/******************************************************************************
 * Name         : MS_FSM_AssetStagingParentingQ
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-06-01
 * Description  : this is scheduled and run after MS_FSM_AssetStagingProcessing in
 * 				  order to parent Assets
 * 				  it is run recursively with exclusions to avoid row locks
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-06-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_AssetStagingTest
 ******************************************************************************/
public class MS_FSM_AssetStagingParentingQ implements Queueable {
    
    private List<Asset> 							assets;
    private List<Asset> 							assetsToUpdate;
    private List<MS_FSM_EtaHub_Asset_Staging__c> 	stagingRecsToUpdate;
    private Set<String>								failedAssetIds;
    private Map<String, Asset> 						parentMap;
    
    public void execute(QueueableContext qc) {
        getAssets();
        if (assets.isEmpty()) {
            return;
        }
        getParentMap();
        applyParents();
        updateFailedStaging();
        finalize();
        nextJob();
    }
    
    private void getAssets() {
        assets = [SELECT Id, MS_FSM_Parent_Serial_Number__c, SerialNumber FROM Asset WHERE MS_FSM_Parent_Serial_Number__c != '' LIMIT 2000];
    }
    
    private void getParentMap() {
        parentMap = new Map<String, Asset>();
        for (Asset t : assets) {
            parentMap.put(t.MS_FSM_Parent_Serial_Number__c, null);
        }
        for (Asset t : [SELECT Id, SerialNumber, ParentId, MS_FSM_Parent_Serial_Number__c, LocationId FROM Asset WHERE SerialNumber IN :parentMap.keySet()]) {
            parentMap.put(t.SerialNumber, t);
        }
    }
    
    private void applyParents() {
        		    failedAssetIds  = new Set<String>();
        			assetsToUpdate 	= new List<Asset>();
        Set<String> parentedSerials = new Set<String>();
        for (Asset t : assets) {
            if (parentedSerials.contains(t.SerialNumber)) {
                continue;
            }
            
            Asset p = parentMap.get(t.MS_FSM_Parent_Serial_Number__c);
            String pid = parentMap.get(t.MS_FSM_Parent_Serial_Number__c).Id;
            if (p == null) {
				failedAssetIds.add(t.Id);
            }
            
            assetsToUpdate.add(new Asset(
            	Id 								= t.Id,
                ParentId 						= p == null ? null : p.Id,
                MS_FSM_Parent_Serial_Number__c 	= '',
                LocationId						= p != null && String.isBlank(p.ParentId) && String.isBlank(p.MS_FSM_Parent_Serial_Number__c) ? p.LocationId : null
            ));
            
            parentedSerials.add(t.MS_FSM_Parent_Serial_Number__c);
        }
    }
    
    private void updateFailedStaging() {
        stagingRecsToUpdate = new List<MS_FSM_EtaHub_Asset_Staging__c>();
        for (MS_FSM_EtaHub_Asset_Staging__c s : [SELECT Id,
                                                        MS_FSM_Stage__c
                                                 FROM   MS_FSM_EtaHub_Asset_Staging__c
                                                 WHERE  MS_FSM_Asset_Id__c IN :failedAssetIds]) 
        {
            s.MS_FSM_Stage__c += ' - Unable to Locate Parent via Serial';
            stagingRecsToUpdate.add(s);
        }
    }
    
    private void finalize() {
        AssetTriggerHandler.skipProcessing();
        UPDATE assetsToUpdate;
        UPDATE stagingRecsToUpdate;
    }
    
    private void nextJob() {
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_AssetStagingParentingQ());
        }
    }
}