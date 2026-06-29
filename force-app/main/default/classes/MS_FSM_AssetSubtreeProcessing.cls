/******************************************************************************
 * Name         : MS_FSM_AssetSubtreeProcessing
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-02-01
 * Description  : main processing / integration for subtree builds
 * 				  this prepares the main record (usually a core) by getting some
 * 				  initial info from EtaHub, after which we send its Serial Number
 * 				  to our EHINT code for getting the subtree
 *
 * Modification History:
 *   Date       | Author           	  | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-02-01 | Nathan Ehrmann      | Initial write for core swaps / subtree builds.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_AssetSubtreeTests
 ******************************************************************************/
public class MS_FSM_AssetSubtreeProcessing implements Queueable, Database.allowsCallouts {
    
    private List<String> 								assetIds;
    private Integer 									index;
    private Asset										a;
    private List<Map<Integer, Map<String, String>>> 	data;
    private String 										tableId = 'bnnfe2qf9';
    private String										mfBy	= 'MSE';
    private Boolean										error   = false;
    
    public MS_FSM_AssetSubtreeProcessing(List<String> aids, Integer i) {
        assetIds 	= aids;
        index 		= i;
    }
    
    public void execute(QueueableContext qc) {
        getAsset();
        getData();
        applyUpdates();
        nextJob();
    }
    
    /********************************************************
	 * Purpose: retrieve and set our context Asset ()
	 * Input:	none (we use our initial list of ids and index to filter)
	 * Output:	! none ! - we assign a context variable for the remainder
	 * 			of processing
	 ********************************************************/
    private void getAsset() {
        a = [SELECT Id, SerialNumber FROM Asset WHERE Id = :assetIds[index]];
    }
    
    /********************************************************
	 * Purpose: INTEGRATION - get data from EH
	 * 			we want to know
	 * 			1. which table the Core resides in (Assembly or CM Assembly)
	 * 			2. the EH Id in that table
	 * 			3. we use (1) to assign a Manufactured By value
	 * Input:	none - we use context variables
	 * Output:	! none ! - we assign more context variables
	 ********************************************************/
    private void getData() {
        String filter = '{12.EX.' + a.SerialNumber + '}';
        data =  MS_FSM_EHINT_Utils.getEHData(MS_FSM_EHINT_Utils.getIntDefs(tableId).values(), filter, 0, 0);
        if (data.isEmpty() && tableId == 'bnnfe2qf9') {		// first	 		attempt Assembly
            tableId = 'brv5unzwf';							// nothing found? 	attempt CM Assembly
            mfBy 	= 'CM';
            getData();
        }
    }
    
    /********************************************************
	 * Purpose: apply updates to the current context Asset
	 * 			based on return from EH
	 * Input:	none - we use context variables
	 * Output:	! none ! - one DML operation
	 ********************************************************/
    private void applyUpdates() {
        if (data.isEmpty()) {
            currentRecordError();
            return;
        }
        a.MS_FSM_EtaHub_Table_Id__c  = tableId;
        a.MS_FSM_EtaHub_Record_Id__c = data[0].get(3).get('value');
        a.MS_FSM_Manufactured_By__c  = mfBy;
        AssetTriggerHandler.skipProcessing();
        UPDATE a;
    }
    
    /********************************************************
	 * Purpose: send to next step in async processing chain;
	 * 			in this case, getting any Assembly Components in the chain
	 * Input:	none - we use context variables
	 * Output:	! none ! - adding +1 job to Apex queue
	 ********************************************************/
    private void nextJob() {
        if (error) {
            if (assetIds.size() == 1) {
             	return;   
            }
        } else {
            index++;
        }
        if (index == assetIds.size()) {
            MS_FSM_EHINT_GetAssemblyComponents 	j 					= new MS_FSM_EHINT_GetAssemblyComponents();
        										j.newTopAssetIds	= assetIds;
        										j.index 			= 0;
            if (!Test.isRunningTest()) {
                System.enqueueJob(j);
            }
        }
        else {
            MS_FSM_AssetSubtreeProcessing j = new MS_FSM_AssetSubtreeProcessing(assetIds, index);
            System.enqueueJob(j);
        }
    }
    
    /********************************************************
	 * Purpose: create an Integration Error record if we could not
	 * 			get hits on the current record SN in EtaHub
	 * Input:	none - we use context variables
	 * Output:	! none ! - one DML for error record
	 ********************************************************/
    private void currentRecordError() {
        error = true;
        
        INSERT new Integration_Error__c(
        	Name 			 = 'Subtree Processing Error - ' + a.Id,
            Date__c 		 = System.today(),
            Origin_Class__c  = 'MS_FSM_AssetSubtreeProcessing',
            Record_Id__c 	 = a.Id,
            Error_Message__c = 'There were no hits on the SN for this Asset in either Assembly or CM Assembly. We are unable to proceed with subtree build.'
        );
        
        if (assetIds.size() == 1) {
            return;
        } else {
            index--;
        }
        List<String> remainingAssets = new List<String>();
        for (String s : assetIds) {
            if (s != a.Id) {
				remainingAssets.add(s);
            }
        }
        assetIds = remainingAssets;
    }
}