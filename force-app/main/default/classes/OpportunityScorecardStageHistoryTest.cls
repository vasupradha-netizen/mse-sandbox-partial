@isTest
private class OpportunityScorecardStageHistoryTest {

    @isTest
    static void standard() {
        Account a = new Account(
        	Name 				= 'test',
            Scorecard_Type__c 	= 'General-BTM',
            Scorecard_Score__c  = 0
        );
        INSERT a;
        
        Contact c = new Contact(
        	AccountId 	= a.Id,
            LastName 	= 'test'
        );
        INSERT c;
        
        Opportunity o = new Opportunity(
        	CloseDate 			= System.today().addDays(15),
            Name 				= 'test opp',
            AccountId 			= a.Id,
            StageName 			= 'Initial Assessment',
            Scorecard_Score__c 	= 0
        );
        INSERT o;
        
        INSERT new OpportunityContactRole(
        	OpportunityId = o.Id,
            ContactId = c.Id,
            Role = 'Decision Maker'
        );
        
        OpportunityTriggerHandler.reset();
        UPDATE new Opportunity(
        	Id 					= o.Id,
            StageName 			= 'Indicative Proposal',
            Proposal_Type__c 	= 'RFP',
            Purchase_Vehicle__c = 'Lease',
            Description 		= 'description',
            NDA_Date__c 		= System.today(),
            Number_of_Units__c  = 1
        );
        
        List<Scorecard_Stage_History__c> sshs = [SELECT Id FROM Scorecard_Stage_History__c];
        Assert.areEqual(1, sshs.size(), 'OpportunityScorecardStageHistoryTest - standard - history records not generated');
    }
    
}