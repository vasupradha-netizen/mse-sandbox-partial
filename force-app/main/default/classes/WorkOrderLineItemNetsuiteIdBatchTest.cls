@isTest
private class WorkOrderLineItemNetsuiteIdBatchTest {
    
    @isTest
    static void testBatchUpdateOnInstall() {

        Product2 testProd = new Product2(Name = 'Test Product', MS_FSM_NetsuiteId__c = 'NS-12345', IsActive = true);
        insert testProd;
        
        Asset testAsset = new Asset(Name = 'Test Asset', Product2Id = testProd.Id);
        insert testAsset;
        
        WorkOrder testWO = new WorkOrder(Subject = 'Test WO');
        insert testWO;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = testWO.Id,
            MS_FSM_Installed_Asset__c = testAsset.Id,
            MS_FSM_Installed_Asset_Netsuite_Id__c = '' 
        );
        insert woli;

        Test.startTest();
        WorkOrderLineItemNetsuiteBatch batch = new WorkOrderLineItemNetsuiteBatch();
        Database.executeBatch(batch);
        Test.stopTest(); 
        
        WorkOrderLineItem updatedWoli = [SELECT MS_FSM_Installed_Asset_Netsuite_Id__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id = :woli.Id];
        
        System.assertEquals('NS-12345', updatedWoli.MS_FSM_Installed_Asset_Netsuite_Id__c, 'The Netsuite ID should have been copied from the Installed Asset.');
    }
    
    @isTest
    static void testBatchUpdateOnReplace() {

        Product2 testProd = new Product2(Name = 'Test Product', MS_FSM_NetsuiteId__c = 'NS-12345', IsActive = true);
        insert testProd;
        
        Asset testAsset = new Asset(Name = 'Test Asset', Product2Id = testProd.Id);
        insert testAsset;
        
        WorkOrder testWO = new WorkOrder(Subject = 'Test WO');
        insert testWO;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = testWO.Id,
            MS_FSM_Removed_Asset__c = testAsset.Id,
            MS_FSM_Removed_Asset_Netsuite_Id__c = '' 
        );
        insert woli;

        Test.startTest();
        WorkOrderLineItemNetsuiteBatch batch = new WorkOrderLineItemNetsuiteBatch();
        Database.executeBatch(batch);
        Test.stopTest(); 
        
        WorkOrderLineItem updatedWoli = [SELECT MS_FSM_Removed_Asset_Netsuite_Id__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id = :woli.Id];
        
        System.assertEquals('NS-12345', updatedWoli.MS_FSM_Removed_Asset_Netsuite_Id__c, 'The Netsuite ID should have been copied from the Removed Asset.');
    }
    @isTest
    static void testBatchUpdateNewInstallNetsuiteId() {

        Product2 testProd = new Product2(Name = 'Test Product', MS_FSM_NetsuiteId__c = 'NS-12345', IsActive = true);
        insert testProd;
        
        Asset testAsset = new Asset(Name = 'Test Asset', Product2Id = testProd.Id);
        insert testAsset;
        
        WorkOrder testWO = new WorkOrder(Subject = 'Test WO');
        insert testWO;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = testWO.Id,
            MS_FSM_Installed_Asset__c = testAsset.Id,
            MS_FSM_Installed_Asset_Netsuite_Id__c = '12345' 
        );
        insert woli;

        Test.startTest();
        WorkOrderLineItemNetsuiteBatch batch = new WorkOrderLineItemNetsuiteBatch();
        Database.executeBatch(batch);
        Test.stopTest(); 
        
        WorkOrderLineItem updatedWoli = [SELECT MS_FSM_Installed_Asset_Netsuite_Id__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id = :woli.Id];
        
        System.assertEquals('NS-12345', updatedWoli.MS_FSM_Installed_Asset_Netsuite_Id__c, 'The Netsuite ID should have been updated with the new NS Id on the Installed Asset.');
    }
    
    @isTest
    static void testBatchUpdateNewReplaceNetsuiteId() {

        Product2 testProd = new Product2(Name = 'Test Product', MS_FSM_NetsuiteId__c = 'NS-12345', IsActive = true);
        insert testProd;
        
        Asset testAsset = new Asset(Name = 'Test Asset', Product2Id = testProd.Id);
        insert testAsset;
        
        WorkOrder testWO = new WorkOrder(Subject = 'Test WO');
        insert testWO;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = testWO.Id,
            MS_FSM_Removed_Asset__c = testAsset.Id,
            MS_FSM_Removed_Asset_Netsuite_Id__c = '12345' 
        );
        insert woli;

        Test.startTest();
        WorkOrderLineItemNetsuiteBatch batch = new WorkOrderLineItemNetsuiteBatch();
        Database.executeBatch(batch);
        Test.stopTest(); 
        
        WorkOrderLineItem updatedWoli = [SELECT MS_FSM_Removed_Asset_Netsuite_Id__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id = :woli.Id];
        
        System.assertEquals('NS-12345', updatedWoli.MS_FSM_Removed_Asset_Netsuite_Id__c, 'The Netsuite ID should have been updated with the new NS Id on the Removed Asset.');
    }
    @isTest
    static void testBatchUpdateDeletedInstallNetsuiteId() {

        Product2 testProd = new Product2(Name = 'Test Product', MS_FSM_NetsuiteId__c = '', IsActive = true);
        insert testProd;
        
        Asset testAsset = new Asset(Name = 'Test Asset', Product2Id = testProd.Id);
        insert testAsset;
        
        WorkOrder testWO = new WorkOrder(Subject = 'Test WO');
        insert testWO;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = testWO.Id,
            MS_FSM_Installed_Asset__c = testAsset.Id,
            MS_FSM_Installed_Asset_Netsuite_Id__c = '12345' 
        );
        insert woli;

        Test.startTest();
        WorkOrderLineItemNetsuiteBatch batch = new WorkOrderLineItemNetsuiteBatch();
        Database.executeBatch(batch);
        Test.stopTest(); 
        
        WorkOrderLineItem updatedWoli = [SELECT MS_FSM_Installed_Asset_Netsuite_Id__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id = :woli.Id];
        
        System.assertEquals(null, updatedWoli.MS_FSM_Installed_Asset_Netsuite_Id__c, 'The Netsuite ID value should have been deleted on the Installed Asset.');
    }
    
    @isTest
    static void testBatchUpdateDeletedReplaceNetsuiteId() {

        Product2 testProd = new Product2(Name = 'Test Product', MS_FSM_NetsuiteId__c = '', IsActive = true);
        insert testProd;
        
        Asset testAsset = new Asset(Name = 'Test Asset', Product2Id = testProd.Id);
        insert testAsset;
        
        WorkOrder testWO = new WorkOrder(Subject = 'Test WO');
        insert testWO;
        
        WorkOrderLineItem woli = new WorkOrderLineItem(
            WorkOrderId = testWO.Id,
            MS_FSM_Removed_Asset__c = testAsset.Id,
            MS_FSM_Removed_Asset_Netsuite_Id__c = '12345' 
        );
        insert woli;

        Test.startTest();
        WorkOrderLineItemNetsuiteBatch batch = new WorkOrderLineItemNetsuiteBatch();
        Database.executeBatch(batch);
        Test.stopTest(); 
        
        WorkOrderLineItem updatedWoli = [SELECT MS_FSM_Removed_Asset_Netsuite_Id__c 
                                       FROM WorkOrderLineItem 
                                       WHERE Id = :woli.Id];
        
        System.assertEquals(null, updatedWoli.MS_FSM_Removed_Asset_Netsuite_Id__c, 'The Netsuite ID value should have been deleted on Removed Asset.');
    }
}