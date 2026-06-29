// STEP 1 of 2 -- see MS_FSM_SnChainRebuildSched for full description
public class MS_FSM_SnChainRebuildRootBatch implements Database.Batchable<sObject>, Database.Stateful {

    private List<String> 	topAssets;
    private List<Asset> 	recs;
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        topAssets = new List<String>();
        return Database.getQueryLocator([SELECT Id, Status, MS_FSM_Serial_Chain__c FROM Asset WHERE ParentId = '']);
    }
    
    public void execute(Database.BatchableContext bc, List<Asset> scope) {
        List<Asset> recsToUpdate = new List<Asset>();
        
        Map<Id, Asset> 		assetMap 			= new Map<Id, Asset>(scope);
        Map<Id, Integer> 	assetIdToChildCt 	= new Map<Id, Integer>();
        
        List<Asset> children = [SELECT 	Id, RootAssetId, MS_FSM_Serial_Chain__c 
                                FROM 	Asset 
                                WHERE 	RootAssetId IN :assetMap.keySet() 
                                AND 	Id NOT IN :assetMap.keySet()];
        
        for (Asset t : children) {
            String rootId = t.RootAssetId;
            Asset r = assetMap.get(rootId);
            
            if (r.Status == 'Obsolete' && !String.isBlank(t.MS_FSM_Serial_Chain__c)) {
                t.MS_FSM_Serial_Chain__c = '';
                recsToUpdate.add(t);
            }
            
            Integer n = assetIdToChildCt.get(rootId);
            assetIdToChildCt.put(rootId, n == null ? 1 : n + 1);
        }
        
        for (Asset t : assetMap.values()) {
            if (t.Status == 'Obsolete' && !String.isBlank(t.MS_FSM_Serial_Chain__c)) {
                t.MS_FSM_Serial_Chain__c = '';
                recsToUpdate.add(t);
                continue;
            }
            if (t.Status == 'Installed' && assetIdToChildCt.get(t.Id) > 0) {
                topAssets.add(t.Id);
            }
        }
        
        AssetTriggerHandler.skipProcessing();
        UPDATE recsToUpdate;
    }
    
    public void finish(Database.BatchableContext bc) {
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_SnChainRebuildQueue(0, topAssets, null));
        }
    }
    
}