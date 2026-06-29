@isTest
public class TrackMeterFieldChangesTest {

//    @isTest
//    static void testTriggerLogicWithAccountAndOpportunity() {
     // Enable test mode for email sending
//       MeterEmailHelper.isTestMode = true;

        // Clear any previously captured emails
//       MockEmailService.clearEmails();

       // Step 1: Set the mock callout
//        Test.setMock(HttpCalloutMock.class, new MockHttpCallout());
        
        // Step 2: Create a test Account
//        Account testAccount = new Account(Name = 'Test Account');
//        insert testAccount;

        // Step 3: Create a test Opportunity linked to the Account
//        Opportunity opp = new Opportunity(
//            Name = 'Test Opportunity',
//            AccountId = testAccount.Id,
//            StageName = 'Initial Assessment',
//            CloseDate = Date.today()
//        );
//        insert opp;

        // Step 4: Create a test Site record
//        Sites__c site = new Sites__c(
//            Opportunity__c = opp.Id,
//            Name = 'Test Site',
//            Street_1__c = '123 Test St',
//            City__c = 'Test City',
//            State_Region__c = 'California',
//            Postal_Code__c = '12345',
//            Active_Sale__c = true
//       );
//       insert site;

        // Step 5: Create a test Meter record linked to the Site and Opportunity
//        Meter__c testMeter = new Meter__c(
//            Name = 'Test Meter',
//            Site__c = site.Id,
//            Opportunity__c = opp.Id,
//            Is_Approved__c = true,  // Mark as approved
//            Meter_Type__c = 'Gas'
//        );
//        insert testMeter;

        // Step 6: Simulate an update to the Meter record
//        Test.startTest();
//        testMeter.ECC_Amount_Year_1__c = 25;  // Simulate a field change
//        update testMeter;
//        Test.stopTest();

        // Step 7: Verify the Approved_Changed_Date__c field
//        Meter__c updatedMeter = [SELECT Initial_Approval_Date__c  FROM Meter__c WHERE Id = :testMeter.Id];
        //System.assertNotEquals(null, updatedMeter.Approved_Changed_Date__c, 'Approved_Changed_Date__c should be updated.');
        //System.assertEquals(System.today(), updatedMeter.Approved_Changed_Date__c, 'Approved_Changed_Date__c should reflect today\'s date.');
    
        // Step 8: Assert Email Sending
        //List<Messaging.SingleEmailMessage> capturedEmails = MockEmailService.getCapturedEmails();
        //System.assertEquals(1, capturedEmails.size(), 'An email should have been sent.');

        //Messaging.SingleEmailMessage sentEmail = capturedEmails[0];
        //System.assert(sentEmail.getPlainTextBody().contains('ECC_Amount_Year_1__c'), 'Email body should mention ECC_Amount_Year_1__c.');
    
//    }
}