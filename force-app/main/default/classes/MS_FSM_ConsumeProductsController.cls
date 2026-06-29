/******************************************************************************
 * Name         : MS_FSM_ConsumeProductsController
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : this powers the LWC consumeProducts, which allows a user to
 * 				  specify products to consume from a WOLI or Work Step
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_ConsumeProductsControllerTest
 ******************************************************************************/
public without sharing class MS_FSM_ConsumeProductsController {

    /********************************************************
	 * Purpose: get the current context record
	 * Input:	recordId - may be a Work Step or a Work Order Line Item Id
	 * Output:	the current context WOLI
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static WorkOrderLineItem getWorkOrderLine(String recordId) {
        String woliid = recordId;
        try {                                                        	// first, attempt to retrieve a Work Step, in case we are
            WorkStep step = [SELECT Id, 								// running in that context
                                    WorkOrderLineItemId
                            FROM    WorkStep
                            WHERE   Id = :recordId];

            woliid = step.WorkOrderLineItemId;
        }
        catch (Exception ex) { /* DO NOTHING - JUST KEEP ORIGINAL woliid */ }
        
        WorkOrderLineItem r;
        try {
            r = [SELECT Id,
                        LineItemNumber,
                        Asset.Name,
                        WorkOrderId,
                        WorkOrder.WorkOrderNumber,
                        WorkOrder.MS_FSM_Inventory_Location__c
                FROM    WorkOrderLineItem
                WHERE   Id = :woliid];     
        }
        catch (Exception ex) { /* DO NOTHING - JUST RETURN */ }
        
        return r;
    }

    /********************************************************
	 * Purpose: get Products Required for current context
	 * Input:	woliid - Work Order Line Item id for current context
	 * Output:	list of Products Required
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ProductRequired> getProductRequired(String woliid) {
        return [SELECT  Id,
                        Product2.Name,
                        Product2Id,
                        Product2.IsSerialized,
                        Product2.MS_FSM_Cost__c,
                        QuantityRequired
                FROM    ProductRequired
                WHERE   ParentRecordId = :woliid
                AND     Product2.MS_FSM_Product_Type__c = 'Part'];
    }

    /********************************************************
	 * Purpose: get Product Items (inventory) represented by
	 * 			Product Required records and at a given Location
	 * Input:	productIds - list of Product2 ids
	 * 			locationId - id of Location record
	 * Output:	list of available Product Items to consume
	 ********************************************************/
    @AuraEnabled(cacheable=true)
    public static List<ProductItem> getProductItems(List<String> productIds, String locationId) {
        return [SELECT Id,
                       Product2Id,
                       QuantityOnHand
                FROM   ProductItem
                WHERE  Product2Id IN :productIds
                AND    LocationId = :locationId];
    }
}