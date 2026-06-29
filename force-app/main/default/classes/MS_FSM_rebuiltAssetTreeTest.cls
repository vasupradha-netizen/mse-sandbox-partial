@isTest
private class MS_FSM_rebuiltAssetTreeTest {

    @isTest
    static void std() {
        Test.loadData(MS_FSM_EtaHub_Integration_Definition__c.sObjectType, 'ehint_data');
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name 							= 'test',
            AccountId 						= a.Id,
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            SerialNumber 					= '1234'
        );
        INSERT t;
		Asset c = new Asset(
        	Name 							= 'child',
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            ParentId 						= t.Id
        );
        INSERT c;
        testProduct('E0116247_A');
        
        setMock('ehint_assemblycomponents');
        Test.startTest();
        MS_FSM_rebuiltAssetTree.initialChecks('');
        MS_FSM_rebuiltAssetTree.initialChecks('123');
        MS_FSM_rebuiltAssetTree.initialChecks(c.Id);
        MS_FSM_rebuiltAssetTree.initialChecks(t.Id);
        MS_FSM_rebuiltAssetTree.rebuildTree(t.Id);
        Test.stopTest();
    }
    
    @isTest
    static void lowerLevel() {
        Test.loadData(MS_FSM_EtaHub_Integration_Definition__c.sObjectType, 'ehint_data');
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        Asset t = new Asset(
        	Name 							= 'test',
            AccountId 						= a.Id,
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            SerialNumber 					= '1234'
        );
        INSERT t;
		Asset c = new Asset(
        	Name 							= 'child',
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            ParentId 						= t.Id
        );
        INSERT c;
        testProduct('E0116247_A');
        
        setMock('ehint_assemblycomponents');
        Test.startTest();
        MS_FSM_rebuiltAssetTree.initialChecks('');
        MS_FSM_rebuiltAssetTree.initialChecks('123');
        MS_FSM_rebuiltAssetTree.initialChecks(c.Id);
        MS_FSM_rebuiltAssetTree.initialChecks(t.Id);
        MS_FSM_rebuiltAssetTree.rebuildTree(c.Id);
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
}