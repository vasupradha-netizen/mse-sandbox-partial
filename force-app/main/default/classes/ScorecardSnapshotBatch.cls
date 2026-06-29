public class ScorecardSnapshotBatch implements Database.Batchable<sObject> {

    private String 					table;
    private List<sObject> 			recs;
    private Map<String, Decimal> 	oldScores;
    private Map<String, String>     ownerIdtoName;
    
    public ScorecardSnapshotBatch(String t) {
        table = t;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String q  = 'SELECT Id, Name, Scorecard_Score__c, OwnerId';
               q += table == 'Opportunity' ? ', StageName, CloseDate, Probability' : '';
               q += (' FROM ' + table + ' WHERE Scorecard_Score__c != null');
        return Database.getQueryLocator(q);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
    	recs = scope;
        getOldScores();
        getOwnerMap();
        List<Scorecard_Snapshot__c> newEntries = new List<Scorecard_Snapshot__c>();
        for (sObject o : recs) {
            newEntries.add(getNewRecord(o));
        }
        INSERT newEntries;
    }
    
    public void finish(Database.BatchableContext bc) {
        if (table == 'Account' && !Test.isRunningTest()) {
            Database.executeBatch(new ScorecardSnapshotBatch('Opportunity'));
        }
    }
    
    private void getOldScores() {
        oldScores = new Map<String, Decimal>();
        for (sObject o : recs) {
            oldScores.put(o.Id, null);
        }
        for (Scorecard_Snapshot__c s : [SELECT Record_Id__c, 
                                               Score__c 
                                        FROM   Scorecard_Snapshot__c 
                                        WHERE  CreatedDate >= :System.now().addDays(-34)
                                        AND    Record_Id__c IN :oldScores.keySet()]) {
            oldScores.put(s.Record_Id__c, s.Score__c);
        }
    }
    
    private void getOwnerMap() {
        ownerIdtoName = new Map<String, String>();
        for (sObject o : recs) {
            ownerIdToName.put((String)o.get('OwnerId'), null);
        }
        for (User u : [SELECT Id, Name FROM User WHERE Id IN :ownerIdToName.keySet()]) {
            ownerIdToName.put(u.Id, u.Name);
        }
    }
    
    private Scorecard_Snapshot__c getNewRecord(sObject o) {
        String k  = (String)o.get('Id');
        Decimal v = (Decimal)o.get('Scorecard_Score__c');
        
        Scorecard_Snapshot__c r = new Scorecard_Snapshot__c(
            Record_Id__c   = k,
            Record_Name__c = (String)o.get('Name'),
            Record_Type__c = table,
            Date__c		   = System.today(),
            Score__c	   = v,
            Delta__c       = oldScores.get(k) == null ? null : v - oldScores.get(k),
            Owner_Name__c  = ownerIdToName.get((String)o.get('OwnerId'))
        );
        
        if (table == 'Opportunity') {
            r.Stage_Name__c  = (String)o.get('StageName');
            r.Close_Date__c  = (Date)o.get('CloseDate');
            r.Probability__c = (Decimal)o.get('Probability');
        }
        
        return r;
    }
}