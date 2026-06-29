/******************************************************************************
 * Name         : MS_FSM_EHINT_CreateLogsBatch
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : batch class for creating Asset Transaction Logs. ends the
 * 			      CM/Assembly chain.
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_CreateLogsBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id,
                                                SerialNumber,
                                                Parent.SerialNumber,
                                                MS_FSM_EtaHub_Table_Id__c,
                                                MS_FSM_EtaHub_Record_Id__c,
                                                MS_FSM_Install_Date_Time__c,
                                                LocationId,
                                          		RootAssetId,
                                                RootAsset.LocationId
                                         FROM   Asset
                                         WHERE  MS_FSM_Create_ATL__c = true]);
    }
    
    public void execute(Database.BatchableContext bc, List<Asset> scope) {
		List<MS_FSM_Asset_Transaction_Log__c> atls = new List<MS_FSM_Asset_Transaction_Log__c>();
        for (Asset a : scope) {
            a.MS_FSM_Create_ATL__c = false;
            atls.add(new MS_FSM_Asset_Transaction_Log__c(
            	MS_FSM_Asset_Serial_Number__c 			= a.SerialNumber,
                MS_FSM_Asset_Id__c 						= a.Id,
                MS_FSM_Status__c 						= 'Installed',
                MS_FSM_Transaction_Type__c 				= 'Status Change',
                MS_FSM_Parent_Asset_Serial_Number__c 	= a.Parent.SerialNumber,
                MS_FSM_EtaHub_Source_Table__c 			= a.MS_FSM_EtaHub_Table_Id__c,
                MS_FSM_EtaHub_Record_Id__c 				= a.MS_FSM_EtaHub_Record_Id__c,
                MS_FSM_Timestamp__c 					= a.MS_FSM_Install_Date_Time__c,
                MS_FSM_Location_Id__c 					= a.RootAsset.LocationId
            ));
        }
        INSERT atls;
        UPDATE scope;
    }
    
    public void finish(Database.BatchableContext bc) { /* DO NOTHING */ }
}