/******************************************************************************
 * Name         : MS_FSM_EHINT_MasterPartRecord
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : retrieves Master Part Records (revs) from EH to become Product2
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
public class MS_FSM_EHINT_MasterPartRecord implements Queueable, Database.AllowsCallouts {

    private Integer offset;
    private Integer top;
    private String	mode;
    private Boolean next;
    private Boolean incrementMinutes;
    
    public MS_FSM_EHINT_MasterPartRecord(String m, Integer t, Integer i, Boolean n, Boolean d) {
        mode				= m;
        top					= t;
        offset 				= i;
        next				= n;
        incrementMinutes 	= d;
    }
    
    public void execute(QueueableContext q) { 
    	List<Product2> newProds = new List<Product2>();
        
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	mpRecordDefs = MS_FSM_EHINT_Utils.getIntDefs('bnjiec2wn');
        List<Map<Integer, Map<String, String>>> 				mpRecordData = MS_FSM_EHINT_Utils.getEHData(mpRecordDefs.values(), 
                                                                                                            '{708.EX.0}' + MS_FSM_EHINT_Utils.getStdDateFilter(mode, 719, true), 
                                                                                                            top, 
                                                                                                            offset);
        
        if (mpRecordData.isEmpty()) {
            nextJob(-1);
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(mpRecordData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Master Part Record Failure', 
                mpRecordData[0].get(0).get('error'), 
                'NA', 
                'MS_FSM_EHINT_MasterPartRecord');
            nextJob(-1);
            return;
        }
        
        Set<String> prodCodes = new Set<String>();
        for (Map<Integer, Map<String, String>> d : mpRecordData) {
            String c = d.get(21).get('value');
            
            if (badRecord(c)) {
                continue;
            }
            
            MS_FSM_EHINT_Utils.addString(prodCodes, c);
            MS_FSM_EHINT_Utils.addString(prodCodes, c.left(c.indexOf('_')));
        }
        
        Map<String, Product2> productCodeMap = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, 
                            	  ProductCode,
                           		  MS_FSM_Maintenance_Plan_Required__c,
                                  IsSerialized,
                           		  (SELECT Id FROM ProductItems WHERE QuantityOnHand > 0)
                           FROM   Product2 
                           WHERE  ProductCode IN :prodCodes]) 
        { 
            productCodeMap.put(p.ProductCode, p); 
        }
        
        for (Map<Integer, Map<String, String>> d : mpRecordData) {
            String c = d.get(21).get('value');
            
            if (badRecord(c)) {
                continue;
            }
            
            Product2 newProd = productCodeMap.get(c);
            Product2 parent  = productCodeMap.get(c.left(c.indexOf('_')));
            
            if (parent == null) {
                continue;
            }
            
            if (newProd == null) {
                newProd = new Product2(Name 								= (d.get(21).get('value') + ' | ' + d.get(9).get('value')).left(80),
                                       MS_FSM_Revision__c 					= true,
                                       MS_FSM_Parent_Product__c 			= parent.Id,
                                       MS_FSM_Maintenance_Plan_Required__c 	= parent.MS_FSM_Maintenance_Plan_Required__c
                                      );
            }
            
            if (serializeChange(newProd, d.get(664).get('value') == 'true', newProds)) {
                continue;
            }
            
            MS_FSM_EHINT_Utils.mapValues(d, mpRecordDefs, newProd);
            newProds.add(newProd);
        }
        
        UPSERT newProds;
        nextJob(mpRecordData.size());
    }
    
    private void nextJob(Integer size) {
        if (size == top) { 
            System.enqueueJob(new MS_FSM_EHINT_MasterPartRecord(mode, top, offset + top, next, incrementMinutes)); 
            return;
        }
        
        if (!Test.isRunningTest() && next) {
            System.enqueueJob(new MS_FSM_EHINT_InventoryLocation(mode, next, incrementMinutes));
        }
    }
    
    private Boolean serializeChange(Product2 p, Boolean b, List<Product2> ps) {
        Boolean s = p.IsSerialized;
        if (String.isBlank(p.Id) || s == b || p.ProductItems.isEmpty()) {
            return false;
        }
        p.MS_FSM_Serialization_Review__c = String.valueOf(System.today()) + ' - attempted change from ' + s + ' to ' + b;
        ps.add(p);
        return true;
    }
    
    private Boolean badRecord(String c) {
        return String.isBlank(c) || c.indexOf('_') == -1;
    }
}