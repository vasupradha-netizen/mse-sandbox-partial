@isTest
private class SitesManageSiteProductsTest {
    
    @isTest
    static void standard() {
        Opportunity opp = new Opportunity(
            Name 		= 'Test class Opportunity',
            StageName 	= 'Prospecting',
            CloseDate 	= Date.today().addDays(30)
        );
        INSERT opp;
        
        Product2 p = new Product2(
        	Name = 'test product'
        );
        INSERT p;
        
       	PricebookEntry pbe = new PricebookEntry(
            Product2Id 		= p.Id,
            Pricebook2Id 	= Test.getStandardPricebookId(),
            UnitPrice		= 0,
            IsActive        = true
        );
        INSERT pbe;
        
        INSERT new OpportunityLineItem(
        	PricebookEntryId 	= pbe.Id,
            Quantity 			= 1,
            UnitPrice 			= 1,
            OpportunityId 		= opp.Id
        );
        
        Sites__c s = new Sites__c(
            Opportunity__c 	= opp.Id
        );
        INSERT s;
        
        Opportunity npp = new Opportunity(
            Name 		= 'Test second Opportunity',
            StageName 	= 'Prospecting',
            CloseDate 	= Date.today().addDays(30)
        );
        INSERT npp;
        
        INSERT new OpportunityLineItem(
        	PricebookEntryId 	= pbe.Id,
            Quantity 			= 1,
            UnitPrice 			= 1,
            OpportunityId 		= npp.Id
        );
        
        SitesTriggerHandler.reset();

        UPDATE new Sites__c(
            Id 				= s.Id,
        	Opportunity__c 	= npp.Id
        );

        for (OpportunityLineItem oli : [SELECT OpportunityId, Site__c FROM OpportunityLineItem]) {
            Assert.areEqual(oli.OpportunityId == npp.Id, oli.Site__c == s.Id, 'Site Line Item Processing incorrect');
        }
    }
}