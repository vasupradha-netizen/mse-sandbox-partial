@isTest
private class OpportunityScorecardStageGateTest {

    @isTest
    static void standard() {
        Scorecard__c sc = new Scorecard__c(
        	Name   		 		= 'test',
            Scorecard_Type__c  	= 'General-BTM'
        );
        INSERT sc;
        
        List<Scorecard_Questions__c> qs = new List<Scorecard_Questions__c>();
        Scorecard_Questions__c scqa = new Scorecard_Questions__c(
        	Title__c 			= 'test account question',
            Active__c 			= true,
            Scorecard__c 		= sc.Id,
         	Question_Type__c 	= 'Account'   
        );
        qs.add(scqa);
        Scorecard_Questions__c scqb = new Scorecard_Questions__c(
            Title__c 							= 'test opportunity question',
            Active__c 							= true,
            Scorecard__c 						= sc.Id,
            Question_Type__c 					= 'Opportunity',
            Required_For_Stage_Progression__c	= true,
            Restricted_Opportunity_Stages__c    = 'Firm Proposal'
        );
        qs.add(scqb);
        INSERT qs;
        
        Account a = new Account(
        	Name 				= 'test account',
            Scorecard_Type__c 	= 'General-BTM'
        );
        INSERT a;
        
        Opportunity o = new Opportunity(
        	AccountId	= a.Id,
            Name		= 'test opportunity',
            StageName 	= 'Prospecting',
            CloseDate 	= Date.today().addDays(30) 
        );
        INSERT o;
        OpportunityTriggerHandler.reset();
        
        List<Scorecard_Answer__c> scas = [SELECT Id, Account__c, Opportunity__c FROM Scorecard_Answer__c];
        Assert.areEqual(2, scas.size());		// this is actually testing a Flow at this time
        
        Boolean f = false;
        try {
            UPDATE new Opportunity(
            	Id = o.Id,
                StageName = 'Firm Proposal'
            );
        } catch (Exception ex) {
            f = true;
            System.debug('OpportunityScorecardStageGateTest - error updating Opportunity');
            System.debug(ex.getMessage());
        }
        Assert.areEqual(true, f);
    }
    
}