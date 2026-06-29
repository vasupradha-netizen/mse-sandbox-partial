/******************************************************************************
 * Name         : MS_FSM_EHINT_InventoryWriteback
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : writes back sync fields to EH;
 * 				  concludes the 15-minute inventory sync;
 * 					Part Master --> Master Part Record --> Inventory Location --> Inventory --> Writeback
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
public class MS_FSM_EHINT_InventoryWriteback implements Queueable, Database.AllowsCallouts {
    
    private Set<String>  ehSerials;
    
    @TestVisible private Boolean forceError = false;
    
    public MS_FSM_EHINT_InventoryWriteback(Set<String> ds) {
        ehSerials = ds;
    }
    
    public void execute(QueueableContext qc) {
        String body = '{"to" : "bnk5gmxgy" , "data" : [';
        Integer i = 0;
        for (String s : ehSerials) {
            body += '{';
            body += '"62" :  { "value" : "' 	+ s 													+ 	'" }, ';
            body += '"981" : { "value" : "' 	+ System.now().format('YYYY-MM-dd\'T\'hh:mm:ss\'Z\'') 	+ 	'" }';
            body += '}';
            if (i < ehSerials.size() - 1) {
                body += ',';
            }
            i++;
        }
        body += ']}';
        try {
            if (forceError) {
                throw new CalloutException('test');
            }
        	MS_FSM_EHINT_Utils.updateEHData(body);
        } catch (Exception ex) {
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Inventory Writeback Failure', 
                ex.getMessage(), 
                'NA', 
                'MS_FSM_EHINT_InventoryWriteback');
        }
    }
}