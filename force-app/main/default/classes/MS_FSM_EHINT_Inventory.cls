/******************************************************************************
 * Name         : MS_FSM_EHINT_Inventory
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : retrieves inventory from EtaHub
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
public class MS_FSM_EHINT_Inventory implements Queueable, Database.AllowsCallouts {
    
    private String 	mode;
    private Boolean next;
    
    private Set<String> 	existingSerials;
    private List<String> 	repeatSerials;
    
    public MS_FSM_EHINT_Inventory(String m, Boolean n) {
        mode 				= m;
        next 				= n;
    }
    
    public void execute(QueueableContext q) { 
    	Set<String> ehSerials = new Set<String>();
        
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	invDefs = MS_FSM_EHINT_Utils.getIntDefs('bnk5gmxgy');
        List<Map<Integer, Map<String, String>>> 				invData = MS_FSM_EHINT_Utils.getEHData(invDefs.values(), 
                                                                                                       '{7.XEX.0}AND{33.XEX.}AND{728.EX.O&M}AND{981.EX.}', 
                                                                                                       0, 
                                                                                                       0);
        
        if (invData.isEmpty()) {											// NO HITS
            return;
        }
        
         if (MS_FSM_EHINT_Utils.handleError(invData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Inventory Failure', 
                invData[0].get(0).get('error'), 
                'NA', 
                'MS_FSM_EHINT_Inventory');
            return;
        }
        
        getExistingSerials(invData);
        repeatSerials = new List<String>();
        
        Set<String> prodCodes = new Set<String>();
        Set<String> locEhIds  = new Set<String>();
        for (Map<Integer, Map<String, String>> d : invData) {
            MS_FSM_EHINT_Utils.addString(prodCodes, d.get(33).get('value'));
            MS_FSM_EHINT_Utils.addString(locEhIds, d.get(47).get('value'));
        }
        
        Map<String, Product2> 		prodMap 		= getProdMap(prodCodes);
        Map<String, String> 		locMap 			= getLocMap(locEhIds);
        Map<String, ProductItem> 	compIdToProd 	= getCompMap(prodMap.keySet(), locMap.keySet());
        List<ProtoSerial>			serials			= new List<ProtoSerial>();
        
        for (Map<Integer, Map<String, String>> d : invData) {
        	String 		prodCode = d.get(33).get('value');
            String 		locEhId  = d.get(47).get('value');
            Product2 	prod	 = prodMap.get(prodCode);
            String 		locId 	 = locMap.get(locEhId);
            String      serial   = d.get(10).get('value');
            
            if (String.isBlank(prodCode) || String.isBlank(locEhId) || prod == null || String.isBlank(locId)) {
                continue;
            }
            
            Object o  = d.get(1029).get('value');
            Decimal c = o == null ? null : Decimal.valueOf((String)o);
            
            if (prod.IsSerialized) {
                if (existingSerials.contains(serial)) {
                    repeatSerials.add(serial);
                    continue;
                }
                
                serials.add(new ProtoSerial(prod.Id, 
                                            locId, 
                                            serial,
                                            c,
                                            d.get(1012).get('value') == 'true',
                                            d.get(1022).get('value')));
            }
            
            String compId = locId + prod.Id;
            
            if (compIdToProd.containsKey(compId)) {
                if (!prod.IsSerialized) {
                    compIdToProd.get(compId).QuantityOnHand += Decimal.valueOf(d.get(341).get('value'));
                }
            }
            else {
                compIdToProd.put(compId, new ProductItem(
                	Product2Id 				= prod.Id,
                    LocationId 				= locId,
                    QuantityUnitOfMeasure 	= d.get(39).get('value'),
                    QuantityOnHand  		= prod.IsSerialized ? 0 : Decimal.valueOf(d.get(341).get('value'))
                ));
            }
            
            if (!String.isBlank(serial)) {
                ehSerials.add(serial);
            }
        }
        
        errorMessage();
        
        UPSERT compIdToProd.values();
        
        List<SerializedProduct> newSerials = new List<SerializedProduct>();
        for (ProtoSerial p : serials) {
            SerializedProduct n = p.convert(compIdToProd);
            if (n == null) {
                continue;
            }
            newSerials.add(n);
        }
        
        INSERT newSerials;
        nextJob(ehSerials);
    }
    
    private void nextJob(Set<String> ehSerials) {
        if (!Test.isRunningTest() && next) {
            System.enqueueJob(new MS_FSM_EHINT_InventoryWriteback(ehSerials));
        }
    }
    
    private Map<String, Product2> getProdMap(Set<String> prodCodes) {
        Map<String, Product2> prodMap = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, ProductCode, IsSerialized FROM Product2 WHERE ProductCode IN :prodCodes]) {
            prodMap.put(p.ProductCode, p);
        }
        return prodMap;
    }
    
    private Map<String, String> getLocMap(Set<String> locEhIds) {
        Map<String, String> locMap = new Map<String, String>();
        for (Schema.Location l : [SELECT Id, MS_FSM_Location_Id__c FROM Location WHERE MS_FSM_Location_Id__c IN :locEhIds]) {
            locMap.put(l.MS_FSM_Location_Id__c, l.Id);
        }
        return locMap;
    }
    
    private Map<String, ProductItem> getCompMap(Set<String> prodCodes, Set<String> locEhIds) {
        Map<String, ProductItem> compMap = new Map<String, ProductItem>();
        for (ProductItem i : [SELECT Id, LocationId, Product2.ProductCode, QuantityOnHand
                              FROM   ProductItem
                              WHERE  Product2.ProductCode IN :prodCodes
                              AND    Location.MS_FSM_Location_Id__c IN :locEhIds
                              AND	 LocationId != ''
                              AND    Product2Id != '']) {
            compMap.put(String.valueOf(i.LocationId) + String.valueOf(i.Product2Id), i);
        }
        return compMap;
    }
    
    private void getExistingSerials(List<Map<Integer, Map<String, String>>> datas) {
        existingSerials = new Set<String>();
        Set<String> serials = new Set<String>();
        for (Map<Integer, Map<String, String>> d : datas) {
            String s = d.get(10).get('value');
            if (!String.isBlank(s)) {
             	serials.add(s);   
            }
        }
        
        if (serials.isEmpty()) {
            return;
        }
        
        for (SerializedProduct p : [SELECT SerialNumber FROM SerializedProduct WHERE SerialNumber IN :serials]) {
            existingSerials.add(p.SerialNumber);
        }
    }
    
    private void errorMessage() {
        if (repeatSerials.isEmpty()) {
            return;
        }
        Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
        m.setToAddresses(new List<String>{'anna.poon@mainspringenergy.com', 'kristin.elmstrom@mainspringenergy.com'});
        m.setSubject('EtaHub Inventory Sync - Repeated Serials');
        
        String b = '<p>The following serials were sent in an inventory sync and encountered repeats in the SerializedProduct table:</p><br/>';
        b += ('<p>' + String.join(repeatSerials, ', ') + '</p><br/>');
        m.setHtmlBody(b);
        
        if (!Test.isRunningTest()) {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{m}, true);
        }
    }
    
    private class ProtoSerial {
        
        private String 	productId;
        private String 	locationId;
        private String 	serial;
        private Decimal cost;
        private Boolean buildHierarchy;
        private String  tag;
        
        public ProtoSerial(String pid, String lid, String s, Decimal c, Boolean h, String t) {
            productId 		= pid;
            locationId 		= lid;
            serial			= s;
            cost			= c;
            buildHierarchy 	= h;
            tag				= t;
        }
        
        public SerializedProduct convert(Map<String, ProductItem> compMap)
        {
            String k = locationId + productId;
            if (String.isBlank(k)) {
                return null;
            }
            
            ProductItem pit = compMap.get(k);
            if (pit == null) {
                return null;
            }
            
            return new SerializedProduct(
            	ProductItemId 					= pit.Id,
                Product2Id	  					= productId,
                SerialNumber  				 	= serial,
                MS_FSM_Product_Cost__c			= cost,
                MS_FSM_Original_Product_Cost__c	= cost,
                MS_FSM_Build_Hierarchy__c 		= true,
                MS_FSM_Core_Package_Unit_Tag__c = tag
            );
        }
    }
}