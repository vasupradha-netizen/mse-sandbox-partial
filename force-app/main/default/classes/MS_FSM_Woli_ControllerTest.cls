@isTest
public class MS_FSM_Woli_ControllerTest {
    
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

        // Create WorkOrder record
        WorkOrder wo = new WorkOrder(
            AccountId = acc.Id,
            LocationId = n.Id 
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

        // Create ProductItem record
        ProductItem productItem = new ProductItem(
            Product2Id = prod.Id,
            LocationId = n.Id, 
            QuantityOnHand = 0,
            QuantityUnitOfMeasure = 'ea'
        );
        insert productItem;

        // Create SerializedProduct record
        SerializedProduct serializedProduct = new SerializedProduct(
            ProductItemId = productItem.Id,
            Status = 'Available',
            SerialNumber = 'SN001',
            Product2Id = prod.Id
        );
        insert serializedProduct;

        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = wo.Id,
            WorkTypeId = wt.Id,
            MS_FSM_Install_Swap_Product__c = prod.Id, 
            AssetId = asset.Id
        );
        insert woli;


    }
    
    @isTest
    static void testGetCurrentWoliDetails() {
        
        // Fetch the WorkOrderLineItem we created in setup
        WorkOrderLineItem woli = [SELECT Id, LineItemNumber, WorkOrder.WorkOrderNumber, Asset.Name FROM WorkOrderLineItem LIMIT 1];

        Test.startTest();
        // Call the method and assert the correct fields are returned
        WorkOrderLineItem result = MS_FSM_Woli_Controller.getCurrentWoliDetails(woli.Id);
        Test.stopTest();

        // Assert the expected values
        System.assertNotEquals(null, result, 'The result should not be null');
        System.assertEquals(woli.LineItemNumber, result.LineItemNumber, 'Expected LineItemNumber does not match');
        System.assertNotEquals(null, result.WorkOrder.WorkOrderNumber, 'WorkOrder should be populated');
    }
    
    @isTest
    static void testGetCurrentWoliDetailsCatchError() {
        List<Account> accountList = [Select id from Account where Name = 'Test Account'];
        Boolean exceptionCaught = false;

        Test.startTest();
        try {
            // Call the method and assert the correct fields are returned
            WorkOrderLineItem result = MS_FSM_Woli_Controller.getCurrentWoliDetails(accountList[0].Id);
         } catch (Exception ex) {
            exceptionCaught = true;
        }
        Test.stopTest();

		System.assertEquals(true, exceptionCaught, 'exception was not caught');

    }
    
    @isTest
    static void testGetRelatedAssets() {
        
        // Fetch the Asset we created in setup
        Asset assetValue = [SELECT Id, Name, ParentId FROM Asset LIMIT 1];
        
        Test.startTest();
        // Call the method and assert the correct fields are returned
        List<Asset> result = MS_FSM_Woli_Controller.getRelatedAssets(assetValue.Id);
        Test.stopTest();

        // Assert the expected values
        System.assertNotEquals(null, result, 'The result should not be null');
    }
}