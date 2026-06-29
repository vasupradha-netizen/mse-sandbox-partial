public with sharing class MS_FSM_Woli_Controller {
    //need from WOLI: work order number, woli number, asset id, asset name, root asset id
    //need from asset: any asset related via root id

    @AuraEnabled(cacheable=true)
    public static WorkOrderLineItem getCurrentWoliDetails(String woliId) {
        
        try {
            WorkOrderLineItem woli = [SELECT 
                        Id,                          
                        WorkOrderId, 
                        WorkOrder.WorkOrderNumber, 
                        WorkOrder.MS_FSM_Inventory_Location__c,
                        MS_FSM_Root_Asset__c,
                        MS_FSM_Install_Swap_Product__c,
                        MS_FSM_L2_Asset__c,
                        MS_FSM_L2_Asset__r.Name,
                        MS_FSM_L2_Asset__r.MS_FSM_Return_Rings_for_Inspection__c,
                        MS_FSM_L2_Asset__r.SerialNumber,
                        MS_FSM_L2_Asset__r.Product2.Family,
                        AssetId, 
                        MS_FSM_Parent_Asset__c,
                        Asset.Name, 
                        Asset.MS_FSM_Asset_Placement__c,
                        Asset.SerialNumber,
                        Asset.Product2.Family,
                        LineItemNumber,
                        Asset.MS_FSM_Removal_Disposition__c,
                        Asset.RootAsset.Name,
                        Asset.RootAsset.SerialNumber
                        FROM WorkOrderLineItem
                        WHERE Id = :woliId];
            return woli;
        } 
        catch (Exception ex) {
            throw ex;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Asset> getRelatedAssets(String rootAssetId) {
        try {
            List<Asset> assets = [SELECT 
                                    Id,
                                    Name
                                  FROM Asset
                                  WHERE RootAssetId = :rootAssetId
                                  ];
            return assets;

        } catch (Exception ex) {
            throw ex;
        }
    }
    // @AuraEnabled(cacheable=true)
    // public static WorkOrderLineItem getCurrentWoliDetails(String woliId) {
        
    //     try {
    //         WorkOrderLineItem woli = [SELECT Id,
    //                                         AssetId,
    //                                         WorkOrderId,
    //                                         LineItemNumber,
    //                                         MS_FSM_Root_Asset__c
    //                                     FROM WorkOrderLineItem
    //                                     WHERE Id = :woliId];
    //         return woli;
    //     } 
    //     catch (Exception ex) {
    //         throw ex;
    //     }
    // }

    // @AuraEnabled(cacheable=true)
    // public static WorkOrder getCurrentWoDetails(String woId) {
    //     try {
    //         WorkOrder wo = [SELECT Id, 
    //                             WorkOrderNumber
    //                         FROM WorkOrder
    //                         WHERE Id = :woId];
    //         return wo;

    //     } catch (Exception ex) {
    //         throw ex;
    //     }
    // }

    // @AuraEnabled(cacheable=true)
    // public static Asset getRootAsset(String rootAssetId) {
    //     try {
    //         Asset asset = [SELECT 
    //                         Name
    //                     FROM Asset
    //                     WHERE Id = :rootAssetId
    //                     ];
    //         return asset;
    //     } catch (Exception ex) {
    //         throw ex;
    //     }
    // }

    // @AuraEnabled(cacheable=true)
    // public static List<Asset> getRelatedAssets(String rootAssetId) {
    //     try {
    //         List<Asset> assets = [SELECT Id,
    //                                 AssetLevel,
    //                                 Name
    //                               FROM Asset
    //                               WHERE RootAssetId = :rootAssetId
    //                               ];
    //         return assets;

    //     } catch (Exception ex) {
    //         throw ex;
    //     }
    // }

        // @AuraEnabled(cacheable=true)
    // public static WorkStep getCurrentDetails(String recordId) {
        
    //    try {
    //         WorkStep ws = [SELECT Id,
    //                             WorkOrderLineItemId,
    //                             WorkOrderId
    //                         FROM WorkStep
    //                         WHERE Id = :recordId];
    //         return ws;
    //    }   
    //      catch (Exception ex) {
    //         throw ex;
    //     }
    // } 

    // @AuraEnabled(cacheable=true)
    // public static Asset getAssetToUpdate(String assetId) {
    //     try {
    //         Asset asset = [SELECT Id,
    //                         Status,
    //                         UsageEndDate
    //                     FROM Asset
    //                     WHERE Id = :assetId];
    //         return asset;

    //     } catch (Exception ex) {
    //         throw ex;
    //     }
    // } //remove?
}