public class OpportunityScorecardStageGate {

    private List<Opportunity> newOpps = new List<Opportunity>();
    
    public void add(Opportunity o) {
        newOpps.add(o);
    }
    
    public void execute() {
        if (newOpps.isEmpty()) {
            return;
        }
        check(buildRestrictedSet());
    }
    
    private Set<String> buildRestrictedSet() {
        Set<String> r = new Set<String>();
        for (Scorecard_Answer__c a : [SELECT Id,
                                                Opportunity__c,
                                                Account__c,
                                                Answer_PL__c,
                                                Scorecard_Question__c,
                                         		Scorecard_Question__r.Title__c,
                                                Scorecard_Question__r.Restricted_Opportunity_Stages__c
                                         FROM   Scorecard_Answer__c
                                         WHERE  Scorecard_Question__r.Required_for_Stage_Progression__c = true
                                         AND    Opportunity__c IN :newOpps]) 
        {
            if (a.Answer_PL__c != 'True') {
                for (String s : a.Scorecard_Question__r.Restricted_Opportunity_Stages__c.split(';')) {
                    r.add(a.Opportunity__c + ' ' + s.trim());
                }
            }
        }
        return r;
    }
    
    private void check(Set<String> restrictions) {
        for (Opportunity o : newOpps) {
            if (restrictions.contains(String.valueOf(o.Id) + ' ' + o.StageName)) {
                o.addError('One or more Scorecard Answers of False / Unknown / blank is blocking this stage change. Please review and update the Opportunity Scorecard and reattempt.');
            }
        }
    }
    
}