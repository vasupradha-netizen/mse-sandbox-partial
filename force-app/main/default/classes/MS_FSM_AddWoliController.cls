/******************************************************************************
 * Name         : MS_FSM_AddWoliController
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-02-01
 * Description  : powers the LWC "msFsmAddWoliMain", which allows a user to add
 * 				  one or more Work Order Line Items (woli) to a Work Order
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-02-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * since we have natively implemented MS_FSM_L2_Asset__c on the Asset table,
 * we no longer need to use AssetHelper. that could be refactored out to save
 * on characters, but no meaningful impact on processing time / efficiency.
 * 
 * Tests:
 * MS_FSM_AddWoliTests
 ******************************************************************************/

public class MS_FSM_AddWoliController {
    
    /********************************************************
	 * Purpose: retrieve the Work Order (via context from current page)
	 * Input:	woid - the record Id passed from the LWC
	 * Output:	a Work Order record
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static WorkOrder getWorkOrder(String woid) {
        return [SELECT Id,
                	   AssetId,
                       LocationId
                FROM   WorkOrder
                WHERE  Id = :woid];
    }
    
    /********************************************************
	 * Purpose: retrieve child Assets under the root Asset from the Work Order.
	 * 			these populate a multi-select list.
	 * Input:	rootId - the Root Asset Id from the Work Order (retrieved by getWorkOrder)
	 * Output:	a list of AssetHelper objects
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static List<AssetHelper> getChildAssets(String rootId) {
        List<AssetHelper> ahs = new List<AssetHelper>();
        for (Asset a : [SELECT   Id,
                        		 Status,
                        		 Name,
                        		 MS_FSM_Run_Hours__c,
                        		 MS_FSM_Asset_Placement__c,
                        		 SerialNumber,
                        		 ProductFamily,
                        		 MS_FSM_Parent_Asset_Name__c,
                        		 ParentId,
                        		 RootAssetId,
                        		 MS_FSM_Serial_Chain__c,
                        		 MS_FSM_L2_Asset__c,
                        		 MS_FSM_L2_Asset__r.ProductFamily,
                                 MS_FSM_L2_Asset__r.Name
                        FROM     Asset
                        WHERE    RootAssetId = :rootId
                        AND      Id != :rootId
                        AND      Status != 'Obsolete'
                        ORDER BY MS_FSM_Install_Date_Time__c DESC, Product2.Family NULLS LAST]) 
        {
            ahs.add(new AssetHelper(a));
        }
        return ahs;
    }
    
    /********************************************************
	 * Purpose: get Work Types to populate dropdown.
	 * 			this list may be filtered based on the families of selected
	 * 			child assets.
	 * Input:	families - list of families (strings) from selected child assets (if applicable)
	 * Output:	list of Work Types
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static List<WorkType> getWorkTypes(List<String> families) {
        return [SELECT Id,
                       Name,
                       EstimatedDuration,
                       DurationType,
                       MS_FSM_Work_Group__c,
                       MS_FSM_Duration_and_Duration_Type__c,
                       MS_FSM_Family__c
                FROM   WorkType
                WHERE  MS_FSM_Family__c = ''
                OR     MS_FSM_Family__c IN :families];
    }
    
    /********************************************************
	 * Purpose: list of Products (not revs) available for selection as
	 * 			install/swap.
	 * Input:	s - search input from User
	 * 			f - family value from selected Work Type
	 * 			n - name of Work Type
	 * Output:	list of Work Types
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Product2> getProducts(String s, String f, String n) {
        List<Product2> revReturn = new List<Product2>();
        Set<String> parentIds = new Set<String>();
        for (Product2 p : getRevs(s, f)) {
            parentIds.add(p.MS_FSM_Parent_Product__c);
            revReturn.add(p);
            if (n == 'Rework Retrofit' && revReturn.size() == 15) {
                return revReturn;
            }
        }
        
        return [SELECT Id,
                       Name
                FROM   Product2
                WHERE  Id IN :parentIds
                ORDER BY Name
                LIMIT 15];
    }
    
    /********************************************************
	 * Purpose: submit client-side inputs for commit
	 * Input:	ip - JS object with all inputs
	 * Output:	String message:
	 * 				SUCCESS 	- records committed
	 * 				else 		- something went wrong and we will
	 * 							  throw to console
	 ********************************************************/
    @AuraEnabled
    public static String submit(Map<String, Object> ip) {
        
        List<Object> 	childIds 	= (List<Object>)ip.get('childIds');
        String 			woid 		= (String)ip.get('woid');
        String 			dtype 		= (String)ip.get('dType');
        Decimal 		dura 		= Decimal.valueOf((String)ip.get('duration'));
        String 			repId 		= (String)ip.get('replaceId');
        String 			wtypeId 	= (String)ip.get('wtypeid');
        String			wtypegroup	= (String)ip.get('wtypegroup');
        String 			planReact 	= (String)ip.get('planReact');
        
        WorkOrder wo = getWoFinal(woid);
        
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        for (Object o : childIds) {
            Map<Object, Object> child = (Map<Object, Object>)o;
            
            String childId 		= getStringValue('id', child);
            String parentId 	= getStringValue('parentId', child);
            String l2Id 		= getStringValue('l2Id', child);
            
            wolis.add(new WorkOrderLineItem(
            	WorkOrderId 					= wo.Id,
                Subject							= wo.Subject,
                Description						= wo.Description,
                AssetId							= wtypegroup == 'Installation' ? null : childId,
                MS_FSM_Root_Asset__c 			= wo.AssetId,
                Duration 						= dura,
                DurationType 					= dtype,
                MS_FSM_Install_Swap_Product__c 	= String.isBlank(repId) ? null : repId,
                WorkTypeId 						= wtypeId,
                MS_FSM_Planned_or_Reactive__c 	= planReact,
                MS_FSM_Parent_Asset__c			= wtypegroup == 'Installation' ? childId : parentId,
                MS_FSM_Method_of_Creation__c	= 'lwc/msFsmAddWoliMain',
                MS_FSM_L2_Asset__c 				= l2Id
            ));
        }
        
        try {
            INSERT wolis;
	        System.enqueueJob(new MS_FSM_AddWoliFollowupQueue(woid));		// send to async followup actions            
            return 'SUCCESS';
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    /********************************************************
	 * Purpose: inner helper class for piecing together Asset outputs
	 ********************************************************/
    @TestVisible
    private class AssetHelper {
        @AuraEnabled public String 	id;
        @AuraEnabled public String 	status;
        @AuraEnabled public String 	name;
        @AuraEnabled public Decimal runHours;
        @AuraEnabled public String  parentName;
        @AuraEnabled public String  placement;
        @AuraEnabled public String 	prodFam;
        @AuraEnabled public String  l2Serial;
        @AuraEnabled public String 	l2Id;
        @AuraEnabled public String 	l2Fam;
        @AuraEnabled public String 	l2Name;
        @AuraEnabled public String 	parentId;
        @AuraEnabled public String 	rootId;
        @AuraEnabled public String  serialChain;
        
        AssetHelper(Asset a) {
            id 				= a.Id;
            status 			= a.Status;
            name 			= a.Name;
            runHours 		= a.MS_FSM_Run_Hours__c;
            parentName		= a.MS_FSM_Parent_Asset_Name__c;
            prodFam 		= a.ProductFamily;
            parentId 		= a.ParentId;
            rootId 			= a.RootAssetId;
            placement		= a.MS_FSM_Asset_Placement__c;
            serialChain		= a.MS_FSM_Serial_Chain__c;
            l2Id			= a.MS_FSM_L2_Asset__c;
            l2Fam			= a.MS_FSM_L2_Asset__r.ProductFamily;
            l2Name			= a.MS_FSM_L2_Asset__r.Name;
        }
    }
    
    /********************************************************
	 * Purpose: utility method for stringifying values from input
	 * Input:	k - key / label for value
	 * 			m - input map
	 * Output:	string value retrieved using key
	 ********************************************************/
    private static String getStringValue(String k, Map<Object, Object> m) {
        Object o = m.get(k);
        return o == null ? null : (String)o;
    }
    
    /********************************************************
	 * Purpose: retriev Revs (parent products)
	 * Input:	s - search string from user
	 * 			f - family value from selected Work Type
	 * Output:	list of Products
	 ********************************************************/
    private static List<Product2> getRevs(String s, String f) {
        s = ('%' + s + '%');
        String q =  'SELECT Id, MS_FSM_Parent_Product__c ';
               q += 'FROM Product2 ';
               q += 'WHERE IsActive = true AND MS_FSM_Product_Type__c = \'Asset\' ';
               q += 'AND (Name LIKE \'' + s + '\'';
               q += (String.isBlank(f) ? (' OR Family LIKE \'' + s + '\')') : (' AND Family = \'' + f + '\')'));
        return (List<Product2>)Database.query(q);
    }
    
    /********************************************************
	 * Purpose: retrieve work order for final commit
	 * Input:	woid - Work Order Id
	 * Output:	single Work Order
	 ********************************************************/
    private static WorkOrder getWoFinal(String woid) {
        return [SELECT Id,
                       Subject,
                       Description,
                	   AssetId
                FROM   WorkOrder
                WHERE  Id = :woid];
    }
}