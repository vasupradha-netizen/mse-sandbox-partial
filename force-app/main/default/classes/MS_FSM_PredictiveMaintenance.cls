public class MS_FSM_PredictiveMaintenance {

    private String 			assetId;
    private Asset			a;
    private List<Asset> 	relatedAssets;
    private WorkOrder		wo;
    private WorkType		wt;
    private Decimal 		totalDuration = 0;
    
    private final List<String> CLOSED_STATUS = new List<String>{'Completed', 'Cannot Complete', 'Closed', 'Canceled'};

    private Id 			rootAssetId;
    private Set<String> productFamilies;

    public MS_FSM_PredictiveMaintenance(String t) {
        assetId = t;
    }

    public MS_FSM_PredictiveMaintenance(Id rootId, Set<String> families) {
        rootAssetId 	= rootId;
        productFamilies = families;
    }
    
    public void execute() {
        if (rootAssetId != null && productFamilies != null && !productFamilies.isEmpty()) {
            executeByRoot();
        } else if (assetId != null) {
            executeByAssetId();
        }
    }

    private void executeByRoot() {
        getAssetByRoot();
        if (a == null) {
            return;
        }
        getRelatedAssetsByRoot();
        if (!hasAssetsWithWorkType()) {
            return;
        }
        buildWorkOrder();
        buildWorkOrderLines();
        buildServiceAppt();
    }

    private void executeByAssetId() {
        getAsset();
        if (a == null || String.isBlank(a.Product2.Family)) {
            return;
        }
        getWorkType();
        if (wt == null) {
            return;
        }
        getRelatedAssets();
        //if (updateExistingServiceAppt()) {
           // return;
        //}
        buildWorkOrder();
        buildWorkOrderLines();
        buildServiceAppt();
    }
    
    private void getAsset() {
        List<Asset> assets = [SELECT 	Id,
                                        RootAssetId,
                              			RootAsset.Location.AccountId,
                                        RootAsset.Location.MS_FSM_Location_Address__Street__s,
                                        RootAsset.Location.MS_FSM_Location_Address__City__s,
                                        RootAsset.Location.MS_FSM_Location_Address__StateCode__s,
                                        RootAsset.Location.MS_FSM_Location_Address__PostalCode__s,
                                        RootAsset.Location.MS_FSM_Location_Address__CountryCode__s,
              							LocationId,
                                        MS_FSM_LGen_SN_Short_Form__c,
                                        Product2.Family,
                                        Product2.MS_FSM_Parent_Product__c,
                                        ParentId,
                                        MS_FSM_L2_Asset__c,
              							MS_FSM_Predictive_Service_Date__c,
              							MS_FSM_Predictive_Service_Lead_Time__c
                              FROM    	Asset
                              WHERE   	Id = :assetId
                              AND     	Status != 'Obsolete'];
        a = assets.isEmpty() ? null : assets[0];
    }

    private void getAssetByRoot() {
        List<Asset> assets = [SELECT 	Id,
                                        RootAssetId,
                              			RootAsset.Location.AccountId,
                                        RootAsset.Location.MS_FSM_Location_Address__Street__s,
                                        RootAsset.Location.MS_FSM_Location_Address__City__s,
                                        RootAsset.Location.MS_FSM_Location_Address__StateCode__s,
                                        RootAsset.Location.MS_FSM_Location_Address__PostalCode__s,
                                        RootAsset.Location.MS_FSM_Location_Address__CountryCode__s,
              							LocationId,
                                        MS_FSM_LGen_SN_Short_Form__c,
                                        Product2.Family,
                                        Product2.MS_FSM_Parent_Product__c,
                                        ParentId,
                                        MS_FSM_L2_Asset__c,
              							MS_FSM_Predictive_Service_Date__c,
              							MS_FSM_Predictive_Service_Lead_Time__c
                              FROM    	Asset
                              WHERE   	RootAssetId = :rootAssetId
                              AND     	Product2.Family IN :productFamilies
                              AND     	Status != 'Obsolete'
                              ORDER BY MS_FSM_Predictive_Service_Date__c ASC NULLS LAST
                              LIMIT    1];
        a = assets.isEmpty() ? null : assets[0];
    }
    
    private void getRelatedAssets() {
        relatedAssets = [SELECT Id,
                         		Product2.Family,
                         		Product2.MS_FSM_Parent_Product__c,
                         		ParentId,
                         		MS_FSM_L2_Asset__c,
                         		RootAssetId
                         FROM 	Asset
                         WHERE 	Product2.Family = :a.Product2.Family
                         AND	Id != :a.Id
                         AND   	RootAssetId = :a.RootAssetId
                         AND   	Status != 'Obsolete'];
    }

    private void getRelatedAssetsByRoot() {
        relatedAssets = [SELECT Id,
                                Product2.Family,
                                Product2.MS_FSM_Parent_Product__c,
                                ParentId,
                                MS_FSM_L2_Asset__c,
                                RootAssetId
                        FROM 	Asset
                        WHERE 	RootAssetId = :rootAssetId
                        AND     Product2.Family IN :productFamilies
                        AND     Status != 'Obsolete'
                        AND     Id != :a.Id];
    }
    
    /*
    private Boolean updateExistingServiceAppt() {
        Set<String> tids = new Set<String>();
        tids.add(a.Id);
        for (Asset t : relatedAssets) {
            tids.add(t.Id);
        }
        
        List<WorkOrderLineItem> exWoli = [SELECT Id,
                                          		 WorkOrderId,
                                          		 AssetId,
                                                 Asset.MS_FSM_Predictive_Service_Date__c
                                          FROM   WorkOrderLineItem
                                          WHERE  AssetId IN :tids
                                          AND  	 WorkTypeId = :wt.Id
                                          AND    Status NOT IN :CLOSED_STATUS
                                          AND    WorkOrder.Status NOT IN :CLOSED_STATUS];
        if (exWoli.isEmpty()) {
            return false;
        }
        String  woid 			= exWoli[0].WorkOrderId;
        Integer x				= a.MS_FSM_Predictive_Service_Lead_Time__c == null ? 7 : Integer.valueOf(a.MS_FSM_Predictive_Service_Lead_Time__c);
        Date    minPredictive 	= a.MS_FSM_Predictive_Service_Date__c;
        
        for (WorkOrderLineItem w : exWoli) {
            if (w.Asset.MS_FSM_Predictive_Service_Date__c < minPredictive) {	// early exit if the new incoming PSD is not the minimum
                return true;													// among all assets in this Work Type / Family group
            }
        }
        
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :woid LIMIT 1];
        sa.DueDate = minPredictive;
        sa.EarliestStartTime = DateTime.newInstance(minPredictive.addDays(-x), Time.newInstance(6,0,0,0));
        UPDATE sa;
        return true;
    }
    */
    
    private void buildServiceAppt() {
        totalDuration = totalDuration > 8 * 60 ? 8 : totalDuration / 60;
        INSERT new ServiceAppointment(
            Subject 			= wo.Subject,
            DueDate 			= DateTime.newInstance(a.MS_FSM_Predictive_Service_Date__c, Time.newInstance(18,0,0,0)),
            ParentRecordId 		= wo.Id,
            Street				= wo.Street,
            City				= wo.City,
            StateCode			= wo.StateCode,
            PostalCode			= wo.PostalCode,
            CountryCode			= wo.CountryCode,
            Duration			= totalDuration,
            DurationType		= 'Hours'
        );
    }
    
    private void buildWorkOrder() {
        String subject = (rootAssetId != null) ? 'Predictive Maintenance' : (a.Product2.Family + ' - Predictive Maintenance');
        wo = new WorkOrder(
            	AssetId    						= a.RootAssetId,
                LocationId 						= a.RootAsset.LocationId,
            	AccountId						= a.RootAsset.Location?.AccountId,
                Street	   						= a.RootAsset.Location?.MS_FSM_Location_Address__Street__s,
                City	   						= a.RootAsset.Location?.MS_FSM_Location_Address__City__s,
                StateCode	   					= a.RootAsset.Location?.MS_FSM_Location_Address__StateCode__s,
                PostalCode 						= a.RootAsset.Location?.MS_FSM_Location_Address__PostalCode__s,
                CountryCode	   					= a.RootAsset.Location?.MS_FSM_Location_Address__CountryCode__s,
                Subject   	 					= subject,
                MS_FSM_Number_of_Techs__c 		= 1,
            	MS_FSM_Method_of_Creation__c 	= 'Predictive Maintenance',
                WorkTypeId						= '08qQr0000008qq7IAA'
        );
        INSERT wo;
    }
    
    private void buildWorkOrderLines() {
        List<WorkOrderLineItem> wolis = new List<WorkOrderLineItem>();
        if (rootAssetId != null) {
            Map<String, WorkType> familyToWorkType = getWorkTypesByFamily();
            for (Asset t : relatedAssets) {
                WorkType assetWt = String.isNotBlank(t.Product2.Family) ? familyToWorkType.get(t.Product2.Family) : null;
                if (assetWt != null) {
                    wolis.add(createWoli(t, assetWt));
                    totalDuration += assetWt.DurationInMinutes;
                }
            }
            WorkType anchorWt = String.isNotBlank(a.Product2.Family) ? familyToWorkType.get(a.Product2.Family) : null;
            if (anchorWt != null) {
                wolis.add(createWoli(a, anchorWt));
                totalDuration += anchorWt.DurationInMinutes;
            }
        } else {
            wolis.add(createWoli(a, wt));
            totalDuration += wt.DurationInMinutes;
            for (Asset t : relatedAssets) {
                wolis.add(createWoli(t, wt));
                totalDuration += wt.DurationInMinutes;
            }
        }
        if (!wolis.isEmpty()) {
            INSERT wolis;
        }
    }
    
    private WorkOrderLineItem createWoli(Asset a, WorkType w) {
        return new WorkOrderLineItem(
                WorkOrderId 					= wo.Id,
            	AssetId 						= a.Id,
                MS_FSM_Root_Asset__c 			= a.RootAssetId,
                WorkTypeId 						= w.Id,
                MS_FSM_Install_Swap_Product__c 	= a.Product2.MS_FSM_Parent_Product__c,
                MS_FSM_Planned_or_Reactive__c 	= 'Planned',
                MS_FSM_Parent_Asset__c 			= a.ParentId,
                MS_FSM_Method_of_Creation__c 	= 'Predictive Maintenance',
                MS_FSM_L2_Asset__c 				= a.MS_FSM_L2_Asset__c);
    }
    
    private void getWorkType() {
        try {
            wt = [SELECT Id, DurationInMinutes FROM WorkType WHERE MS_FSM_Family__c = :a.Product2.Family LIMIT 1];
        } catch (Exception ex) {
            // DO NOTHING - will early exit in the main method
        }
    }

    private Map<String, WorkType> getWorkTypesByFamily() {
        Map<String, WorkType> result = new Map<String, WorkType>();
        if (productFamilies == null || productFamilies.isEmpty()) {
            return result;
        }
        for (WorkType w : [SELECT Id, DurationInMinutes, MS_FSM_Family__c FROM WorkType WHERE MS_FSM_Family__c IN :productFamilies]) {
            result.put(w.MS_FSM_Family__c, w);
        }
        return result;
    }

    /*
    private WorkType getWorkTypeForAsset(Asset a) {
        if (a == null || String.isBlank(a.Product2.Family)) {
            return null;
        }
        try {
            return [SELECT Id, DurationInMinutes FROM WorkType WHERE MS_FSM_Family__c = :a.Product2.Family LIMIT 1];
        } catch (Exception ex) {
            return null;
        }
    }
    */

    private Boolean hasAssetsWithWorkType() {
        return !getWorkTypesByFamily().isEmpty();
    }
}