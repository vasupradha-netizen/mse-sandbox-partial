public class OpportunityScorecardStageHistory {
    
    private List<ProtoSSH>   newRecs;
    private Map<Id, Account> accMap;
    
    public OpportunityScoreCardStageHistory() {
        newRecs = new List<ProtoSSH>();
    }
    
    public void add(String o, String a, String n, String v, Decimal s) {
        newRecs.add(new ProtoSSH(o, a, n, v, s));
    }
    
    public void execute() {        
        if (newRecs.isEmpty()) {
            return;
        }
        getAccMap();
        makeRecs();
    }
    
    private void getAccMap() {
        Set<String> aids = new Set<String>();
        for (ProtoSSH p : newRecs) {
            aids.add(p.aid);
        }
        accMap = new Map<Id, Account>(
        	[SELECT Id,
                    Scorecard_Score__c,
                    Scorecard_Type__c
             FROM   Account
             WHERE  Id IN :aids]
        );
    }
    
    private void makeRecs() {
        List<Scorecard_Stage_History__c> newEntries = new List<Scorecard_Stage_History__c>();
        for (ProtoSSH p : newRecs) {
            Account a = accMap.get(p.aid);
            if (p.score == null && a.Scorecard_Score__c == null) {
                continue;
            }
            newEntries.add(new Scorecard_Stage_History__c(
            	Opportunity__c 			= p.oid,
                New_Stage__c   			= p.newStage,
                Old_Stage__c   			= p.oldStage,
                Date__c		   			= System.today(),
                Account_Score__c 		= a.Scorecard_Score__c,
                Scorecard_Type__c 		= a.Scorecard_Type__c,
                Opportunity_Score__c 	= p.score
            ));
        }
        INSERT newEntries;
    }
    
    private class ProtoSSH {
        private String  oid;
        private String  aid;
        private String  newStage;
        private String  oldStage;
        private Decimal score;
        
        public ProtoSSH(String o, String a, String n, String v, Decimal s) {
            oid 		= o;
            aid			= a;
            newStage 	= n;
            oldStage	= v;
            score		= s;
        }
    }
}