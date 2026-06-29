public class OpportunityScorecardStageGateAnswered {

    private List<Opportunity> monitoredOpps = new List<Opportunity>();
    private Set<Id> accountIds = new Set<Id>();
    
    public void add(Opportunity o) {
        if (o.StageName == 'Indicative Proposal' || 
            o.StageName == 'Firm Proposal' || 
            o.StageName == 'Negotiation/Review' || 
            o.StageName == 'Closed Won') {
            
            monitoredOpps.add(o);
            if (o.AccountId != null) accountIds.add(o.AccountId);
        }
    }
    
    public void execute() {
        Apex_Classes_Enable_Disable__mdt gateSwitch = Apex_Classes_Enable_Disable__mdt.getInstance('Opportunity_Scorecard_Gate');
        
        if (gateSwitch == null || !gateSwitch.Active__c || monitoredOpps.isEmpty()) {
            return;
        }

        Set<Id> incompleteOppIds = new Set<Id>();
        Set<Id> incompleteAccountIds = new Set<Id>();

        // Optimized Query: Only fetch records relevant to their specific level
        for (Scorecard_Answer__c a : [SELECT Opportunity__c, Account__c, Question_Type__c 
                                      FROM Scorecard_Answer__c 
                                      WHERE Answer_PL__c = null 
                                      AND (
                                          (Opportunity__c IN :monitoredOpps AND Question_Type__c = 'Opportunity') 
                                          OR 
                                          (Account__c IN :accountIds AND Question_Type__c = 'Account')
                                      )]) {
            
            if (a.Question_Type__c == 'Opportunity') {
                incompleteOppIds.add(a.Opportunity__c);
            } else if (a.Question_Type__c == 'Account') {
                incompleteAccountIds.add(a.Account__c);
            }
        }

        for (Opportunity o : monitoredOpps) {
            if (incompleteOppIds.contains(o.Id) || incompleteAccountIds.contains(o.AccountId)) {
                o.addError('Incomplete Scorecard: Please ensure all related Opportunity and Account-level questions are answered before proceeding.');
            }
        }
    }
}