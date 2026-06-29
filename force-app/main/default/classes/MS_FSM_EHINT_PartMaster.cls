/******************************************************************************
 * Name         : MS_FSM_EHINT_PartMaster
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : gets "master" products (which are used as parents and not
 * 				  associated with Assets)
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
public class MS_FSM_EHINT_PartMaster implements Queueable, Database.AllowsCallouts {
    
    private Integer offset;
    private Integer top;
    private String	mode;		// can be set to "all" to reset all products; not advised
    private Boolean next;
    
    public MS_FSM_EHINT_PartMaster(String m, Integer t, Integer i, Boolean n) {
        mode	= m;
        top		= t;
        offset 	= i;
        next	= n;
    }
    
    public void execute(QueueableContext q) {   
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> partMasterDefs = MS_FSM_EHINT_Utils.getIntDefs('bpk87rsn2');
        
        List<Product2> newProds = new List<Product2>();
        
        List<Map<Integer, Map<String, String>>> partMasterData = MS_FSM_EHINT_Utils.getEHData(partMasterDefs.values(), 
                                                                                              MS_FSM_EHINT_Utils.getStdDateFilter(mode, 2, false), 
                                                                                              top, 
                                                                                              offset);
        
        if (partMasterData.isEmpty()) { 
            nextJob(-1, false);
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(partMasterData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Part Master Failure', 
                partMasterData[0].get(0).get('error'), 
                'NA', 
                'MS_FSM_EHINT_PartMaster');
            nextJob(-1, true);
            return;
        }
        
        Set<String> prodCodes = new Set<String>();
        for (Map<Integer, Map<String, String>> d : partMasterData) {
            MS_FSM_EHINT_Utils.addString(prodCodes, d.get(6).get('value'));
        }
        Map<String, Id> prodCodeToId = new Map<String, Id>();
        for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN : prodCodes]) {
            prodCodeToId.put(p.ProductCode, p.Id);
        }
        
        for (Map<Integer, Map<String, String>> d : partMasterData) {
            String prodCode = d.get(6).get('value');
            
            if (String.isBlank(prodCode)) {
                continue;
            }
            
            Id ex = prodCodeToId.get(prodCode);
            
            Product2 p;
            if (!String.isBlank(ex)) {
                p = new Product2(Id = ex);
            } else {
                p = new Product2(Name 		= d.get(427).get('value').left(80),
                                 IsActive 	= true,
                                 test__c	= true);
            }
            
            MS_FSM_EHINT_Utils.mapValues(d, partMasterDefs, p);
            newProds.add(p);
        }
        
        UPSERT newProds;
        nextJob(partMasterData.size(), false);
    }
    
    private void nextJob(Integer size, Boolean hasError) {
        if (size == top) {
            System.enqueueJob(new MS_FSM_EHINT_PartMaster(mode, top, offset + top, next)); 
            return;
        }
        
        if (!Test.isRunningTest() && next) {
            System.enqueueJob(new MS_FSM_EHINT_MasterPartRecord('', 5000, 0, next, hasError));
        }
    }
}