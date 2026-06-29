/******************************************************************************
 * Name         : AssetTriggerHandler
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-02-01
 * Description  : Initial handler for AssetTrigger. Qualifies candidates and sends
 * 				  for further processing.
 *
 * Modification History:
 *   Date       | Author           	  | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-02-01 | Nathan Ehrmann      | Initial write for core swaps / subtree builds.
 *
 * Notes:
 * Standard "trigger handler" pattern. All trigger-based initial processing should
 * run from AssetTrigger to this class.
 * 
 * Tests:
 * MS_FSM_AssetSubtreeTests
 ******************************************************************************/

public class AssetTriggerHandler {

    private static Boolean hasRun = false;
    
    public static void skipProcessing() {
        hasRun = true;
    }
    
    @TestVisible
    private static void reset() {
        hasRun = false;
    }
    
    public static void mainEntry(Boolean 		isBefore,
                                 Boolean 		isAfter,
                                 Boolean 		isInsert,
                                 Boolean 		isUpdate,
                                 Boolean 		isDelete,
                                 List<Asset> 	newRecs,
                                 Map<Id, Asset> oldMap) 
    {
        if (hasRun) {
            return;
        }
        
        if (isAfter) {
            hasRun = true;
        }
        
        Map<Id, Asset> parentMap = getParentMap(newRecs);
        
        List<Asset> newInstalled = new List<Asset>();
        
        for (Asset a : newRecs) {
            Asset old = oldMap == null ? null : oldMap.get(a.Id);
            
            if (isBefore) {
                if (isInsert) {
                    Asset p = parentMap.get(a.ParentId);
                    if (p != null && String.isBlank(p.ParentId)) {									// this means we have an incoming L2 Asset
                        a.LocationId = p.LocationId;
                    }
                }
            }
            
            if (isAfter) {
                if (a.Status == 'Installed' && (old == null || old.Status != 'Installed')) {		// is this a fresh install
                    newInstalled.add(a);															// or freshly updated?
                }
            }
        }

        MS_FSM_AssetSubtreeHelper.getSubtreeQualified(newInstalled);  // ! will send scheduled jobs if there are qualifying records
    }
    
    private static Map<Id, Asset> getParentMap(List<Asset> ts) {
        Set<Id> parentIds = new Set<Id>();
        for (Asset a : ts) {
        	parentIds.add(a.ParentId);    
        }
        return new Map<Id, Asset>([SELECT Id, ParentId, LocationId FROM Asset WHERE Id IN :parentIds]);
    }
}