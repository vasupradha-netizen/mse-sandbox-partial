// test coverage -- see MS_FSM_SnChainRebuildSched for full description
@isTest
private class MS_FSM_SnChainRebuildTests {

    @TestSetup
    static void setup() {
        Account a = new Account(
        	Name = 'test'
        );
        INSERT a;
        AssetTriggerHandler.skipProcessing();
        Asset r = new Asset(
        	Name 							= 'root',
            AccountId 						= a.Id,
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            MS_FSM_Method_of_Creation__c	= 'EtaHub',
            SerialNumber 					= 'R',
            Status							= 'Installed'
        );
        INSERT r;
        Asset t = new Asset(
        	Name 							= 'test',
            AccountId 						= a.Id,
            SerialNumber 					= '1234',
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            MS_FSM_Method_of_Creation__c 	= 'EtaHub',
            MS_FSM_Serial_Chain__c 			= 'R',
            ParentId 						= r.Id,
            Status							= 'Installed'
        );
        INSERT t;
        INSERT new Asset(
        	Name = 'test2',
            AccountId = a.Id,
            MS_FSM_Parent_Serial_Number__c 	= '1234',
            MS_FSM_LGen_SN_Short_Form__c 	= 'test',
            MS_FSM_Method_of_Creation__c 	= 'EtaHub',
            ParentId						= t.Id,
            Status							= 'Installed'
        );
    }
    
    @isTest
    static void firststep() {
        Test.startTest();
        MS_FSM_SnChainRebuildSched j = new MS_FSM_SnChainRebuildSched();
        j.execute(null);
        Test.stopTest();
    }
    
    @isTest
    static void secondStepLevelOne() {
        Asset a = [SELECT Id FROM Asset WHERE Name = 'root' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new MS_FSM_SnChainRebuildQueue(0, new List<String>{a.Id}, null));
        Test.stopTest();
    }
    
    @isTest
    static void secondStepLevelTwo() {
        Asset r = [SELECT Id FROM Asset WHERE Name = 'root' LIMIT 1];
        Asset a = [SELECT Id FROM Asset WHERE Name = 'test' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new MS_FSM_SnChainRebuildQueue(0, new List<String>{r.Id}, new Set<String>{a.Id}));
        Test.stopTest();
    }
}