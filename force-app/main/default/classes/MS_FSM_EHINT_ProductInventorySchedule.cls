/******************************************************************************
 * Name         : MS_FSM_EHINT_ProductInventorySchedule
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : schedulable interface for 15-minute product/inventory jobs
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
global class MS_FSM_EHINT_ProductInventorySchedule implements Schedulable {
    global void execute(SchedulableContext sc) {
        Boolean t = Test.isRunningTest();
        System.enqueueJob(new MS_FSM_EHINT_PartMaster(t ? 'all' : '', 1000, 0, !t));
    }
}