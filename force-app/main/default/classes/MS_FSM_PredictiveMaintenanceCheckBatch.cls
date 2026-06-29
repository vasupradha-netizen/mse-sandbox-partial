public class MS_FSM_PredictiveMaintenanceCheckBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private Map<Id, Set<String>> rootToFamilies = new Map<Id, Set<String>>();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,
                                                RootAssetId,
                                                Product2.Family,
                                                MS_FSM_Predictive_Service_Date__c,
                                                MS_FSM_Predictive_Service_Lead_Time__c
                                         FROM   Asset
                                         WHERE  MS_FSM_Predictive_Service_Date__c != null
                                         AND    MS_FSM_Predictive_Service_Date__c > :System.today()
                                         AND    Status != 'Obsolete'
                                         AND    RootAsset.Status != 'Obsolete']);
    }

    public void execute(Database.BatchableContext bc, List<Asset> scope) {
        for (Asset t : scope) {
            Integer x 	= t.MS_FSM_Predictive_Service_Lead_Time__c == null ? 7 : Integer.valueOf(t.MS_FSM_Predictive_Service_Lead_Time__c);
            Date d 		= t.MS_FSM_Predictive_Service_Date__c.addDays(-x);
            if (d <= System.today() && t.RootAssetId != null && String.isNotBlank(t.Product2.Family)) {
                if (!rootToFamilies.containsKey(t.RootAssetId)) {
                    rootToFamilies.put(t.RootAssetId, new Set<String>());
                }
                rootToFamilies.get(t.RootAssetId).add(t.Product2.Family);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (!rootToFamilies.isEmpty() && !Test.isRunningTest()) {
            List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies> scope = new List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies>();
            for (Id rootId : rootToFamilies.keySet()) {
                scope.add(new MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies(rootId, rootToFamilies.get(rootId)));
            }
            Database.executeBatch(new MS_FSM_PredictiveMaintenanceBatch(scope), 1);
        }
    }
}