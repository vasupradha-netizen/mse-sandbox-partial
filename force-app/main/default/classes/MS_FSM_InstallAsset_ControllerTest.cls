@isTest
public class MS_FSM_InstallAsset_ControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create Account record
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create WorkType record
        WorkType wt = new WorkType(
            Name = 'Test Work Type',
            EstimatedDuration = 5,
            MS_FSM_Sub_Type__c = 'Work Order Line Item'
        );
        insert wt;
        
        // Create Location record (using Location)
        Schema.Location n = new Schema.Location(
            Name = 'InventoryLocation1',
            LocationType = 'Site',
            IsInventoryLocation = true
            );
        INSERT n; 
        
        OperatingHours ot = new OperatingHours(Name = 'Test OT');
        insert ot;
        
        ServiceTerritory st = new ServiceTerritory(Name = 'Test ST', OperatingHoursId = ot.id, IsActive = true);
        insert st;

        // Create WorkOrder record
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            LocationId = n.Id,
            ServiceTerritoryId = st.id
        );
        insert wo;

        // Create Asset record
        Asset parentAsset = new Asset(Name = 'Parent Asset', Status = 'Active');
        insert parentAsset;
        
        Asset asset = new Asset(
            Name = 'Test Asset',
            Status = 'Active',
            MS_FSM_Asset_Placement__c = 'INT', 
            ParentId = parentAsset.Id 
        );
        insert asset;

        // create product, product item with qty 0, create serialized product related to product item
        
        // Create a Product record
        Product2 prod = new Product2(
            Name = 'Product Swap', 
            IsActive = true,
            MS_FSM_Product_Type__c = 'Asset',
            IsSerialized = true
            );
        insert prod;
        
        // Create a Product record
        Product2 prod2 = new Product2(
            Name = 'Product Swap2', 
            IsActive = true,
            MS_FSM_Product_Type__c = 'Asset',
            MS_FSM_Parent_Product__c = prod.Id,
            IsSerialized = true
            );
        insert prod2;

        // Create ProductItem record
        ProductItem productItem = new ProductItem(
            Product2Id = prod.Id,
            LocationId = n.Id, 
            QuantityOnHand = 0,
            QuantityUnitOfMeasure = 'ea'
        );
        insert productItem;
        
        // Create ProductItem record
        ProductItem productItem2 = new ProductItem(
            Product2Id = prod2.Id,
            LocationId = n.Id, 
            QuantityOnHand = 0,
            QuantityUnitOfMeasure = 'ea'
        );
        insert productItem2;

        // Create SerializedProduct record
        SerializedProduct serializedProduct = new SerializedProduct(
            ProductItemId = productItem2.Id,
            Status = 'Available',
            SerialNumber = 'SN001',
            Product2Id = prod2.Id
        );
        insert serializedProduct;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            WorkTypeId = wt.Id,
            MS_FSM_Install_Swap_Product__c = prod.Id, 
            AssetId = asset.Id
        );
        insert woli;
        
        ServiceTerritoryLocation serviceTerritoryLoc = new ServiceTerritoryLocation(LocationId = n.Id, ServiceTerritoryId = st.Id);
        insert serviceTerritoryLoc;
    }

    @isTest
    static void testGetCurrentInstallAssetDetails() {
        
        // Fetch the WorkOrderLineItem we created in setup
        WorkOrderLineItem woli = [SELECT Id, LineItemNumber, WorkOrder.WorkOrderNumber, Asset.Name FROM WorkOrderLineItem LIMIT 1];

        Test.startTest();
        // Call the method and assert the correct fields are returned
        WorkOrderLineItem result = MS_FSM_InstallAsset_Controller.getCurrentInstallAssetDetails(woli.Id);
        Test.stopTest();

        // Assert the expected values
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(woli.LineItemNumber, result.LineItemNumber, 'Expected LineItemNumber does not match');
        System.assertNotEquals(null, result.WorkOrder.WorkOrderNumber, 'WorkOrder should be populated');
    }

    @isTest
    static void testGetCurrentInstallAssetDetailsCatchError() {
        List<Account> accountList = [Select id from Account where Name = 'Test Account'];
        Boolean exceptionCaught = false;

        Test.startTest();
        try {
            // Call the method and assert the correct fields are returned
            WorkOrderLineItem result = MS_FSM_InstallAsset_Controller.getCurrentInstallAssetDetails(accountList[0].Id);
         } catch (Exception ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

		System.assertEquals(true, exceptionCaught, 'exception was not caught');

    }
    
    @isTest
    static void testGetCurrentReplaceAssetDetails() {
        WorkOrderLineItem woli = [SELECT Id, LineItemNumber, WorkOrder.WorkOrderNumber, Asset.Name FROM WorkOrderLineItem LIMIT 1];
        Test.startTest();
        WorkOrderLineItem result = MS_FSM_InstallAsset_Controller.getCurrentReplaceAssetDetails(woli.Id);
        Test.stopTest();
        System.assertEquals(woli.LineItemNumber, result.LineItemNumber, 'Expected LineItemNumber does not match');
        System.assertNotEquals(null, result.WorkOrder.WorkOrderNumber, 'WorkOrder should be populated');
    }
    
    @isTest
    static void testGetCurrentReplaceAssetDetailsCatchError() {
        List<Account> accountList = [Select id from Account where Name = 'Test Account'];
        Boolean exceptionCaught = false;

        Test.startTest();
        try {
            // Call the method and assert the correct fields are returned
            WorkOrderLineItem result = MS_FSM_InstallAsset_Controller.getCurrentReplaceAssetDetails(accountList[0].Id);
         } catch (Exception ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

		System.assertEquals(true, exceptionCaught, 'exception was not caught');

    }
    
    @isTest
    static void testGetLocationName() {
        Test.startTest();
        Schema.Location n = [SELECT Id FROM Location WHERE Name = 'InventoryLocation1' and LocationType = 'Site' and  IsInventoryLocation = true LIMIT 1];
        List<Schema.Location> locationList = MS_FSM_InstallAsset_Controller.getLocationName(n.Id);
        Test.stopTest();

        System.assertNotEquals(0, locationList.size(), 'Location should not be null');
    }

    @isTest
    static void testGetSerializedProducts() {
        Test.startTest();

        // Fetch the ProductItem we created in setup
        ProductItem productItem = [SELECT Id, LocationId, Product2Id FROM ProductItem LIMIT 1];
        System.debug('productItem++++: '+productItem);
        
        Schema.Location n = [SELECT Id FROM Location WHERE Name = 'InventoryLocation1' and LocationType = 'Site' and  IsInventoryLocation = true LIMIT 1];
        List<Id> serviceTerritoryLocationIds = new List<Id>();
        serviceTerritoryLocationIds.add(n.Id);

        List<SerializedProduct> serializedProducts = MS_FSM_InstallAsset_Controller.getSerializedProducts(serviceTerritoryLocationIds, productItem.Product2Id);
        System.debug('serializedProducts++++: '+serializedProducts);
        Test.stopTest();

        // Assert that serialized products were fetched correctly
        System.assertNotEquals(0, serializedProducts.size(), 'Serialized products should be returned');
        System.assertEquals('SN001', serializedProducts[0].SerialNumber, 'Serial number does not match');
    }
    
    @isTest
    static void testGetProductItemsForSTLocations() {
        Test.startTest();

        // Fetch the ProductItem we created in setup
        ProductItem productItem = [SELECT Id, LocationId, Product2Id FROM ProductItem LIMIT 1];
        
        Schema.Location n = [SELECT Id FROM Location WHERE Name = 'InventoryLocation1' and LocationType = 'Site' and  IsInventoryLocation = true LIMIT 1];
        List<Id> serviceTerritoryLocationIds = new List<Id>();
        serviceTerritoryLocationIds.add(n.Id);

        List<ProductItem> productItems = MS_FSM_InstallAsset_Controller.getProductItemsForSTLocations(serviceTerritoryLocationIds, productItem.Product2Id);
        System.debug('productItems+++: '+productItems);
        Test.stopTest();

        // Assert that serialized products were fetched correctly
        System.assertNotEquals(0, productItems.size(), 'Service Territory Product Items should be returned');
    }
       
    @isTest
    static void testgetServiceTerritory() {        
		Test.startTest();

        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Test ST' LIMIT 1];

        List<ServiceTerritoryLocation> stLocations = MS_FSM_InstallAsset_Controller.getServiceTerritory(st.Id);
        Schema.Location n = [SELECT Id FROM Location WHERE Name = 'InventoryLocation1' and LocationType = 'Site' and  IsInventoryLocation = true LIMIT 1];
        Test.stopTest();

        // Assert that serialized products were fetched correctly
        System.assertNotEquals(0, stLocations.size(), 'Service Territory Locations should be returned');
        System.assertEquals(n.Id, stLocations[0].LocationId, 'Serial number does not match');
    }
    
}