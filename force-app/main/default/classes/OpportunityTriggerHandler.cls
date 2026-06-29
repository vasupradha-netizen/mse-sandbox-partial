public class OpportunityTriggerHandler {
    
    private static Boolean hasRun = false;
    
    public static void skipProcessing() {
        hasRun = true;
    }
    
    @TestVisible
    private static void reset() {
        hasRun = false;
    }
    
    public static void mainEntry(Boolean         isBefore,
                                 Boolean         isAfter,
                                 Boolean         isInsert,
                                 Boolean         isUpdate,
                                 Boolean         isDelete,
                                 List<Opportunity>     newRecs,
                                 Map<Id, Opportunity>  oldMap) 
    {
        if (hasRun || isDelete) { 
            return;
        }
        
        if (isAfter) {
            hasRun = true;
        }
        
        OpportunityScorecardStageHistory ossh = new OpportunityScorecardStageHistory();
        OpportunityScorecardStageGate    ossg = new OpportunityScorecardStageGate();
        OpportunityScorecardStageGateAnswered ossga = new OpportunityScorecardStageGateAnswered();
        
        for (Opportunity o : newRecs) {
            Opportunity old = oldMap == null ? null : oldMap.get(o.Id);
            
            Boolean stageChange = old != null && o.StageName != old.StageName;
            
            if (isBefore) {
                if (stageChange || isInsert) {
               
                    ossga.add(o); 
                }
                if (stageChange) {
                    ossg.add(o);
                }
            }
            
            if (isAfter) {
                if (stageChange) {
                    ossh.add(o.Id, o.AccountId, o.StageName, old.StageName, o.Scorecard_Score__c);
                }
            }
        }
        
        ossh.execute();
        ossg.execute();
        ossga.execute(); 
    }
}