public with sharing class MS_FSM_InstallAsset_Controller {

    @AuraEnabled(cacheable=true)
    public static WorkOrderLineItem getCurrentInstallAssetDetails(String woliId) {
        try {
            WorkOrderLineItem woli = [SELECT 
                            Id,                            
                            LineItemNumber,
                            WorkTypeId,
                            WorkType.MS_FSM_Work_Group__c,
                            MS_FSM_Installed_Asset_Asset_Placement__c,
                            MS_FSM_Installed_Asset_Install_Date_Time__c,
                            MS_FSM_Installed_Asset_Product_Item__c,
                            MS_FSM_Installed_Asset_Quantity__c,
                            MS_FSM_Installed_Asset_Serial_Number__c,
                            MS_FSM_Removed_Asset_Removal_Disposition__c,
                            MS_FSM_Removed_Asset_Usage_End_Date_Time__c,
                            MS_FSM_Run_Asset_Actions__c,
                            MS_FSM_Missing_Inventory_Description__c,
                            WorkOrderId,
                            WorkOrder.WorkOrderNumber, 
                            WorkOrder.ServiceTerritoryId,
                            MS_FSM_Install_Swap_Product__c,
                            MS_FSM_Install_Swap_Product__r.MS_FSM_Parent_Product__c,
                            MS_FSM_Install_Swap_Product__r.Name,
                            MS_FSM_Install_Swap_Product__r.IsSerialized,
                            MS_FSM_Install_Swap_Product__r.MS_FSM_Require_Asset_Placement__c,
                            MS_FSM_Parent_Asset__c,
                            MS_FSM_Parent_Asset__r.Name,
                            MS_FSM_Parent_Asset__r.SerialNumber,
                            MS_FSM_Parent_Asset__r.Product2.Family,
                            MS_FSM_Root_Asset__c,
                            MS_FSM_L2_Asset__c,
                            MS_FSM_L2_Asset__r.SerialNumber,
                            MS_FSM_L2_Asset__r.Product2.Family,
                            MS_FSM_L2_Asset__r.MS_FSM_Return_Rings_for_Inspection__c,
                            AssetId, 
                            Asset.Name, 
                            Asset.MS_FSM_Asset_Placement__c,
                            Asset.SerialNumber,
                            Asset.Product2.Family,
                            Asset.MS_FSM_Removal_Disposition__c,
                            MS_FSM_Root_Asset__r.SerialNumber,
                            MS_FSM_Root_Asset__r.Product2.Family
                            FROM WorkOrderLineItem
                            WHERE Id = :woliId];
            return woli;

        } catch (Exception ex) {
            throw ex;
        }
    }

    @AuraEnabled(cacheable=true)
    public static WorkOrderLineItem getCurrentReplaceAssetDetails(String woliId) {
        try {
            WorkOrderLineItem woli = [SELECT 
                            Id,                            
                            WorkOrderId, 
                            WorkOrder.WorkOrderNumber, 
                            WorkOrder.ServiceTerritoryId,
                            MS_FSM_Install_Swap_Product__c,
                            MS_FSM_Install_Swap_Product__r.Name,
                            MS_FSM_Install_Swap_Product__r.IsSerialized,
                            MS_FSM_Parent_Asset__c,
                            MS_FSM_Parent_Asset__r.Name,
                            MS_FSM_Parent_Asset__r.SerialNumber,
                            MS_FSM_Parent_Asset__r.Product2.Family,
                            LineItemNumber,
                            MS_FSM_Root_Asset__c,
                            MS_FSM_L2_Asset__c,
                            MS_FSM_L2_Asset__r.Name,
                            MS_FSM_L2_Asset__r.MS_FSM_Return_Rings_for_Inspection__c,
                            AssetId, 
                            Asset.Name, 
                            Asset.MS_FSM_Asset_Placement__c,
                            Asset.SerialNumber,
                            Asset.Product2.Family,
                            Asset.MS_FSM_Removal_Disposition__c,
                            Asset.RootAsset.Name,
                            Asset.RootAsset.SerialNumber
                            FROM WorkOrderLineItem
                            WHERE Id = :woliId];
            return woli;

        } catch (Exception ex) {
            throw ex;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Schema.Location> getLocationName(string inventoryLocation) {
        List<Schema.Location> locationName = [SELECT Name FROM Location WHERE Id = :inventoryLocation];
        return locationName;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<ServiceTerritoryLocation> getServiceTerritory(string woServiceTerritoryId) {
        List<ServiceTerritoryLocation> serviceTerritoryLocation = [SELECT LocationId FROM ServiceTerritoryLocation WHERE ServiceTerritoryId = :woServiceTerritoryId];
        return serviceTerritoryLocation;
    }


    // @AuraEnabled(cacheable=true)
    // public static List<ProductItem> getProductItems(String inventoryLocation) {
    //         List<ProductItem> productItems = [SELECT 
    //                             Id,
    //                             Product2Id,
    //                             Product2.Name,
    //                             Product2.IsSerialized,
    //                             Product2.MS_FSM_Cost__c,
    //                             QuantityOnHand
    //                             FROM ProductItem
    //                             WHERE LocationId = :inventoryLocation                         
    //                             AND Product2.MS_FSM_Product_Type__c = 'Asset'
    //                             AND QuantityOnHand > 0
    //                             ];
    //         return productItems;
    // }

    @AuraEnabled(cacheable=true)
    public static List<ProductItem> getProductItemsForSTLocations(List<Id> serviceTerritoryLocationIds, Id parentProductId){
        List<ProductItem> productItems = [SELECT 
                                Id,
                                Product2Id,
                                Product2.MS_FSM_Parent_Product__c,
                                Product2.Name,
                                Product2.IsSerialized,
                                Location.Name,
                                Location.MS_FSM_Shortened_Name__c,
                                QuantityOnHand,
                                Product2.MS_FSM_Cost__c
                                FROM ProductItem
                                WHERE LocationId in :serviceTerritoryLocationIds                         
                                AND Product2.MS_FSM_Parent_Product__c = :parentProductId];
            return productItems;
    }

    @AuraEnabled(cacheable=true)
    public static List<SerializedProduct> getSerializedProducts(List<Id> serviceTerritoryLocationIds, Id parentProductId) {
            List<SerializedProduct> serializedProducts = [SELECT  
                                                Id,
                                                ProductItemId, 
                                                Status, 
                                                Product2Id,
                                                Product2.MS_FSM_Parent_Product__c,
                                                Product2.Name, 	
                                                Name, 
                                                SerialNumber,
                                                MS_FSM_Product_Cost__c 
                                                FROM SerializedProduct 
                                                WHERE ProductItem.LocationId in :serviceTerritoryLocationIds
                                                AND Product2.MS_FSM_Parent_Product__c = :parentProductId
                                                AND Status = 'Available'];
                return serializedProducts;
    }
}