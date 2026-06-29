public class SitesTriggerHandler {
    
    private static Boolean hasRun = false;
    
    public static void skipProcessing() {
        hasRun = true;
    }
    
    @TestVisible
    private static void reset() {
        hasRun = false;
    }
    
    private static final Set<String> ADDRESS_FIELDS = new Set<String>{
        'Street_1__c',
        'Street_2__c',
        'City__c',
        'State_Region__c',
        'Country__c',
        'Postal_Code__c'
    };
    
    public static void mainEntry(Boolean 			isBefore,
                                 Boolean 			isAfter,
                                 Boolean 			isInsert,
                                 Boolean 			isUpdate,
                                 Boolean 			isDelete,
                                 List<Sites__c> 	newRecs,
                                 Map<Id, Sites__c>  oldMap) 
    {
        if (hasRun) {
            return;
        }
        
        if (isAfter) {
            hasRun = true;
        }
        
        List<String> geocodeIds 		= new List<String>();
        List<String> clearOppys 		= new List<String>();
        Map<String, String> oppyToSite 	= new Map<String, String>();
        
        for (Sites__c n : newRecs) {
         	Sites__c o = oldMap == null ? null : oldMap.get(n.Id);
            if (hasAddressChange(n, o)) {
                geocodeIds.add(n.Id);
            }
            
            if (!String.isBlank(n.Opportunity__c)) {
                String nOpp = n.Opportunity__c;
                if (o == null) {
                    oppyToSite.put(nOpp, n.Id);
                } else {
                    String vOpp = o.Opportunity__c;
                    if (change(nOpp, vOpp)) {
                        oppyToSite.put(nOpp, n.Id);
                        if (!String.isBlank(vOpp)) {
                            clearOppys.add(vOpp);
                        }
                    }
                }
            }
        }
        
        if (!geocodeIds.isEmpty()) {
            System.enqueueJob(new GeocodeJob(geocodeIds));
        }
        
        if (!clearOppys.isEmpty()) {
            SitesManageSiteProducts.clearOppyProducts(clearOppys);
        }
        
        if (!oppyToSite.values().isEmpty()) {
            SitesManageSiteProducts.populateOppyProducts(oppyToSite);
        }
    }
    
    private static Boolean change(String s, String t) {
        return !String.isBlank(s) && s != t;
    }
    
    private static Boolean hasAddressChange(Sites__c n, Sites__c o) {
        for (String f : ADDRESS_FIELDS) {
            String s = (String)n.get(f);
            String t = o == null ? '' : (String)o.get(f);
            if (change(s, t)) {
                return true;
            }
        }
        
        return false;
    }
    
}