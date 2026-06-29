/******************************************************************************
 * Name         : MS_FSM_AssetSubtreeSched
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-02-01
 * Description  : schedulable interface for subtree builds / core swaps
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
public class MS_FSM_AssetSubtreeSched implements Schedulable {
    
    List<String> assetIds;
    
    public MS_FSM_AssetSubtreeSched(List<String> aids) {
        assetIds = aids;
    }
    
    public void execute(SchedulableContext sc) {
        MS_FSM_AssetSubtreeHelper.applySnToLgen(assetIds);
        System.enqueueJob(new MS_FSM_AssetSubtreeProcessing(assetIds, 0));
    }
}