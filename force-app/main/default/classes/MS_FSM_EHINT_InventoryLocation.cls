/******************************************************************************
 * Name         : MS_FSM_EHINT_InventoryLocation
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : retrieves inventory locations from EtaHub
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
public class MS_FSM_EHINT_InventoryLocation implements Queueable, Database.AllowsCallouts {
    
    public 	String  mode;
    public 	Boolean next;
    private Boolean incrementMinutes;
    
    public MS_FSM_EHINT_InventoryLocation(String m, Boolean n, Boolean d) {
        mode 				= m;
        next 				= n;
        incrementMinutes 	= d;
    }
    
    public void execute(QueueableContext q) {
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	locDefs = MS_FSM_EHINT_Utils.getIntDefs('bqzwcecb4');
        List<Map<Integer, Map<String, String>>> 				locData = MS_FSM_EHINT_Utils.getEHData(locDefs.values(), 
                                                                                               		   '{82.EX.O&M}AND{25.EX.0}' + MS_FSM_EHINT_Utils.getStdDateFilter(mode, 2, true), 
                                                                                               		   0, 
                                                                                                       0);
        
        if (locData.isEmpty()) {											// NO HITS
            nextJob();
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(locData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Inventory Location Failure', 
                locData[0].get(0).get('error'), 
                'NA', 
                'MS_FSM_EHINT_InventoryLocation');
            incrementMinutes = true;
            nextJob();
            return;
        }
        
        List<Schema.Location> newLocs = new List<Schema.Location>();
        
        Set<String> 					locNames = new Set<String>();
        Map<String, Schema.Location> 	locMap	 = new Map<String, Schema.Location>();
        for (Map<Integer, Map<String, String>> d : locData) {
            MS_FSM_EHINT_Utils.addString(locNames, d.get(9).get('value'));
        }
        for (Schema.Location loc : [SELECT Id, Name FROM Location WHERE Name IN :locNames]) {
            locMap.put(loc.Name, loc);
        }
        
        for (Map<Integer, Map<String, String>> d : locData) {
            Schema.Location l = locMap.get(d.get(9).get('value'));
            
            if (l == null) {
                l = new Schema.Location(
                    LocationType  		= 'Warehouse',
                    IsInventoryLocation = true
                );
            }
            
            MS_FSM_EHINT_Utils.mapValues(d, locDefs, l);
            newLocs.add(l);
        }
        
        UPSERT newLocs;
        nextJob();
    }
    
    private void nextJob() {
        MS_FSM_EHINT_Utils.updateMinutes(!incrementMinutes);
        if (!Test.isRunningTest() && next) {
            System.enqueueJob(new MS_FSM_EHINT_Inventory('', true));
        }
    }
}