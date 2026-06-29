/******************************************************************************
 * Name         : MS_FSM_EHINT_GetStagingWorkOrderSched
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : schedulable interface to kick off *StagingWorkOrder chain
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
global class MS_FSM_EHINT_GetStagingWorkOrderSched implements Schedulable {
    global void execute(SchedulableContext sc) {
        System.enqueueJob(new MS_FSM_EHINT_GetStagingWorkOrderQueue());
    }
}