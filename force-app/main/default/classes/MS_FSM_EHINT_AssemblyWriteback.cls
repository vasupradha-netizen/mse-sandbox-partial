/******************************************************************************
 * Name         : MS_FSM_EHINT_AssemblyWriteback
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : writes back a "sync date" to CM/Assembly table after completion
 * 				  of nightly sync
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
public class MS_FSM_EHINT_AssemblyWriteback implements Queueable, Database.AllowsCallouts {

    private List<String> 	topAssetIds;
    private String 			tableId;
    private String			updateField;
    private String			keyField;
    private Boolean 		skip;
    
    public MS_FSM_EHINT_AssemblyWriteback(List<String> ds, String t, String uf, Boolean s) {
        topAssetIds 	= ds;
        tableId 		= t;
        updateField 	= uf;
        keyField		= tableId == 'brv5unzwf' ? '12' : '3';
        skip			= s;
    }
    
    public void execute(QueueableContext qc) {
		sendToEh();
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_EHINT_ParentingQueue(topAssetIds, 0, null));
        }
    }
    
    private void sendToEh() {
        if (skip) {
            return;
        }
        
        String body = '{"to" : "' + tableId + '" , "data" : [';
        Integer i = 0;
        for (Asset a : [SELECT Id, MS_FSM_EtaHub_Record_Id__c, SerialNumber FROM Asset WHERE Id IN :topAssetIds]) {
            String idValue = tableId == 'brv5unzwf' ? ('"' + a.SerialNumber + '"') : a.MS_FSM_EtaHub_Record_Id__c;
            body += '{ "' + keyField + '" : { "value" : ' + idValue + '}, ';
            body += '"' + updateField + '" : { "value" : "' + String.valueOf(System.today()) + '" }}';
            if (i < topAssetIds.size() - 1) {
                body += ',';
            }
            i++;
        }
        body += ']}';
        MS_FSM_EHINT_Utils.updateEHData(body);
    }
}