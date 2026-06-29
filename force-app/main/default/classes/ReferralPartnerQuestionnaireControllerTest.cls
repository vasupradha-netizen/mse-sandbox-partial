@isTest
private class ReferralPartnerQuestionnaireControllerTest {

    @testSetup
    static void setupTestData() {
        insert new Partner_Application__c(
            Token__c = 'valid-token-123',
            Token_expires_at__c = System.now().addHours(1),
            Partner_Contact_Email__c = 'test@example.com'
        );
    }

    @isTest
    static void testValidateTokenAndGetRecordReturnsValidForMatchingToken() {
        Partner_Application__c app = [
            SELECT Id, Token__c, Token_expires_at__c
            FROM Partner_Application__c
            LIMIT 1
        ];

        Test.startTest();
        ReferralPartnerQuestionnaireController.TokenValidationWrapper result =
            ReferralPartnerQuestionnaireController.validateTokenAndGetRecord(app.Token__c);
        Test.stopTest();

        System.assertEquals(true, result.isValid, 'Token should validate successfully.');
        System.assertNotEquals(null, result.record, 'Record should be returned.');
        System.assertEquals(app.Id, result.record.Id, 'Returned record should match the token owner.');
    }

    @isTest
    static void testValidateTokenAndGetRecordReturnsInvalidForBlankAndExpiredTokens() {
        Partner_Application__c app = [
            SELECT Id, Token__c, Token_expires_at__c
            FROM Partner_Application__c
            LIMIT 1
        ];
        app.Token_expires_at__c = System.now().addMinutes(-1);
        update app;

        Test.startTest();
        ReferralPartnerQuestionnaireController.TokenValidationWrapper blankResult =
            ReferralPartnerQuestionnaireController.validateTokenAndGetRecord(null);
        ReferralPartnerQuestionnaireController.TokenValidationWrapper expiredResult =
            ReferralPartnerQuestionnaireController.validateTokenAndGetRecord(app.Token__c);
        Test.stopTest();

        System.assertEquals(false, blankResult.isValid, 'Blank token should be rejected.');
        System.assertEquals(null, blankResult.record, 'Blank token should not return a record.');
        System.assertEquals(false, expiredResult.isValid, 'Expired token should be rejected.');
        System.assertEquals(null, expiredResult.record, 'Expired token should not return a record.');
    }

    @isTest
    static void testSaveRecordReturnsFailureWhenRecordIdMissing() {
        Test.startTest();
        ReferralPartnerQuestionnaireController.SaveResultWrapper result =
            ReferralPartnerQuestionnaireController.saveRecord('{"Name":"Test"}', false, null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Save should fail without a record id.');
        System.assertEquals('Error: Missing context record ID.', result.message, 'Expected missing id error message.');
    }

    @isTest
    static void testSaveRecordPublishesDraftAndSubmitPayloads() {
        Partner_Application__c app = [
            SELECT Id
            FROM Partner_Application__c
            LIMIT 1
        ];

        Test.startTest();
        ReferralPartnerQuestionnaireController.SaveResultWrapper draftResult =
            ReferralPartnerQuestionnaireController.saveRecord('{"Name":"Draft Value"}', false, app.Id);
        ReferralPartnerQuestionnaireController.SaveResultWrapper submitResult =
            ReferralPartnerQuestionnaireController.saveRecord('{"Name":"Submitted Value"}', true, app.Id);
        Test.stopTest();

        System.assertEquals(true, draftResult.success, 'Draft save should succeed.');
        System.assertEquals(app.Id, draftResult.recordId, 'Draft result should echo the record id.');
        System.assertEquals('Draft saved successfully.', draftResult.message, 'Expected draft success message.');

        System.assertEquals(true, submitResult.success, 'Final submit should succeed.');
        System.assertEquals(app.Id, submitResult.recordId, 'Submit result should echo the record id.');
        System.assertEquals('Questionnaire submitted successfully!', submitResult.message, 'Expected submit success message.');
    }

    @isTest
    static void testGetOrgStateCountryMappingReturnsExpectedKeys() {
        Test.startTest();
        Map<String, Map<String, String>> mapping =
            ReferralPartnerQuestionnaireController.getOrgStateCountryMapping();
        Test.stopTest();

        System.assert(mapping.containsKey('countries'), 'Countries mapping should be returned.');
        System.assert(mapping.containsKey('states'), 'States mapping should be returned.');
        System.assertNotEquals(null, mapping.get('countries'), 'Countries mapping should not be null.');
        System.assertNotEquals(null, mapping.get('states'), 'States mapping should not be null.');
    }

    @isTest
    static void testGenerateTokenReturnsValidOutput() {
        Test.startTest();
        List<ReferralPartnerQuestionnaireController.Output> results =
            ReferralPartnerQuestionnaireController.generateToken(new List<String>{ 'request' });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Exactly one output should be returned.');
        System.assertNotEquals(null, results[0].token, 'Token should be generated.');
        System.assertEquals(false, String.isBlank(results[0].token), 'Token should not be blank.');
    }

    @isTest
    static void testRequestNewAccessLinkReturnsGenericSuccessWhenNoMatchFound() {
        Test.startTest();
        Map<String, Object> result =
            ReferralPartnerQuestionnaireController.requestNewAccessLink('unknown-token', 'missing@example.com');
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Method should return success for generic response.');
        System.assertEquals('No matching records found', result.get('message'), 'Expected generic no-match message.');
    }

    @isTest
    static void testRequestNewAccessLinkReturnsSuccessForMatchingRecord() {
        Partner_Application__c app = [
            SELECT Id, Token__c, Partner_Contact_Email__c
            FROM Partner_Application__c
            LIMIT 1
        ];

        Test.startTest();
        Map<String, Object> result =
            ReferralPartnerQuestionnaireController.requestNewAccessLink(app.Token__c, app.Partner_Contact_Email__c);
        Test.stopTest();

        System.assertEquals(true, result.get('success'), 'Matching record should succeed.');
        System.assertEquals(
            'A new secure link has been generated and sent to your email.',
            result.get('message'),
            'Expected success message for secure token reset.'
        );
    }

    @isTest
    static void testRequestNewAccessLinkReturnsErrorWhenInputsMissing() {
        Test.startTest();
        Map<String, Object> result =
            ReferralPartnerQuestionnaireController.requestNewAccessLink('', '   ');
        Test.stopTest();

        System.assertEquals(false, result.get('success'), 'Missing inputs should fail.');
        System.assertEquals('Required inputs are missing.', result.get('message'), 'Expected missing input message.');
    }
}