@isTest
private class ScorecardSnapshotTest {

    @TestSetup
    static void setup() {
        Account a = new Account(
        	Name 				= 'test',
            Scorecard_Type__c 	= 'General-BTM'
        );
        INSERT a;
        
        Contact c = new Contact(
        	AccountId 	= a.Id,
            LastName 	= 'test'
        );
        INSERT c;
        
        Opportunity o = new Opportunity(
        	CloseDate 	= System.today().addDays(15),
            Name 		= 'test opp',
            AccountId 	= a.Id,
            StageName 	= 'Initial Assessment'
        );
        INSERT o;
    }
    
    @isTest
    static void acc() {
        Account a = [SELECT Id, Name FROM Account LIMIT 1];
        INSERT new Scorecard_Snapshot__c(
        	Record_Id__c = a.Id,
            Record_Name__c = a.Name,
            Record_Type__c = 'Account',
            Date__c = System.today().addDays(-30),
            Score__c = 20,
            Delta__c = null
        );
        UPDATE new Account(Id = a.Id, Scorecard_Score__c = 40);
        ScorecardSnapshotSched j = new ScorecardSnapshotSched();
        Test.startTest();
        j.execute(null);
        Test.stopTest();
        
        List<Scorecard_Snapshot__c> entries = [SELECT Id FROM Scorecard_Snapshot__c];
        Assert.areEqual(2, entries.size());
    }
    
    @isTest
    static void opp() {
        Opportunity o = [SELECT Id, Name FROM Opportunity LIMIT 1];
        INSERT new Scorecard_Snapshot__c(
        	Record_Id__c = o.Id,
            Record_Name__c = o.Name,
            Record_Type__c = 'Opportunity',
            Date__c = System.today().addDays(-30),
            Score__c = 20,
            Delta__c = null
        );
        UPDATE new Opportunity(Id = o.Id, Scorecard_Score__c = 40);
        Test.startTest();
        Database.executeBatch(new ScorecardSnapshotBatch('Opportunity'));
        Test.stopTest();
        
        List<Scorecard_Snapshot__c> entries = [SELECT Id FROM Scorecard_Snapshot__c];
        Assert.areEqual(2, entries.size());
    }
}