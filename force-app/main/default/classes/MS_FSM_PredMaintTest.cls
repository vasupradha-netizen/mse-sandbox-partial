@isTest
private class MS_FSM_PredMaintTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(
            Name = 'Test Account'
        );
        INSERT acc;

        Product2 parentProd = new Product2(
            Name 		= 'Parent Product', 
            IsActive 	= true
        );
        INSERT parentProd;

        Product2 prod = new Product2(
            Name 						= 'Test Product',
            IsActive 					= true,
            Family 						= 'PredictiveFamily',
            MS_FSM_Parent_Product__c 	= parentProd.Id
        );
        INSERT prod;

        WorkType wt = new WorkType(
            Name 				= 'Predictive Work Type',
            EstimatedDuration 	= 60,
            DurationType 		= 'Minutes',
            MS_FSM_Family__c 	= 'PredictiveFamily',
            MS_FSM_Sub_Type__c 	= 'Work Order Line Item'
        );
        INSERT wt;

        Schema.Location loc = new Schema.Location(
            Name 				= 'Test Location',
            LocationType 		= 'Site',
            IsInventoryLocation = false
        );
        INSERT loc;

        AssetTriggerHandler.skipProcessing();
        Asset rootAsset = new Asset(
            Name 			= 'Root Asset',
            AccountId 		= acc.Id,
            Product2Id 		= parentProd.Id,
            Status 			= 'Installed',
            LocationId 		= loc.Id
        );
        INSERT rootAsset;

        Asset childAsset = new Asset(
            Name 									= 'Child Asset',
            AccountId 								= acc.Id,
            Product2Id 								= prod.Id,
            ParentId 								= rootAsset.Id,
            LocationId 								= loc.Id,
            Status 									= 'Installed',
            MS_FSM_Predictive_Service_Date__c 		= System.today().addDays(3),
            MS_FSM_Predictive_Service_Lead_Time__c 	= 7
        );
        INSERT childAsset;
    }

    @isTest
    static void testExecuteByRoot() {
        Asset rootAsset = [SELECT Id FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Set<String> families = new Set<String>{ 'PredictiveFamily' };

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(rootAsset.Id, families);
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id, Subject, AssetId FROM WorkOrder];
        System.assertEquals(1, wos.size(), 'Should create one work order');
        System.assertEquals('Predictive Maintenance', wos[0].Subject);
        System.assertEquals(rootAsset.Id, wos[0].AssetId);

        List<WorkOrderLineItem> wolis = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :wos[0].Id];
        System.assert(wolis.size() >= 1, 'Should have at least one line item');

        List<ServiceAppointment> sas = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :wos[0].Id];
        System.assertEquals(1, sas.size(), 'Should create one service appointment');
    }

    @isTest
    static void testExecuteByAssetId() {
        Asset childAsset = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(childAsset.Id);
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id, Subject FROM WorkOrder];
        System.assertEquals(1, wos.size(), 'Should create one work order');
        System.assert(wos[0].Subject.contains('Predictive Maintenance'));
    }

    @isTest
    static void testExecuteByRootNoAssets() {
        Asset rootAsset = [SELECT Id FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Set<String> families = new Set<String>{ 'NonExistentFamily' };

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(rootAsset.Id, families);
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'Should not create work order when no matching assets');
    }

    @isTest
    static void testExecuteByRootNoWorkType() {
        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Set<String> families = new Set<String>{ 'FamilyWithNoWorkType' };

        Product2 prod2 = new Product2(Name = 'Other Product', IsActive = true, Family = 'FamilyWithNoWorkType');
        INSERT prod2;

        AssetTriggerHandler.skipProcessing();
        Asset child2 = new Asset(
            Name 		= 'Child 2',
            AccountId 	= rootAsset.AccountId,
            Product2Id 	= prod2.Id,
            ParentId 	= rootAsset.Id,
            Status 		= 'Installed'
        );
        INSERT child2;

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(rootAsset.Id, families);
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'Should not create work order when no WorkType matches');
    }

    @isTest
    static void testExecuteNullAssetId() {
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance((String) null);
        pm.execute();
        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size());
    }

    @isTest
    static void testExecuteEmptyFamilies() {
        Asset rootAsset = [SELECT Id FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(rootAsset.Id, new Set<String>());
        pm.execute();
        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size());
    }

    @isTest
    static void testExecuteByAssetIdObsolete() {
        Asset child = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];
        child.Status = 'Obsolete';
        UPDATE child;

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(child.Id);
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'Should not create work order for obsolete asset');
    }

    @isTest
    static void testExecuteByAssetIdNoProductFamily() {
        Product2 prodNoFamily = new Product2(Name = 'No Family Product', IsActive = true);
        INSERT prodNoFamily;
        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        AssetTriggerHandler.skipProcessing();
        Asset childNoFamily = new Asset(
            Name 			= 'Child No Family',
            AccountId 		= rootAsset.AccountId,
            Product2Id 		= prodNoFamily.Id,
            ParentId 		= rootAsset.Id,
            LocationId 		= loc.Id,
            Status 			= 'Installed'
        );
        INSERT childNoFamily;

        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(childNoFamily.Id);
        pm.execute();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'Should not create work order when asset has no Product Family');
    }

    @isTest
    static void testExecuteByAssetIdNoWorkType() {
        Product2 prodNoWt = new Product2(Name = 'No WorkType Product', IsActive = true, Family = 'FamilyNoWorkType');
        INSERT prodNoWt;
        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        AssetTriggerHandler.skipProcessing();
        Asset childNoWt = new Asset(
            Name 		= 'Child No WorkType',
            AccountId 	= rootAsset.AccountId,
            Product2Id 	= prodNoWt.Id,
            ParentId 	= rootAsset.Id,
            LocationId 	= loc.Id,
            Status 		= 'Installed'
        );
        INSERT childNoWt;

        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(childNoWt.Id);
        pm.execute();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'Should not create work order when no WorkType matches family');
    }

    @isTest
    static void testExecuteByAssetIdWithRelatedAssets() {
        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Family = 'PredictiveFamily' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        AssetTriggerHandler.skipProcessing();
        Asset child2 = new Asset(
            Name 		= 'Child Asset 2',
            AccountId	= rootAsset.AccountId,
            Product2Id 	= prod.Id,
            ParentId 	= rootAsset.Id,
            LocationId 	= loc.Id,
            Status 		= 'Installed'
        );
        INSERT child2;

        Asset child1 = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(child1.Id);
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(1, wos.size());
        List<WorkOrderLineItem> wolis = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :wos[0].Id];
        System.assertEquals(2, wolis.size(), 'Should have line items for both related assets');
    }

    @isTest
    static void testExecuteByRootWithMultipleRelatedAssets() {
        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Family = 'PredictiveFamily' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        AssetTriggerHandler.skipProcessing();
        Asset child2 = new Asset(
            Name 								= 'Child Asset 2',
            AccountId 							= rootAsset.AccountId,
            Product2Id 							= prod.Id,
            ParentId 							= rootAsset.Id,
            LocationId 							= loc.Id,
            Status 								= 'Installed',
            MS_FSM_Predictive_Service_Date__c 	= System.today().addDays(5)
        );
        INSERT child2;

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(rootAsset.Id, new Set<String>{ 'PredictiveFamily' });
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(1, wos.size());
        List<WorkOrderLineItem> wolis = [SELECT Id FROM WorkOrderLineItem WHERE WorkOrderId = :wos[0].Id];
        System.assertEquals(2, wolis.size(), 'Should have line items for anchor and related asset');
    }

    @isTest
    static void testBuildServiceApptLongDuration() {
        Product2 prodLong = new Product2(Name = 'Long Duration Product', IsActive = true, Family = 'LongDurationFamily');
        INSERT prodLong;
        WorkType wtLong = new WorkType(
            Name 				= 'Long Duration Work Type',
            EstimatedDuration 	= 600,
            DurationType 		= 'Minutes',
            MS_FSM_Family__c 	= 'LongDurationFamily',
            MS_FSM_Sub_Type__c 	= 'Work Order Line Item'
        );
        INSERT wtLong;

        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];
        AssetTriggerHandler.skipProcessing();
        Asset childLong = new Asset(
            Name 								= 'Child Long Duration',
            AccountId 							= rootAsset.AccountId,
            Product2Id 							= prodLong.Id,
            ParentId 							= rootAsset.Id,
            LocationId 							= loc.Id,
            Status 								= 'Installed',
            MS_FSM_Predictive_Service_Date__c 	= System.today().addDays(3)
        );
        INSERT childLong;

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(childLong.Id);
        pm.execute();
        Test.stopTest();

        List<ServiceAppointment> sas = [SELECT Id, Duration FROM ServiceAppointment];
        System.assertEquals(1, sas.size());
        System.assertEquals(8, sas[0].Duration, 'Duration should cap at 8 hours when total exceeds 8*60');
    }

    @isTest
    static void testExecuteByRootExcludesObsolete() {
        Asset rootAsset = [SELECT Id, AccountId FROM Asset WHERE Name = 'Root Asset' LIMIT 1];
        Product2 prod = [SELECT Id FROM Product2 WHERE Family = 'PredictiveFamily' LIMIT 1];
        Schema.Location loc = [SELECT Id FROM Location LIMIT 1];

        AssetTriggerHandler.skipProcessing();
        Asset obsoleteChild = new Asset(
            Name 								= 'Obsolete Child',
            AccountId 							= rootAsset.AccountId,
            Product2Id 							= prod.Id,
            ParentId 							= rootAsset.Id,
            LocationId 							= loc.Id,
            Status 								= 'Obsolete',
            MS_FSM_Predictive_Service_Date__c 	= System.today().addDays(2)
        );
        INSERT obsoleteChild;

        Test.startTest();
        MS_FSM_PredictiveMaintenance pm = new MS_FSM_PredictiveMaintenance(rootAsset.Id, new Set<String>{ 'PredictiveFamily' });
        pm.execute();
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(1, wos.size());
        List<WorkOrderLineItem> wolis = [SELECT Id, AssetId FROM WorkOrderLineItem WHERE WorkOrderId = :wos[0].Id];
        for (WorkOrderLineItem woli : wolis) {
            System.assertNotEquals(obsoleteChild.Id, woli.AssetId, 'Obsolete asset should not appear on work order');
        }
    }
}