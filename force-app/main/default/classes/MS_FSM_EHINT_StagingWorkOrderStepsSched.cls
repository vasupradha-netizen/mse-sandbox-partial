/******************************************************************************
 * Name         : MS_FSM_EHINT_StagingWorkOrderStepsSched
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : schedulable interface to retrieve work order steps
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
global class MS_FSM_EHINT_StagingWorkOrderStepsSched implements Schedulable {

    private String ehId;
    private String woliid;
    private String woid;
    
    public MS_FSM_EHINT_StagingWorkOrderStepsSched(String e, String w, String p) {
        ehId 	= e;
        woliid 	= w;
        woid 	= p;
    }
    
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new MS_FSM_EHINT_StagingWorkOrderSteps(ehid, woliid, woid));
    }
}