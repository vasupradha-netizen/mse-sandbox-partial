/******************************************************************************
 * Name         : MS_FSM_EHINT_AssemblySchedule
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : schedulable interface for Assembly job chain
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
global class MS_FSM_EHINT_AssemblySchedule implements Schedulable {
    
    @TestVisible private MS_FSM_EHINT_GetAssemblies j;
    
    global void execute(SchedulableContext sc) { 
        j = j == null ? new MS_FSM_EHINT_GetAssemblies() : j;
        System.enqueueJob(j);
    }
}