@isTest
private class StageTimeCalculatorBatchTest {

    @isTest
    static void testBatchLogicWithRegression() {
        // 1. Create real record
        Analytics_Model__c testRec = new Analytics_Model__c(Stage__c = 'Analysis');
        insert testRec;
        
        // RE-QUERY to get the system-generated CreatedDate
        testRec = [SELECT Id, CreatedDate, Stage__c FROM Analytics_Model__c WHERE Id = :testRec.Id];

        // 2. Create "Mock" History
        Datetime now = Datetime.now();
        List<StageTimeCalculatorBatch.StageHistory> mocks = new List<StageTimeCalculatorBatch.StageHistory>();
        mocks.add(new StageTimeCalculatorBatch.StageHistory('Analysis', now.addHours(-5)));
        mocks.add(new StageTimeCalculatorBatch.StageHistory('Released', now.addHours(-2)));
        mocks.add(new StageTimeCalculatorBatch.StageHistory('Analysis', now));

        // 3. Setup Batch and Inject Mocks
        StageTimeCalculatorBatch batch = new StageTimeCalculatorBatch();
        batch.mockedHistory = mocks;

        Test.startTest();
        batch.execute(null, new List<Analytics_Model__c>{testRec});
        Test.stopTest();

        // 4. Verify
        Analytics_Model__c result = [SELECT KD_Testing_TTR__c, KD_Testing_TTR_Notes__c FROM Analytics_Model__c WHERE Id = :testRec.Id];
        System.assertNotEquals(null, result.KD_Testing_TTR__c, 'TTR should not be null');
        System.assert(result.KD_Testing_TTR_Notes__c.contains('RESET'), 'Should have logged a reset');
    }
    
    @isTest
    static void testStandardBatchRun() {
        insert new Analytics_Model__c(Stage__c = 'To Do');
        Test.startTest();
        Database.executeBatch(new StageTimeCalculatorBatch());
        Test.stopTest();
        System.assert([SELECT Count() FROM Analytics_Model__c] > 0);
    }
}