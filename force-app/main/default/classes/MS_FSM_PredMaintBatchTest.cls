@isTest
private class MS_FSM_PredMaintBatchTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        INSERT acc;

        Product2 parentProd = new Product2(Name = 'Parent Product', IsActive = true);
        INSERT parentProd;

        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            Family = 'PredictiveFamily',
            MS_FSM_Parent_Product__c = parentProd.Id
        );
        INSERT prod;

        WorkType wt = new WorkType(
            Name = 'Predictive Work Type',
            EstimatedDuration = 60,
            DurationType = 'Minutes',
            MS_FSM_Family__c = 'PredictiveFamily',
            MS_FSM_Sub_Type__c = 'Work Order Line Item'
        );
        INSERT wt;

        Schema.Location loc = new Schema.Location(
            Name = 'Test Location',
            LocationType = 'Site',
            IsInventoryLocation = false
        );
        INSERT loc;

        AssetTriggerHandler.skipProcessing();
        Asset rootAsset = new Asset(
            Name = 'Root Asset',
            AccountId = acc.Id,
            Product2Id = parentProd.Id,
            Status = 'Installed',
            LocationId = loc.Id
        );
        INSERT rootAsset;

        Asset childAsset = new Asset(
            Name = 'Child Asset',
            AccountId = acc.Id,
            Product2Id = prod.Id,
            ParentId = rootAsset.Id,
            LocationId = loc.Id,
            Status = 'Installed',
            MS_FSM_Predictive_Service_Date__c = System.today().addDays(3),
            MS_FSM_Predictive_Service_Lead_Time__c = 7
        );
        INSERT childAsset;
    }

    @isTest
    static void testBatch() {
        Asset rootAsset = [SELECT Id FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Set<String> families = new Set<String>{ 'PredictiveFamily' };
        List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies> scope = new List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies>{
            new MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies(rootAsset.Id, families)
        };

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceBatch(scope), 1);
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id, Subject FROM WorkOrder];
        System.assertEquals(1, wos.size(), 'Should create one work order');
        System.assertEquals('Predictive Maintenance', wos[0].Subject);
    }

    @isTest
    static void testBatchEmptyScope() {
        List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies> scope = new List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies>();

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceBatch(scope), 1);
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size());
    }

    @isTest
    static void testBatchMultipleRoots() {
        Asset root1 = [SELECT Id FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Account acc2 = new Account(Name = 'Test Account 2');
        INSERT acc2;
        Product2 parent = [SELECT Id FROM Product2 WHERE Name = 'Parent Product' LIMIT 1];
        Product2 child = [SELECT Id FROM Product2 WHERE Name = 'Test Product' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        AssetTriggerHandler.skipProcessing();
        Asset root2 = new Asset(
            Name = 'Root Asset 2',
            AccountId = acc2.Id,
            Product2Id = parent.Id,
            Status = 'Installed',
            LocationId = loc.Id
        );
        INSERT root2;

        Asset child2 = new Asset(
            Name = 'Child Asset 2',
            AccountId = acc2.Id,
            Product2Id = child.Id,
            ParentId = root2.Id,
            LocationId = loc.Id,
            Status = 'Installed',
            MS_FSM_Predictive_Service_Date__c = System.today().addDays(3)
        );
        INSERT child2;

        List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies> scope = new List<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies>{
            new MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies(root1.Id, new Set<String>{ 'PredictiveFamily' }),
            new MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies(root2.Id, new Set<String>{ 'PredictiveFamily' })
        };

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceBatch(scope), 2);
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(2, wos.size(), 'Should create two work orders');
    }
}