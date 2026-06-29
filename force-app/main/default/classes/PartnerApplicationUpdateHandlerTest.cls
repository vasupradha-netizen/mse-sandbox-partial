@isTest
private class PartnerApplicationUpdateHandlerTest {

    @testSetup
    static void setupTestData() {
        insert new Partner_Application__c(
            Name = 'Test Partner Application',
            Partner_Contact_Email__c = 'test@example.com'
        );
    }

    @isTest
    static void testHandleAfterInsertUpdatesSupportedFields() {
        Partner_Application__c app = [
            SELECT Id, Status__c, Partner_Contact_Email__c, Token__c
            FROM Partner_Application__c
            LIMIT 1
        ];

        Datetime futureDt = System.now().addDays(1);
        String payload = JSON.serialize(new Map<String, Object>{
            'Id' => app.Id,
            'Status__c' => 'Submitted',
            'Partner_Contact_Email__c' => 'updated@example.com',
            'Token__c' => 'new-token',
            'Token_expires_at__c' => futureDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''),
            'Is_Active__c' => 'true'
        });

        Partner_Application_Update_Event__e event = new Partner_Application_Update_Event__e(
            Record_ID__c = app.Id,
            Payload__c = payload
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Platform event should publish successfully.');

        Partner_Application__c updatedApp = [
            SELECT Id, Status__c, Partner_Contact_Email__c, Token__c, Token_expires_at__c, Is_Active__c
            FROM Partner_Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals('Submitted', updatedApp.Status__c, 'Status should be updated.');
        System.assertEquals('updated@example.com', updatedApp.Partner_Contact_Email__c, 'Email should be updated.');
        System.assertEquals('new-token', updatedApp.Token__c, 'Token should be updated.');
        System.assertEquals(true, updatedApp.Is_Active__c, 'Boolean field should be parsed correctly.');
        System.assertEquals(futureDt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), updatedApp.Token_expires_at__c.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\''), 'Datetime should be parsed correctly.');
    }

    @isTest
    static void testHandleAfterInsertSkipsUnsupportedAndNullFields() {
        Partner_Application__c app = [
            SELECT Id, Status__c, Partner_Contact_Email__c
            FROM Partner_Application__c
            LIMIT 1
        ];

        String payload = JSON.serialize(new Map<String, Object>{
            'Id' => app.Id,
            'Status__c' => 'Draft',
            'Partner_Contact_Email__c' => null,
            'Name' => '   ',
            'Some_Unknown_Field__c' => 'value'
        });

        Partner_Application_Update_Event__e event = new Partner_Application_Update_Event__e(
            Record_ID__c = app.Id,
            Payload__c = payload
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Platform event should publish successfully.');

        Partner_Application__c updatedApp = [
            SELECT Id, Status__c, Partner_Contact_Email__c
            FROM Partner_Application__c
            WHERE Id = :app.Id
        ];

        System.assertEquals('Draft', updatedApp.Status__c, 'Supported field should be updated.');
        System.assertEquals(null, updatedApp.Partner_Contact_Email__c, 'Null value should clear field.');
    }

    @isTest
    static void testHandleAfterInsertIgnoresEventWithoutPayloadOrRecordId() {
        Partner_Application_Update_Event__e event = new Partner_Application_Update_Event__e(
            Record_ID__c = null,
            Payload__c = null
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(event);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Platform event should publish successfully.');
    }
}