@isTest
private class MS_FSM_ConsumeProductsControllerTest {

    @isTest
    static void std() {
        createTestData();
        String woliid = [SELECT Id FROM WorkOrderLineItem LIMIT 1].Id;
        WorkOrderLineItem woli = MS_FSM_ConsumeProductsController.getWorkOrderLine(woliid);
        List<ProductRequired> reqs = MS_FSM_ConsumeProductsController.getProductRequired(woliid);
        
        List<String> reqIds = new List<String>();
        for (ProductRequired r : reqs) {
            reqIds.add(r.Product2Id);
        }
        
        MS_FSM_ConsumeProductsController.getProductItems(reqIds, woli.WorkOrder.MS_FSM_Inventory_Location__c);
    }
    
    static void createTestData() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        
        List<Product2> prods = new List<Product2>();
        Product2 ap = new Product2(
        	Name = 'test',
            MS_FSM_Product_Type__c = 'Asset',
            IsActive = true
        );
        prods.add(ap);
        Product2 pp = new Product2(
        	Name = 'test',
            MS_FSM_Product_Type__c = 'Part',
            IsActive = true
        );
        prods.add(pp);
        INSERT prods;
        
        Asset t = new Asset(
        	Name = 'test',
            Product2Id = ap.Id
        );
        INSERT t;
        
        Schema.Location inv = new Schema.Location(
        	Name = 'test',
            LocationType = 'Warehouse',
            IsInventoryLocation = true
        );
        INSERT inv;
        
        WorkOrder wo = new WorkOrder(
        	Subject = 'test',
            AccountId = a.Id,
            MS_FSM_Inventory_Location__c = inv.Id
        );
        INSERT wo;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
        	Subject = 'test',
            WorkOrderId = wo.Id
        );
        INSERT woli;
        
        INSERT new ProductRequired(
        	ParentRecordId = woli.Id,
            Product2Id = pp.Id,
            QuantityRequired = 1
        );
        
        INSERT new ProductItem(
        	LocationId = inv.Id,
            Product2Id = pp.Id,
            QuantityOnHand = 100
        );
    }
}