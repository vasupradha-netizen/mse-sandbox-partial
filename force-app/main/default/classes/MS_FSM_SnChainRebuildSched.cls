/* ######################################################################################
INITIAL WRITE: 	May 2025																|
AUTHOR: 		empowherOps																|
 						Nathan Ehrmann		nathan@empowherops.com						|
 						Kortney Cervantes	kortney@empowherops.com						|
PURPOSE:		this allows nightly scheduling and kicks off a 2-part process			|
 				1. as seen below, we will start MS_FSM_SnChainRebuildRootBatch,			|
 					which batches over root assets (no parent) and determines			|
 					an appropriate next step											|
 				2. MS_FSM_SnChainRebuildQueue - this class runs recursively over		|
 					a tree to rebuild the MS_FSM_Serial_Chain__c on each Asset			|
 					to catch any swaps / changes and ensure an accurate Serial Chain	|
 					and L2 Asset														|
TEST COVERAGE:	MS_FSM_SnChainRebuildTests												|
####################################################################################### */

public class MS_FSM_SnChainRebuildSched implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new MS_FSM_SnChainRebuildRootBatch(), 1);
    }
}