@isTest
private class MS_FSM_AddWoliTests {

    @isTest
    static void std() {
        WorkOrder wo = [SELECT Id, AssetId FROM WorkOrder LIMIT 1];
        MS_FSM_AddWoliController.getWorkOrder(wo.Id);
        
        List<MS_FSM_AddWoliController.AssetHelper> 	cats 	= MS_FSM_AddWoliController.getChildAssets(wo.AssetId);
        List<WorkType> 								wts 	= MS_FSM_AddWoliController.getWorkTypes(new List<String>{});
        List<Product2> 								prods 	= MS_FSM_AddWoliController.getProducts('child', '', '');
        
        List<Map<Object, Object>> childIds = new List<Map<Object, Object>>{
            new Map<Object, Object> {
            'id' 		=> cats[0].id,
            'parentId' 	=> cats[0].parentId,
            'l2Id' 		=> cats[0].l2Id
        }};
        
        Map<String, Object> ip = new Map<String, Object>{
            'childIds' 		=> childIds,
            'woid' 			=> wo.Id,
            'dType' 		=> 'Minutes',
            'duration' 	 	=> '60',
            'repId'		 	=> prods[0].Id,
            'wTypeId' 		=> wts[0].Id,
            'wtypegroup'	=> wts[0].MS_FSM_Work_Group__c,
            'planReact' 	=> 'Planned'
        };
            
        Test.startTest();
        String s = MS_FSM_AddWoliController.submit(ip);
        Test.stopTest();
    }
    
    @TestSetup
    static void setup() {
        Product2 root = new Product2(
        	Name 		= 'root',
            IsActive 	= true
        );
        INSERT root;
        Product2 parent = new Product2(
        	Name 		= 'parent',
            IsActive 	= true
        );
        INSERT parent;
        Product2 child = new Product2(
        	Name 						= 'child',
            IsActive 					= true,
            MS_FSM_Product_Type__c 		= 'Asset',
            MS_FSM_Parent_Product__c 	= parent.Id
        );
        INSERT child;
        
        List<Asset> ats = new List<Asset>();
        Asset a = new Asset(
        	Product2Id 	= root.Id,
            Name 		= 'root'
        );
        INSERT a;
        Asset b = new Asset(
        	Product2Id 	= child.Id,
            Name 		= 'child',
            ParentId 	= a.Id
        );
        INSERT b;
        
        INSERT new WorkOrder(
        	Subject = 'test wo',
            AssetId = a.Id
        );
        
        INSERT new WorkType(
        	Name 					= 'test',
            EstimatedDuration 		= 60,
            DurationType 			= 'Minutes',
            MS_FSM_Work_Group__c	= 'Installation'
        );
    }
    
}