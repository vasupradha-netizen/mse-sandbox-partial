/******************************************************************************
 * Name         : MS_FSM_AssetStagingParentingQ
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-06-01
 * Description  : schedulable interface for MS_FSM_AssetStagingParentingQ
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-06-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_AssetStagingTest
 ******************************************************************************/
public class MS_FSM_AssetStagingParentingSched implements Schedulable {
    public void execute(SchedulableContext sc) {
        System.enqueueJob(new MS_FSM_AssetStagingParentingQ());
    }
}