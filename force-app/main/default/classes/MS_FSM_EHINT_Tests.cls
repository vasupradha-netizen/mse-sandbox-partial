@isTest
private class MS_FSM_EHINT_Tests {

    @TestSetup
    static void setup() {
        Test.loadData(MS_FSM_EtaHub_Integration_Definition__c.sObjectType, 'ehint_data');
        INSERT new MS_FSM_EtaHub_Integration_Setting__c(Minutes_Lookback__c = 15);
    }
    
    @isTest
    static void partMaster() {
        setMock('ehint_partmastertest');
        Test.startTest();
        MS_FSM_EHINT_ProductInventorySchedule j = new MS_FSM_EHINT_ProductInventorySchedule();
        j.execute(null);
        Test.stopTest();
        
        Assert.areEqual(1, [SELECT Id FROM Product2].size(), 'part masters not processed correctly');
    }
    
    @isTest
    static void partMasterError() {
        setMock('ehint_forceerror');
        Test.startTest();
        MS_FSM_EHINT_ProductInventorySchedule j = new MS_FSM_EHINT_ProductInventorySchedule();
        j.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void masterPartRecord() {
        INSERT new Product2(
        	Name = 'test',
            ProductCode = 'E0100087'
        );
        setMock('ehint_masterpartrecordtest');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_MasterPartRecord('all', 1000, 0, true, false));
        Test.stopTest();
        
        Assert.areEqual(1, [SELECT Id FROM Product2 WHERE MS_FSM_Parent_Product__r.ProductCode = 'E0100087'].size());
    }
    
    @isTest
    static void masterPartRecordError() {
        INSERT new Product2(
        	Name = 'test',
            ProductCode = 'E0100087'
        );
        setMock('ehint_forceerror');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_MasterPartRecord('all', 1000, 0, true, false));
        Test.stopTest();
    }
    
    @isTest
    static void inventoryLocation() {
        setMock('ehint_inventorylocation');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_InventoryLocation('all', true, false));
        Test.stopTest();
        
        Assert.areEqual(1, [SELECT Id FROM Location].size());
    }
    
    @isTest	
    static void inventoryLocationError() {
        setMock('ehint_forceerror');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_InventoryLocation('all', true, false));
        Test.stopTest();
    }
    
    @isTest
    static void inventory() {
        INSERT new List<Product2> {
            new Product2(
            	Name = 'test1',
                ProductCode = 'E0132042_A',
                IsSerialized = true
            ),
            new Product2(
            	Name = 'test2',
                ProductCode = 'E0129088_A',
                IsSerialized = false
            )
        };
        INSERT new List<Schema.Location> {
        	new Schema.Location(
            	Name = 'test1',
                MS_FSM_Location_Id__c = 'FS1',
                LocationType = 'Warehouse',
                IsInventoryLocation = true
            ),
            new Schema.Location(
            	Name = 'test2',
                MS_FSM_Location_Id__c = 'FS3',
                LocationType = 'Warehouse',
                IsInventoryLocation = true
            )
        };
            
        setMock('ehint_inventory');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_Inventory('all', true));
        Test.stopTest();
    }
    
    @isTest
    static void assembly() {
        Account a = new Account(
            Name = 'test'
        );
        INSERT a;
        testProduct('E0110225_42');
        setMock('ehint_assembly');
        Test.startTest();
        MS_FSM_EHINT_GetAssemblies j = new MS_FSM_EHINT_GetAssemblies();
        j.dummyAcc = a.Id;
        MS_FSM_EHINT_AssemblySchedule s = new MS_FSM_EHINT_AssemblySchedule();
        s.j = j;
        s.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void cmAssembly() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        testProduct('E0154805_02_D9');
        setMock('ehint_cmassembly');
        Test.startTest();
        MS_FSM_EHINT_GetCMAssemblies j = new MS_FSM_EHINT_GetCMAssemblies();
        j.dummyAcc = a.Id;
        MS_FSM_EHINT_CMAssemblySchedule s = new MS_FSM_EHINT_CMAssemblySchedule();
        s.j = j;
        s.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void assemblyComponent() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id
        );
        INSERT t;
        testProduct('E0116247_A');
        
        setMock('ehint_assemblycomponents');
        MS_FSM_EHINT_GetAssemblyComponents j = new MS_FSM_EHINT_GetAssemblyComponents();
        j.index = 0;
        j.newTopAssetIds = new List<String>{t.Id};
        
        Test.startTest();
        System.enqueueJob(j);
        Test.stopTest();
    }
    
    @isTest
    static void assemblyComponentError() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id
        );
        INSERT t;
        testProduct('E0116247_A');
        
        setMock('ehint_forceerror');
        MS_FSM_EHINT_GetAssemblyComponents j = new MS_FSM_EHINT_GetAssemblyComponents();
        j.index = 0;
        j.newTopAssetIds = new List<String>{t.Id};
        
        Test.startTest();
        System.enqueueJob(j);
        Test.stopTest();
    }
    
    @isTest
    static void cmAssemblyComponent() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id
        );
        INSERT t;
        testProduct('E0131408_C');
        
        setMock('ehint_cmassemblycomponents');
        MS_FSM_EHINT_GetCMAssemblyComponents j = new MS_FSM_EHINT_GetCMAssemblyComponents();
        j.index = 0;
        j.newTopAssetIds = new List<String>{t.Id};
        
        Test.startTest();
        System.enqueueJob(j);
        Test.stopTest();
    }
    
    @isTest
    static void cmAssemblyComponentError() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id
        );
        INSERT t;
        testProduct('E0131408_C');
        
        setMock('ehint_forceerror');
        MS_FSM_EHINT_GetCMAssemblyComponents j = new MS_FSM_EHINT_GetCMAssemblyComponents();
        j.index = 0;
        j.newTopAssetIds = new List<String>{t.Id};
        
        Test.startTest();
        System.enqueueJob(j);
        Test.stopTest();
    }
    
    @isTest
    static void assemblyWriteback() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name 					   = 'test',
            AccountId 				   = a.Id,
            MS_FSM_EtaHub_Record_Id__c = '1'
        );
        INSERT t;
        setMock('ehint_cmassemblycomponents');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_AssemblyWriteback(new List<String>{t.Id}, 't1', '515', false));
        Test.stopTest();
    }
    
    @isTest
    static void inventoryWriteback() {
        setMock('ehint_cmassemblycomponents');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_InventoryWriteback(new Set<String>{'1'}));
        Test.stopTest();
    }
    
    @isTest
    static void inventoryWritebackError() {
        setMock('ehint_forceerror');
        MS_FSM_EHINT_InventoryWriteback j = new MS_FSM_EHINT_InventoryWriteback(new Set<String>{'1'});
        j.forceError = true;
        Test.startTest();
        j.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void woWriteback() {
        setMock('ehint_cmassemblycomponents');
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_StagingWorkOrderWriteback('1', '2', '3'));
        Test.stopTest();
    }
    
    @isTest
    static void woWritebackError() {
        setMock('ehint_forceerror');
        MS_FSM_EHINT_StagingWorkOrderWriteback j = new MS_FSM_EHINT_StagingWorkOrderWriteback('1', '2', '3');
        j.forceError = true;
        Test.startTest();
        j.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void parenting() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset r = new Asset(
        	Name = 'root',
            AccountId = a.Id,
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub',
            SerialNumber = 'R'
        );
        INSERT r;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id,
            SerialNumber = '1234',
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub',
            MS_FSM_Serial_Chain__c = 'R',
            ParentId = r.Id
        );
        INSERT t;
        INSERT new Asset(
        	Name = 'test2',
            AccountId = a.Id,
            MS_FSM_Parent_Serial_Number__c = '1234',
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub'
        );
        
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_ParentingQueue(new List<String>{t.Id}, 0, null));
        Test.stopTest();
        
        Asset result = [SELECT ParentId, MS_FSM_Serial_Chain__c, MS_FSM_L2_Asset__c FROM Asset WHERE Name = 'test2'];
        
        Assert.areEqual(result.ParentId, 				t.Id, 		'EHINT PARENTING - parent not assigned correctly');
        Assert.areEqual(result.MS_FSM_Serial_Chain__c, 'R, 1234', 	'EHINT PARENTING - chain not set correctly');
        Assert.areEqual(result.MS_FSM_L2_Asset__c, 		t.Id, 		'EHINT PARENTING - l2 asset not assigned correctly');
    }
    
    /*
    @isTest
    static void stagingParenting() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset r = new Asset(
        	Name = 'root',
            AccountId = a.Id,
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub',
            SerialNumber = 'R'
        );
        INSERT r;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id,
            SerialNumber = '1234',
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub',
            MS_FSM_Serial_Chain__c = 'R',
            ParentId = r.Id
        );
        INSERT t;
        INSERT new Asset(
        	Name = 'test2',
            AccountId = a.Id,
            MS_FSM_Parent_Serial_Number__c = '1234',
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub'
        );
        
        Test.startTest();
        MS_FSM_EHINT_AssetStagingParentingSched j = new MS_FSM_EHINT_AssetStagingParentingSched();
        j.execute(null);
        Test.stopTest();
    }
	*/    

    @isTest
    static void createLogs() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name = 'test',
            AccountId = a.Id,
            SerialNumber = '1234',
            MS_FSM_LGen_SN_Short_Form__c = 'test',
            MS_FSM_Method_of_Creation__c = 'EtaHub',
            MS_FSM_Create_ATL__c = true
        );
        INSERT t;
        Test.startTest();
        Database.executeBatch(new MS_FSM_EHINT_CreateLogsBatch());
        Test.stopTest();
    }
    
    @isTest
    static void workOrderStart() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Schema.Location l = new Schema.Location(
        	Name = 'CA-Lathrop-1',
            MS_FSM_Account__c = a.Id,
            LocationType = 'Site'
        );
        INSERT l;
        
        Product2 parent = new Product2(
        	Name 					= 'test parent',
            IsActive 				= true,
            MS_FSM_Product_Type__c 	= 'Asset'
        );
        INSERT parent;
        
        INSERT new Product2(
            Name 						= 'test', 
            ProductCode 				= 'EC1727 | Train 6 ; Train 7 ; Train 8 ; Train 9 | Core A or Core B_1', 
            MS_FSM_Product_Type__c 		= 'Asset', 
            IsActive 					= true, 
            MS_FSM_Parent_Product__c 	= parent.Id);
        
        List<Asset> ts = new List<Asset>();
        ts.add(new Asset(Name = 'test', AccountId = a.Id, SerialNumber = 'MP000033', LocationId = l.Id));
        ts.add(new Asset(Name = 'test2', AccountId = a.Id, SerialNumber = 'M000064'));
        INSERT ts;
        
        INSERT new WorkType(Name = 'Standard', MS_FSM_Work_Group__c = 'Removal', EstimatedDuration = 90, DurationType = 'Minutes');
        
        setMock('ehint_workorder');
        Test.startTest();
        INSERT new MS_FSM_EtaHub_Work_Order_Staging__c(Name = '1');
        Test.stopTest();
    }
    
    @isTest
    static void workOrderStartError() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Schema.Location l = new Schema.Location(
        	Name = 'CA-Lathrop-1',
            MS_FSM_Account__c = a.Id,
            LocationType = 'Site'
        );
        INSERT l;
        
        Product2 parent = new Product2(
        	Name 					= 'test parent',
            IsActive 				= true,
            MS_FSM_Product_Type__c 	= 'Asset'
        );
        INSERT parent;
        
        INSERT new Product2(
            Name 						= 'test', 
            ProductCode 				= 'EC1727 | Train 6 ; Train 7 ; Train 8 ; Train 9 | Core A or Core B_1', 
            MS_FSM_Product_Type__c 		= 'Asset', 
            IsActive 					= true, 
            MS_FSM_Parent_Product__c 	= parent.Id);
        
        List<Asset> ts = new List<Asset>();
        ts.add(new Asset(Name = 'test', AccountId = a.Id, SerialNumber = 'MP000033', LocationId = l.Id));
        ts.add(new Asset(Name = 'test2', AccountId = a.Id, SerialNumber = 'M000064'));
        INSERT ts;
        
        INSERT new WorkType(Name = 'Standard', MS_FSM_Work_Group__c = 'Removal', EstimatedDuration = 90, DurationType = 'Minutes');
        
        setMock('ehint_forceerror');
        Test.startTest();
        INSERT new MS_FSM_EtaHub_Work_Order_Staging__c(Name = '1');
        Test.stopTest();
    }
    
    @isTest
    static void workOrderSteps() {
        Account a = new Account(Name = 'test');
        INSERT a;
        WorkOrder wo = new WorkOrder(Subject = 'test', AccountId = a.Id);
        INSERT wo;
        WorkOrderLineItem woli = new WorkOrderLineItem(Subject = 'test', WorkOrderId = wo.Id);
        INSERT woli;
        INSERT new WorkPlan(ParentRecordId = woli.Id, Name = 'Test');
        
        setMock('ehint_workorderstep');
        Test.startTest();
        MS_FSM_EHINT_StagingWorkOrderStepsSched s = new MS_FSM_EHINT_StagingWorkOrderStepsSched('1', woli.Id, wo.Id);
        s.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void workOrderStepsError() {
        Account a = new Account(Name = 'test');
        INSERT a;
        WorkOrder wo = new WorkOrder(Subject = 'test', AccountId = a.Id);
        INSERT wo;
        WorkOrderLineItem woli = new WorkOrderLineItem(Subject = 'test', WorkOrderId = wo.Id);
        INSERT woli;
        INSERT new WorkPlan(ParentRecordId = woli.Id, Name = 'Test');
        
        setMock('ehint_forceerror');
        Test.startTest();
        MS_FSM_EHINT_StagingWorkOrderStepsSched s = new MS_FSM_EHINT_StagingWorkOrderStepsSched('1', woli.Id, wo.Id);
        s.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void workOrderSA() {
        Account a = new Account(Name = 'test');
        INSERT a;
        WorkOrder wo = new WorkOrder(Subject = 'test', AccountId = a.Id, Staging_Work_Order_Date__c = System.today());
        INSERT wo;
        WorkOrderLineItem woli = new WorkOrderLineItem(Subject = 'test', WorkOrderId = wo.Id, DurationType = 'hours', Duration = 1);
        INSERT woli;
        INSERT new WorkPlan(ParentRecordId = woli.Id, Name = 'Test');
        
        Test.startTest();
        System.enqueueJob(new MS_FSM_EHINT_StagingWorkOrderServiceAppt('1', wo.Id, woli.Id));
        Test.stopTest();
    }
    
    @isTest
    static void workOrderExisting() {
        Account a = new Account(Name = 'test');
        INSERT a;
        WorkOrder wo = new WorkOrder(
            Subject 					= 'test', 
            AccountId 					= a.Id, 
            Staging_Work_Order_Date__c 	= System.today()
        );
        INSERT wo;
        WorkOrderLineItem woli = new WorkOrderLineItem(
            Subject 			= 'test', 
            WorkOrderId 		= wo.Id, 
            DurationType 		= 'hours', 
            Duration 			= 1,
            MS_FSM_EtaHub_Id__c = '665'
        );
        INSERT woli;
        
        setMock('ehint_workorder');
        Test.startTest();
        INSERT new MS_FSM_EtaHub_Work_Order_Staging__c(Name = '665');
        Test.stopTest();
    }
    
    static void testProduct(String s) {
        INSERT new Product2(Name = 'test', ProductCode = s);
    }
    
    static void setMock(String s) {
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource(s);
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, mock);
    }
	
    /*
    @isTest
    static void assetStaging_createsNewAssetAndTransactionLog() {
        Product2 prod1 = new Product2(Name = 'Test1', ProductCode = '1111111');
		Product2 prod2 = new Product2(Name = 'Test2', ProductCode = '2222222');
		insert new List<Product2>{ prod1, prod2 };
            
        DateTime dateVar = System.now();
        
        Asset preExistingAsset = new Asset(
        	Name         = 'preExistingAsset',
            Status       = 'Installed',
            SerialNumber = 'childC',
            MS_FSM_Parent_Serial_Number__c = 'Parent1764817',
            Product2Id   = prod1.Id,
            MS_FSM_Asset_Placement__c = 'EXH',
            Quantity             = 1,
            MS_FSM_Install_Date_Time__c = dateVar
        );
        insert preExistingAsset;
        
        MS_FSM_EtaHub_Asset_Staging__c rootStaging = new MS_FSM_EtaHub_Asset_Staging__c(
        	MS_FSM_Part_Number__c          = '1111111',
        	MS_FSM_Status__c               = 'Installed',
        	MS_FSM_Timestamp__c            = System.now(),
        	MS_FSM_Parent_Serial_Number__c = '',
        	MS_FSM_EtaHub_Record_Id__c     = '54321',    
        	MS_FSM_EtaHub_Table_Id__c      = '12345',
        	MS_FSM_Quantity__c             = 1,
        	MS_FSM_Asset_Placement__c      = 'EXH',
        	MS_FSM_Asset_Serial_Number__c  = 'Parent1764817',
       	 	MS_FSM_Description__c          = 'description'
    	); 

    	MS_FSM_EtaHub_Asset_Staging__c childStaging = new MS_FSM_EtaHub_Asset_Staging__c(
        	MS_FSM_Part_Number__c          = '2222222',
        	MS_FSM_Status__c               = 'Installed',
        	MS_FSM_Timestamp__c            = System.now(),
        	MS_FSM_Parent_Serial_Number__c = 'Parent1764817',
        	MS_FSM_EtaHub_Record_Id__c     = '65432',    
        	MS_FSM_EtaHub_Table_Id__c      = '234565',
        	MS_FSM_Quantity__c             = 1,
        	MS_FSM_Asset_Placement__c      = 'EXH',
        	MS_FSM_Asset_Serial_Number__c  = 'childA',
        	MS_FSM_Description__c          = 'description'
    	);

    	MS_FSM_EtaHub_Asset_Staging__c noProduct = new MS_FSM_EtaHub_Asset_Staging__c(
       	 	MS_FSM_Part_Number__c          = 'X-INVALID-X',
       		MS_FSM_Status__c               = 'Obsolete',
        	MS_FSM_Timestamp__c            = System.now(),
        	MS_FSM_Parent_Serial_Number__c = 'Parent1764817',
        	MS_FSM_EtaHub_Record_Id__c     = '99999',    
        	MS_FSM_EtaHub_Table_Id__c      = '99999',
        	MS_FSM_Quantity__c             = 1,
        	MS_FSM_Asset_Placement__c      = 'EXH',
        	MS_FSM_Asset_Serial_Number__c  = 'childB',
        	MS_FSM_Description__c          = 'description'
    	);

    	MS_FSM_EtaHub_Asset_Staging__c existingAsset = new MS_FSM_EtaHub_Asset_Staging__c(
        	MS_FSM_Asset_Id__c             = preExistingAsset.Id,
        	MS_FSM_Part_Number__c          = '1111111',
        	MS_FSM_Status__c               = 'Obsolete',
        	MS_FSM_Timestamp__c            = System.now(),
        	MS_FSM_Parent_Serial_Number__c = 'Parent1764817',
        	MS_FSM_EtaHub_Record_Id__c     = '88888',    
        	MS_FSM_EtaHub_Table_Id__c      = '88888',
        	MS_FSM_Quantity__c             = 1,
        	MS_FSM_Asset_Placement__c      = 'EXH',
        	MS_FSM_Asset_Serial_Number__c  = 'childC',
        	MS_FSM_Description__c          = 'description'
    	);
        
        MS_FSM_EtaHub_Asset_Staging__c existingUnchangedAsset = new MS_FSM_EtaHub_Asset_Staging__c(
        	MS_FSM_Asset_Id__c             = preExistingAsset.Id,
        	MS_FSM_Part_Number__c          = '1111111',
        	MS_FSM_Status__c               = 'Installed',
        	MS_FSM_Timestamp__c            = dateVar,
        	MS_FSM_Parent_Serial_Number__c = 'Parent1764817',
        	MS_FSM_EtaHub_Record_Id__c     = '88888',    
        	MS_FSM_EtaHub_Table_Id__c      = '88888',
        	MS_FSM_Quantity__c             = 1,
        	MS_FSM_Asset_Placement__c      = 'EXH',
        	MS_FSM_Asset_Serial_Number__c  = 'childC',
        	MS_FSM_Description__c          = 'description'
    	);

    	Test.startTest();
    	insert new List<MS_FSM_EtaHub_Asset_Staging__c>{ rootStaging, childStaging, noProduct, existingAsset, existingUnchangedAsset };
    	Test.stopTest();
        
    	Asset updated = [
            SELECT Status, Name, MS_FSM_EtaHub_Record_Id__c, MS_FSM_EtaHub_Table_Id__c
            FROM Asset
            WHERE Id = :preExistingAsset.Id];
    	System.assertEquals('Obsolete', updated.Status, 'Status should be updated to Obsolete');
    	System.assertEquals('childC | 1111111 - description', updated.Name, 'Name should match formatting');
    	System.assertEquals('88888', updated.MS_FSM_EtaHub_Record_Id__c, 'EtaHub Record Id should be updated');
    	System.assertEquals('88888', updated.MS_FSM_EtaHub_Table_Id__c, 'EtaHub Table Id should be updated');

   	 	List<Asset> assets = [
            	SELECT SerialNumber, Product2Id, Status
        		FROM Asset
        		WHERE SerialNumber IN ('Parent1764817', 'childA', 'childC')
    	];
    	System.assertEquals(3, assets.size(), 'Should have 3 assets in total');

    	List<MS_FSM_Asset_Transaction_Log__c> logs = [
            SELECT MS_FSM_Asset_Serial_Number__c
        	FROM MS_FSM_Asset_Transaction_Log__c
       	 	WHERE MS_FSM_Asset_Serial_Number__c IN ('Parent1764817', 'childA', 'childC')
    	];
    	System.assertEquals(3, logs.size(), 'Should create 3 transaction logs');

    	List<MS_FSM_EtaHub_Asset_Staging__c> processed = [
        	SELECT MS_FSM_Stage__c
        	FROM MS_FSM_EtaHub_Asset_Staging__c
        	WHERE Id IN :new List<Id>{ rootStaging.Id, childStaging.Id, existingAsset.Id }
    	];
    	for (MS_FSM_EtaHub_Asset_Staging__c s : processed) {
        	System.assertEquals('Processed', s.MS_FSM_Stage__c);
    	}

    	MS_FSM_EtaHub_Asset_Staging__c errored = [
        	SELECT MS_FSM_Stage__c, MS_FSM_Error_Message__c
       	 	FROM MS_FSM_EtaHub_Asset_Staging__c
        	WHERE Id = :noProduct.Id
    	];
    	System.assertEquals('Error', errored.MS_FSM_Stage__c);
    	System.assertNotEquals(null, errored.MS_FSM_Error_Message__c);
   }
	*/
}