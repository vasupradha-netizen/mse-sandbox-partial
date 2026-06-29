@isTest
public class UpdateCurrentStageDurationBatchTest {

    @testSetup
    static void setup() {
        // Create a test user to use as OwnerId
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser@example.com' + System.currentTimeMillis(),
            ProfileId = p.Id,
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Running as the test user
        System.runAs(testUser) {
            // Create sample Analytics Model records
            List<Analytics_Model__c> models = new List<Analytics_Model__c>();

            // Record in 'To Do' stage
            models.add(new Analytics_Model__c(
                OwnerId = testUser.Id,  // Assigning valid owner
                Stage__c = 'To Do',
                Stage_Start_Time__c = DateTime.now().addHours(-2)  // Two hours ago
            ));

            // Record in 'Info Needed' stage
            models.add(new Analytics_Model__c(
                OwnerId = testUser.Id,  // Assigning valid owner
                Stage__c = 'Info Needed',
                Stage_Start_Time__c = DateTime.now().addMinutes(-90)  // 90 minutes ago
            ));

            // Record in 'Ready for Analysis' stage
            models.add(new Analytics_Model__c(
                OwnerId = testUser.Id,  // Assigning valid owner
                Stage__c = 'Ready for Analysis',
                Stage_Start_Time__c = DateTime.now().addHours(-3)  // Three hours ago
            ));

            // Record in 'Analysis' stage
            models.add(new Analytics_Model__c(
                OwnerId = testUser.Id,  // Assigning valid owner
                Stage__c = 'Analysis',
                Stage_Start_Time__c = DateTime.now().addMinutes(-60)  // One hour ago
            ));

            // Record in 'Validation' stage
            models.add(new Analytics_Model__c(
                OwnerId = testUser.Id,  // Assigning valid owner
                Stage__c = 'Validation',
                Stage_Start_Time__c = DateTime.now().addMinutes(-30)  // 30 minutes ago
            ));

            insert models;
        }
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
// Schedule the job for immediate execution
        String cronExpression = '0 0 0 * * ?'; // Every day at midnight (example)
        UpdateCurrentStageDurationScheduler scheduler = new UpdateCurrentStageDurationScheduler();
        String jobId = System.schedule('TestUpdateCurrentStageDurationScheduler', cronExpression, scheduler);

        // Verify that the scheduled job was enqueued
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, ct.CronExpression, 'Cron expression should match the scheduled expression.');
        System.assert(ct.NextFireTime != null, 'The scheduled job should have a valid next execution time.');

        // Start the batch
        UpdateCurrentStageDurationBatch batch = new UpdateCurrentStageDurationBatch();
        Database.executeBatch(batch);

        Test.stopTest();

        // Query the updated records
        List<Analytics_Model__c> updatedModels = [SELECT Stage__c, Time_Spent_in_To_Do__c, Time_Spent_in_Info_Needed__c, 
                                                    Time_Spent_in_Ready_for_Analysis__c, Time_Spent_in_Analysis__c, 
                                                    Time_Spent_in_Validation__c 
                                                 FROM Analytics_Model__c];

        // Ensure records are present
        System.assert(updatedModels.size() > 0, 'No records found after batch execution.');

        // Assert time spent in stages is calculated correctly
        for (Analytics_Model__c model : updatedModels) {
            if (model.Stage__c == 'To Do') {
                System.assertNotEquals(null, model.Time_Spent_in_To_Do__c, 'Time in "To Do" should be calculated.');
            }
            if (model.Stage__c == 'Info Needed') {
                System.assertNotEquals(null, model.Time_Spent_in_Info_Needed__c, 'Time in "Info Needed" should be calculated.');
            }
            if (model.Stage__c == 'Ready for Analysis') {
                System.assertNotEquals(null, model.Time_Spent_in_Ready_for_Analysis__c, 'Time in "Ready for Analysis" should be calculated.');
            }
            if (model.Stage__c == 'Analysis') {
                System.assertNotEquals(null, model.Time_Spent_in_Analysis__c, 'Time in "Analysis" should be calculated.');
            }
            if (model.Stage__c == 'Validation') {
                System.assertNotEquals(null, model.Time_Spent_in_Validation__c, 'Time in "Validation" should be calculated.');
            }
        }
    }
}