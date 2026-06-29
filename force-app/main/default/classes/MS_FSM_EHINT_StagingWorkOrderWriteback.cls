/******************************************************************************
 * Name         : MS_FSM_EHINT_StagingWorkOrderWriteback
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : writes back sync fields for a retrofit WO to EH;
 * 				  cycles back to step 1 for additional WO
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
public class MS_FSM_EHINT_StagingWorkOrderWriteback implements Queueable, Database.AllowsCallouts {
    
    private String ehWorkOrderId;
    private String sfWorkOrderId;
    private String sfWorkOrderLineId;
    
    @TestVisible private Boolean forceError = false;
    
    public MS_FSM_EHINT_StagingWorkOrderWriteback(String ehid, String sfwoid, String sfwoliid) {
        ehWorkOrderId 		= ehid;
        sfWorkOrderId 		= sfwoid;
        sfWorkOrderLineId 	= sfwoliid;
    }
    
    public void execute(QueueableContext q) { 
    	String workOrderUrl = URL.getOrgDomainURL().toExternalForm() 		+ '/' + sfWorkOrderId;
        String workOrderLineUrl = URL.getOrgDomainURL().toExternalForm() 	+ '/' + sfWorkOrderLineId;
        
        String body = '{"to": "bufd2pu5y", "data" : [{ "3" : { "value" : ' + ehWorkOrderId + ' },  "19" : { "value" : "' + workOrderUrl + '"}, "20" : { "value" : "' + workOrderLineUrl + '"}}]}';
        try {
            if (forceError) {
                throw new CalloutException('test');
            }
        	MS_FSM_EHINT_Utils.updateEHData(body);
        } catch (Exception ex) {
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Retrofit WO Writeback Error',
                ex.getMessage(),
                sfWorkOrderId,
                'MS_FSM_EHINT_StagingWorkOrderWriteback'
            );
        }
        
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_EHINT_GetStagingWorkOrderQueue());
        }
    }
}