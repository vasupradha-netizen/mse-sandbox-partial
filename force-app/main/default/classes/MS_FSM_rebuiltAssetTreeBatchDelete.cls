/******************************************************************************
 * Name         : MS_FSM_rebuiltAssetTreeBatchDelete
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-06-04
 * Description  : our "rebuild tree" button was beginning to fail due to large delete
 * 				  operations. this allows us to batch these deletes for safer processing.
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-06-04 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_rebuiltAssetTreeTest
 ******************************************************************************/
public class MS_FSM_rebuiltAssetTreeBatchDelete implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private Asset a;
    private String tableId;
    private String ehId;
        
    public MS_FSM_rebuiltAssetTreeBatchDelete(String aid, String t, String e) {
        getAsset(aid);
        tableId = t;
        ehid	= e;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (a == null || String.isBlank(a.SerialNumber)) {
            return Database.getQueryLocator([SELECT Id FROM Asset WHERE Name = 'EMPTY EMPTY EMPTY']);
        }
        String snSearch = '%' + a.SerialNumber + '%';
        return Database.getQueryLocator([SELECT Id 
                                         FROM   Asset 
                                         WHERE  Id != :a.Id									// obviously do not delete triggering Asset
                                         AND    RootAssetId = :a.RootAssetId				// must reside in same tree
                                         AND    MS_FSM_Serial_Chain__c LIKE :snSearch]);	// must be in subtree
    }
    
    public void execute(Database.BatchableContext bc, List<Asset> scope) {
        DELETE scope;
    }
    
    public void finish(Database.BatchableContext bc) { 
    	fullRebuild();
        partialRebuild();
    }
    
    private void getAsset(String aid) {
        try {
            a = [SELECT Id, AssetLevel, SerialNumber, RootAssetId FROM Asset WHERE Id = :aid];
        } catch (Exception ex) {
         	return;   
        }
    }
    
    private void fullRebuild() {
        if (a.AssetLevel > 1) {
            return;
        }
        MS_FSM_EHINT_GetAssemblyComponents 	j 					= new MS_FSM_EHINT_GetAssemblyComponents();
        									j.newTopAssetIds 	= new List<String>{a.Id};
        									j.index 			= 0;
        if (!Test.isRunningTest()) {
            System.enqueueJob(j);    
        }
    }
    
    private void partialRebuild() {
        if (a.AssetLevel == 1) {
            return;
        }
        Boolean isAssembly = tableId == 'bnnfe2qf9';
        
        String keyField 	= isAssembly ? '3'   : '12';
        String idValue  	= isAssembly ? ehId  : a.SerialNumber;
        String updateField 	= isAssembly ? '594' : '277';
        
        String body  = '{"to" : "' + tableId + '" , "data" : [';
               body += '{ "' + keyField + '" : { "value" : ' + idValue + '}, ';
               body += '"' + updateField + '" : { "value" : true }}';
               body += ']}';
        
        MS_FSM_EHINT_Utils.updateEHData(body);
    }
}