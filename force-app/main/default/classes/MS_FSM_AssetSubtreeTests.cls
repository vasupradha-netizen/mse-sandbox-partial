@isTest
private class MS_FSM_AssetSubtreeTests {
    
    @isTest
    static void standard() {
        Product2 p 	= [SELECT Id FROM Product2 LIMIT 1];
        Account  a 	= [SELECT Id FROM Account  LIMIT 1];

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ehint_assembly');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        INSERT new Asset(
        	Name 			= 'test',
            AccountId 		= a.Id,
            Status 			= 'Installed',
            SerialNumber 	= '123',
            Product2Id 		= p.Id
        );
        Test.stopTest();
    }
    
    @isTest
    static void faultNoHits() {
        Product2 p 	= [SELECT Id FROM Product2 LIMIT 1];
        Account  a 	= [SELECT Id FROM Account  LIMIT 1];

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ehint_empty');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        INSERT new Asset(
        	Name 			= 'test',
            AccountId 		= a.Id,
            Status 			= 'Installed',
            SerialNumber 	= '123',
            Product2Id 		= p.Id
        );
        Test.stopTest();
    }
    
    @TestSetup
    static void setupData() {
        Schema.Location l = new Schema.Location(
        	Name 				= 'test',
            LocationType 		= 'Warehouse',
            IsInventoryLocation = true
        );
        INSERT l;
        
        Product2 p = new Product2(
        	Name 			= 'test',
            IsSerialized 	= true
        );
        INSERT p;
        
        ProductItem i = new ProductItem(
        	Product2Id 		= p.Id,
            LocationId 		= l.Id,
            QuantityOnHand 	= 0
        );
        INSERT i;
        
        INSERT new SerializedProduct(
        	ProductItemId 				= i.Id,
            SerialNumber 				= '123',
            MS_FSM_Build_Hierarchy__c 	= true,
            Product2Id 					= p.Id
        );
        
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        
        Test.loadData(MS_FSM_EtaHub_Integration_Definition__c.sObjectType, 'ehint_data');
    }
}