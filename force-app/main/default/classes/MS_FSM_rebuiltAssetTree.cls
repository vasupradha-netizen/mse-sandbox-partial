/******************************************************************************
 * Name         : MS_FSM_rebuiltAssetTree
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : with the click of a few buttons and some system confirmations,
 * 				  a user can rebuild a subtree for the LGen that they are
 * 				  currently viewing. this may be required as builds are sometimes
 * 				  corrected in EH after syncing to FSM.
 * 				  this powers the LWC "rebuiltAssetTreet" (yes, tree is misspelled at the end)
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *   2025-06-01 | Nathan Ehrmann      | Enabled "targeted rebuild" for *subtrees*.
 * 										A user can now use this component anywhere in the tree.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_rebuiltAssetTreeTest
 ******************************************************************************/

public without sharing class MS_FSM_rebuiltAssetTree {
    
    private static String tableId;
    private static String ehId;
    
    /********************************************************
	 * Purpose: an Asset will fail initial checks if
	 * 			1. no record Id is specified (rare)
	 * 			2. we cannot find the record given an Id (rare)
	 * 			3. the current page is not a LGen / root asset (possible)
	 * 			4. there is a Work Order for this asset somewhere (possible; our biggest risk)
	 * Input:	assetId - the record Id passed from the LWC
	 * Output:	String message:
	 * 				"SUCCESS" 	- checks passed and user can proceed
	 * 				else 		- checks failed and user is blocked
	 ********************************************************/
    @AuraEnabled
    public static String initialChecks(String assetId) {
        if (String.isBlank(assetId)) {
            return 'No record Id specified.';
        }

        Asset a = getAsset(assetId);
        if (a == null) {
            return 'Asset not found.';
        }

        String snSearch = '%' + a.SerialNumber + '%';
        List<WorkOrderLineItem> woliList = [SELECT Id 
                                  			FROM   WorkOrderLineItem 
                                  			WHERE  MS_FSM_Installed_Asset__r.MS_FSM_Serial_Chain__c LIKE :snSearch 
                                  			OR     MS_FSM_Removed_Asset__r.MS_FSM_Serial_Chain__c LIKE :snSearch];
        
        if (!woliList.isEmpty()) {
            return 'There are already Work Order Line Items on Assets in this tree.';
        }
        
        return checkEtaHub(a.SerialNumber);
    }

    /********************************************************
	 * Purpose: button click from user kicks off the rebuild process
	 * 			the DELETE will be large and somewhat time-consuming
	 * Input:	assetId - the record Id passed from the LWC
	 * Output:	String message:
	 * 				"SUCCESS" 	- DELETE DML and system enqueue have succeeded
	 * 				else 		- no error handling; these operations should proceed fine
	 ********************************************************/
    @AuraEnabled
    public static String rebuildTree(String assetId) {
        Asset a = getAsset(assetId);
        checkEtaHub(a.SerialNumber);
        Database.executeBatch(new MS_FSM_rebuiltAssetTreeBatchDelete(a.Id, tableId, ehId));
        return 'SUCCESS';
    }

    /********************************************************
	 * Purpose: get the Asset the user is currently viewing
	 * Input:	assetId - the record Id passed from the LWC
	 * Output:	the Asset that the user is currently viewing
	 ********************************************************/
    private static Asset getAsset(String assetId) {
        try {
            return [SELECT Id, 
                           AssetLevel, 
                           SerialNumber, 
                           MS_FSM_Serial_Chain__c
                    FROM   Asset 
                    WHERE  Id = :assetId];
        } catch (Exception ex) {
            return null;
        }
    }
    
    private static String checkEtaHub(String serial) {
        String a = getEhData(serial, 'bnnfe2qf9');
        String b = !String.isBlank(a) ? '' : getEhData(serial, 'brv5unzwf');
        String c = String.isBlank(a) && String.isBlank(b) ? 'No Assembly or CM Assembly found for this Serial Number' : '';
        
        return String.isBlank(a + b) ? 'No Assembly or CM Assembly found for this Serial Number' : (a + b);
    }
    
    private static String getEhData(String sn, String tid) {
        String filter = '{12.EX.' + sn + '}';
        List<Map<Integer, Map<String, String>>> data = MS_FSM_EHINT_Utils.getEHData(MS_FSM_EHINT_Utils.getIntDefs(tid).values(), filter, 0, 0);
        if (data.size() > 1) {
            return 'Multiple records (table = ' + tid + ') found for this Serial Number.';
        }
        if (data.size() == 1) {
            tableId = tid;
            ehId 	= data[0].get(3).get('value');
            return 'SUCCESS';
        }
        
        return '';
    }
}