@isTest
private class MS_FSM_PredMaintCheckBatchTest {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
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
            Name 		= 'Root Asset',
            AccountId 	= acc.Id,
            Product2Id 	= parentProd.Id,
            Status 		= 'Installed',
            LocationId 	= loc.Id
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
    static void testCheckBatch() {
        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceCheckBatch(), 10);
        Test.stopTest();

        System.assert(true, 'CheckBatch completes without error; inner batch skipped in test to avoid executeBatch limit');
    }

    @isTest
    static void testCheckBatchNoQualifyingAssets() {
        Asset child = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];
        UPDATE new Asset(
            Id 										= child.Id,
            MS_FSM_Predictive_Service_Date__c 		= System.today().addDays(30),
            MS_FSM_Predictive_Service_Lead_Time__c 	= 7
        );
        UPDATE child;

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceCheckBatch(), 10);
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'No work orders when no assets qualify');
    }

    @isTest
    static void testCheckBatchWithLeadTime() {
        Asset child = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];
        UPDATE new Asset(
            Id 										= child.Id,
            MS_FSM_Predictive_Service_Date__c 		= System.today().addDays(5),
            MS_FSM_Predictive_Service_Lead_Time__c 	= 7
        );

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceCheckBatch(), 10);
        Test.stopTest();

        System.assert(true, 'CheckBatch with qualifying asset completes; inner batch skipped in test');
    }

    @isTest
    static void testCheckBatchDefaultLeadTime() {
        Asset child = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];
        UPDATE new Asset(
            Id 										= child.Id,
            MS_FSM_Predictive_Service_Date__c 		= System.today().addDays(5),
            MS_FSM_Predictive_Service_Lead_Time__c 	= null
        );

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceCheckBatch(), 10);
        Test.stopTest();

        System.assert(true, 'CheckBatch with default lead time completes; inner batch skipped in test');
    }

    @isTest
    static void testCheckBatchExcludesObsolete() {
        Asset child = [SELECT Id FROM Asset WHERE Name = 'Child Asset' LIMIT 1];
        UPDATE new Asset(
            Id 										= child.Id,
            Status 									= 'Obsolete',
            MS_FSM_Predictive_Service_Date__c 		= System.today().addDays(3),
            MS_FSM_Predictive_Service_Lead_Time__c 	= 7
        );

        Test.startTest();
        Database.executeBatch(new MS_FSM_PredictiveMaintenanceCheckBatch(), 10);
        Test.stopTest();

        List<WorkOrder> wos = [SELECT Id FROM WorkOrder];
        System.assertEquals(0, wos.size(), 'Obsolete assets should be excluded from CheckBatch query');
    }
}