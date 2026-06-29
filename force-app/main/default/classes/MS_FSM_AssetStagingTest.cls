@isTest
private class MS_FSM_AssetStagingTest {
    
    @isTest
    static void newAsset() {
        List<Product2> prods = new List<Product2>();
        Product2 pa = new Product2(
        	Name 		= 'test product',
            ProductCode = 'ABC'
        );
        Product2 pb = new Product2(
        	Name 		= 'test other',
            ProductCode = 'DEF'
        );
        prods.add(pa);
        prods.add(pb);
        INSERT prods;
        
        AssetTriggerHandler.skipProcessing();
        INSERT new Asset(
            Name 		 = 'test parent',
        	Product2Id 	 = pa.Id,
            SerialNumber = '123'
        );
        
        Test.startTest();
        INSERT new MS_FSM_EtaHub_Asset_Staging__c(
        	MS_FSM_Status__c 				= 'Installed',
            MS_FSM_Asset_Serial_Number__c 	= '456',
            MS_FSM_Part_Number__c 			= 'DEF',
            MS_FSM_Description__c 			= 'test staging asset',
            MS_FSM_Timestamp__c 			= System.now().addMinutes(-10),
            MS_FSM_Parent_Serial_Number__c 	= '123'
        );
        Test.stopTest();
    }
    
    @isTest
    static void existingAsset() {
        List<Product2> prods = new List<Product2>();
        Product2 pa = new Product2(
        	Name 		= 'test product',
            ProductCode = 'ABC'
        );
        Product2 pb = new Product2(
        	Name 		= 'test other',
            ProductCode = 'DEF'
        );
        prods.add(pa);
        prods.add(pb);
        INSERT prods;
        
        AssetTriggerHandler.skipProcessing();
        Asset t = new Asset(
            Name 		 = 'test update',
        	Product2Id 	 = pa.Id,
            SerialNumber = '123'
        );
        INSERT t;
        
        Test.startTest();
        INSERT new MS_FSM_EtaHub_Asset_Staging__c(
            MS_FSM_Asset_Id__c				= t.Id,
        	MS_FSM_Status__c 				= 'Installed',
            MS_FSM_Asset_Serial_Number__c 	= '123',
            MS_FSM_Part_Number__c 			= 'ABC',
            MS_FSM_Description__c 			= 'test staging asset',
            MS_FSM_Timestamp__c 			= System.now().addMinutes(-10)
        );
        Test.stopTest();
    }
    
    @isTest
    static void existingAtl() {
        List<Product2> prods = new List<Product2>();
        Product2 pa = new Product2(
        	Name 		= 'test product',
            ProductCode = 'ABC'
        );
        Product2 pb = new Product2(
        	Name 		= 'test other',
            ProductCode = 'DEF'
        );
        prods.add(pa);
        prods.add(pb);
        INSERT prods;
        
        AssetTriggerHandler.skipProcessing();
        Asset t = new Asset(
            Name 		 = 'test update',
        	Product2Id 	 = pa.Id,
            SerialNumber = '123'
        );
        INSERT t;
        INSERT new MS_FSM_Asset_Transaction_Log__c(
        	MS_FSM_Asset_Id__c 	= t.Id,
            MS_FSM_Timestamp__c = System.now().addHours(-1)
        );
        
        Test.startTest();
        INSERT new MS_FSM_EtaHub_Asset_Staging__c(
            MS_FSM_Asset_Id__c				= t.Id,
        	MS_FSM_Status__c 				= 'Installed',
            MS_FSM_Asset_Serial_Number__c 	= '123',
            MS_FSM_Part_Number__c 			= 'ABC',
            MS_FSM_Description__c 			= 'test staging asset',
            MS_FSM_Timestamp__c 			= System.now().addHours(-2)
        );
        Test.stopTest();
    }
}