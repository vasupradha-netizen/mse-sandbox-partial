/******************************************************************************
 * Name         : MS_FSM_EHINT_StagingWorkOrderSteps
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : retrieves Work Steps, which come from the Staging Work Order table
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
public class MS_FSM_EHINT_StagingWorkOrderSteps implements Queueable, Database.AllowsCallouts {

    private String ehId;
    private String woliid;
    private String woid;
    
    public MS_FSM_EHINT_StagingWorkOrderSteps(String e, String w, String p) {
        ehId 	= e;
        woliid 	= w;
        woid	= p;
    }
    
    public void execute(QueueableContext qc) {
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c>   swoLineDefs = MS_FSM_EHINT_Utils.getIntDefs('bufd2q7wt');
        List<Map<Integer, Map<String, String>>> 				swoLineData = MS_FSM_EHINT_Utils.getEHData(swoLineDefs.values(), '{6.EX.' + ehId + '}', 0, 0);
        
       	if (MS_FSM_EHINT_Utils.handleError(swoLineData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - ' + woliid + ' - Staging Work Order Steps Failure', 
                swoLineData[0].get(0).get('error'), 
                woliid, 
                'MS_FSM_EHINT_StagingWorkOrderSteps');
            nextJob();
            return;
        }
        
        try {
            WorkPlan wp = [SELECT Id FROM WorkPlan WHERE ParentRecordId = :woliid];		// this line may fail; we do nothing on exception
            List<WorkStep> wss = new List<WorkStep>();
            for (Map<Integer, Map<String, String>> d : swoLineData) {
                if (d.get(8).get('value') == 'Enter SN for ') {
                    continue;
                }
                WorkStep ws = new WorkStep(WorkPlanId = wp.Id, Status = 'New', ExecutionOrder = 1);
                MS_FSM_EHINT_Utils.mapValues(d, swoLineDefs, ws);
                wss.add(ws);
            }
            INSERT wss;
        } 
        catch (Exception ex) {
            /* DO NOTHING */
        }
        
        nextJob();
    }
    
    private void nextJob() {
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_EHINT_StagingWorkOrderServiceAppt(ehId, woid, woliid));
        }
    }
}