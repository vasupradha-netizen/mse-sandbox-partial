public class SitesManageSiteProducts {
    
    public static void clearOppyProducts(List<String> oppIds) {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (OpportunityLineItem o : [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :oppIds]) {
            olis.add(new OpportunityLineItem(
            	Id 		= o.Id,
                Site__c = null
            ));
        }
        UPDATE olis;
    }
    
    public static void populateOppyProducts(Map<String, String> oppyToSite) {
        List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        for (OpportunityLineItem o : [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId IN :oppyToSite.keySet()]) {
            olis.add(new OpportunityLineItem(
            	Id 		= o.Id,
                Site__c = oppyToSite.get(o.OpportunityId)
            ));
        }
        UPDATE olis;
    }
}