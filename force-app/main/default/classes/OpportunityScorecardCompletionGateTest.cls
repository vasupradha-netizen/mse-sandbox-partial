@isTest
private class OpportunityScorecardCompletionGateTest {

    @testSetup
    static void setup() {
        // 1. Create the Master Scorecard
        Scorecard__c sc = new Scorecard__c(Name = 'Standard Scorecard');
        insert sc;

        // 2. Create the Account and Opportunity
        Account acc = new Account(Name = 'Test Completion Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Completion Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = acc.Id
        );
        insert opp;

        // 3. Create the Parent Questions using the correct API Name: Scorecard_Questions__c
        Scorecard_Questions__c oppQ = new Scorecard_Questions__c(
            Title__c = 'Opp Question',
            Question_Type__c = 'Opportunity',
            Scorecard__c = sc.Id 
        );
        Scorecard_Questions__c accQ = new Scorecard_Questions__c(
            Title__c = 'Acc Question',
            Question_Type__c = 'Account',
            Scorecard__c = sc.Id
        );
        insert new List<Scorecard_Questions__c>{oppQ, accQ};

        // 4. Create the Scorecard Answers
        Scorecard_Answer__c ans1 = new Scorecard_Answer__c(
            Opportunity__c = opp.Id,
            Scorecard_Question__c = oppQ.Id,
            Answer_PL__c = null // The blank value that triggers the gate
        );
        
        Scorecard_Answer__c ans2 = new Scorecard_Answer__c(
            Account__c = acc.Id,
            Scorecard_Question__c = accQ.Id,
            Answer_PL__c = null
        );
        insert new List<Scorecard_Answer__c>{ans1, ans2};
    }

    @isTest
    static void testGateBlocksIncomplete() {
        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.StageName = 'Negotiation/Review';
        Database.SaveResult result = Database.update(opp, false);
        Test.stopTest();

        // Check if metadata is active before asserting
        Apex_Classes_Enable_Disable__mdt sw = Apex_Classes_Enable_Disable__mdt.getInstance('Opportunity_Scorecard_Gate');
        if (sw != null && sw.Active__c) {
            System.assert(!result.isSuccess(), 'The save should have been blocked.');
        }
    }

    @isTest
    static void testGateAllowsComplete() {
        List<Scorecard_Answer__c> answers = [SELECT Id FROM Scorecard_Answer__c];
        for(Scorecard_Answer__c a : answers) {
            a.Answer_PL__c = 'True';
        }
        update answers;

        Opportunity opp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        
        Test.startTest();
        opp.StageName = 'Negotiation/Review';
        Database.SaveResult result = Database.update(opp, true);
        Test.stopTest();

        System.assert(result.isSuccess(), 'The save should succeed with complete answers.');
    }
}