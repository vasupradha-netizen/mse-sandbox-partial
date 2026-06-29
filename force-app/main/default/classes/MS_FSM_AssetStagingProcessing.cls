/******************************************************************************
 * Name         : MS_FSM_AssetStagingProcessing
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-06-01
 * Description  : this enables a Pipeline-driven "upgrades" process by taking in
 * 				  Staging records (MS_FSM_Asset_Staging__c) and processing them into
 * 				  Asset updates and Asset Transaction Log inserts.
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-06-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_AssetStagingTest
 ******************************************************************************/
public class MS_FSM_AssetStagingProcessing {

    private List<MS_FSM_EtaHub_Asset_Staging__c> recs;
    
    private Map<String, String> 						prodCodeToProdId 			= new Map<String, String>();
    private Map<String, Asset>  						assetIdToAsset   			= new Map<String, Asset>();
    private Map<String, AssetHistory>					assetIdToRunHours			= new Map<String, AssetHistory>();
    private Map<String, MS_FSM_EtaHub_Asset_Staging__c> assetIdToStaging 			= new Map<String, MS_FSM_EtaHub_Asset_Staging__c>();
    private Map<String, String>							assetStagingIdToOutcome		= new Map<String, String>();
    private List<Asset>									newAssets					= new List<Asset>();
    private List<Asset>									updateAssets				= new List<Asset>();
    private List<MS_FSM_EtaHub_Asset_Staging__c>		updateStages				= new List<MS_FSM_EtaHub_Asset_Staging__c>();
    private List<MS_FSM_Asset_Transaction_Log__c> 		newAtl						= new List<MS_FSM_Asset_Transaction_Log__c>();   
    private List<MS_FSM_Asset_Transaction_Log__c> 		exAtl;
    private DateTime 									minimum;
    private DateTime									maximum;
    
    private final String DATA_USER = '005Qr00000B2n4lIAB';
    
    public MS_FSM_AssetStagingProcessing(List<MS_FSM_EtaHub_Asset_Staging__c> r) {
        recs = r;
    }
    
    public void execute() {
        initialize();
        AssetTriggerHandler.skipProcessing();
        createAssets();
        checkAtl();
        processStaging();
        finalize();
        toParenting();
    }
    
    private void initialize() {
        for (MS_FSM_EtaHub_Asset_Staging__c s : recs) {
            if (!String.isBlank(s.MS_FSM_Asset_Id__c)) {
                assetIdToStaging.put(s.MS_FSM_Asset_Id__c, s);
                assetIdToAsset.put(s.MS_FSM_Asset_Id__c, null);
            }
            
            if (!String.isBlank(s.MS_FSM_Part_Number__c)) {
                prodCodeToProdId.put(s.MS_FSM_Part_Number__c, null); 
            }
            
            DateTime t 			= s.MS_FSM_Timestamp__c;
            		 minimum 	= (minimum == null || t < minimum) ? t : minimum;
            		 maximum    = (maximum == null || t > maximum) ? t : maximum;
        }
        buildAssetMap();
        buildProdMap();
        buildRunHoursMap();
        getAtl();
    }
    
    private void finalize() {
        UPDATE updateAssets;
        INSERT newAtl;
        UPDATE updateStages;
    }
    
    private void toParenting() {
        List<String> PARENTING_CLASS_NAMES = new List<String> {
            'MS_FSM_EHINT_AssetStagingParentingSched',
            'MS_FSM_EHINT_AssetStagingParentingQ'
        };
                    
        DateTime 	p = System.now().addMinutes(5);
        String 		c = '' + p.second() + ' ' + p.minute() + ' ' + p.hour() + ' ' + p.day() + ' ' + p.month() + ' ? ' + p.year();
        
        List<AsyncApexJob> jobs = [SELECT 	Id 
                                   FROM 	AsyncApexJob 
                                   WHERE 	ApexClass.Name IN :PARENTING_CLASS_NAMES 
                                   AND 		Status IN ('Holding', 'Preparing', 'Processing', 'Queued')];
        
        if (jobs.isEmpty()) {
            System.schedule('Staging Record Parenting ' + String.valueOf(p), c, new MS_FSM_AssetStagingParentingSched());
        } 
    }
    
    private void updateStage(String sid, String s) {
        updateStages.add(new MS_FSM_EtaHub_Asset_Staging__c(Id = sid, MS_FSM_Stage__c = s));
    }
    
    private void createAssets() {
        List<MS_FSM_EtaHub_Asset_Staging__c> recsWithNewAssets = new List<MS_FSM_EtaHub_Asset_Staging__c>();
        for (MS_FSM_EtaHub_Asset_Staging__c s : recs) {
            if (!String.isBlank(s.MS_FSM_Asset_Id__c)) {
                continue;
            }
            recsWithNewAssets.add(s);
            newAssets.add(mapAsset(s));
        }
        INSERT newAssets;
        for (Integer i = 0; i < newAssets.size(); i++) {
            MS_FSM_EtaHub_Asset_Staging__c 	s = recsWithNewAssets[i];
            Asset 							t = newAssets[i];
            newAtl.add(createAtl(s, t));
            updateStages.add(new MS_FSM_EtaHub_Asset_Staging__c(
            	Id 					= s.Id,
                MS_FSM_Stage__c 	= 'Processed - New Asset',
                MS_FSM_Asset_Id__c 	= t.Id
            ));
        }
    }
    
    private void checkAtl() {
        for (MS_FSM_Asset_Transaction_Log__c atl : exAtl) {
            MS_FSM_EtaHub_Asset_Staging__c stage = assetIdToStaging.get(atl.MS_FSM_Asset_Id__c);
            if (assetStagingIdToOutcome.containsKey(stage.Id)) {										// already processed
                continue;
            }
            if (atl.MS_FSM_Timestamp__c < stage.MS_FSM_Timestamp__c) {
                continue;
            }
            // now, we proceed knowing that the ATL is 
            // LATER THAN the provided upgrade/staging record
            if (isMatch(stage, atl)) {
                assetStagingIdToOutcome.put(stage.Id, 'DUPLICATE');										// this means we will potentially just apply updates to the Asset
            } else {
                assetStagingIdToOutcome.put(stage.Id, 'LATER ATL EXISTS');  							// this means we will create an ATL, but not update the Asset
            }
        }
    }
    
    private void processStaging() {
        for (MS_FSM_EtaHub_Asset_Staging__c s : recs) {
            if (String.isBlank(s.MS_FSM_Asset_Id__c)) {			// ALREADY PROCESSED by creating new Asset + ATL
                continue;
            }
            
            Asset a = assetIdToAsset.get(s.MS_FSM_Asset_Id__c);
            
            switch on (assetStagingIdToOutcome.containsKey(s.Id) ? assetStagingIdToOutcome.get(s.Id) : 'NO LATER ATL') {
                when 'NO LATER ATL' {
                    updateStage(s.Id, 'Processed - New ATL and Asset Update');
                    updateAssets.add(mapAsset(s));
                    newAtl.add(createAtl(s, a));
                }
                when 'DUPLICATE' {
                    updateStage(s.Id, 'Not Applicable');
                } 
                when 'LATER ATL EXISTS' {
                    updateStage(s.Id, 'Processed - Later ATL Found - New ATL Only');
                    newAtl.add(createAtl(s, a));
                }
            }
        }
    }
    
    private Boolean isMatch(MS_FSM_EtaHub_Asset_Staging__c s, MS_FSM_Asset_Transaction_Log__c atl) {
        return s.MS_FSM_Timestamp__c            == atl.MS_FSM_Timestamp__c &&
               s.MS_FSM_Status__c               == atl.MS_FSM_Status__c    &&
               s.MS_FSM_Parent_Serial_Number__c == atl.MS_FSM_Parent_Asset_Serial_Number__c;
    }
    
    private Asset mapAsset(MS_FSM_EtaHub_Asset_Staging__c s) {
        String 	status 		= s.MS_FSM_Status__c;
        Boolean isInstall 	= status == 'Installed';
        Asset a = new Asset(
            Status 							= status,
            MS_FSM_EtaHub_Table_Id__c 		= s.MS_FSM_EtaHub_Table_Id__c,
            MS_FSM_EtaHub_Record_Id__c 		= s.MS_FSM_EtaHub_Record_Id__c,
            Description 					= s.MS_FSM_Description__c,
            Name 							= s.MS_FSM_Asset_Serial_Number__c + ' | ' + s.MS_FSM_Part_Number__c + ' - ' + s.MS_FSM_Description__c,
            SerialNumber				 	= s.MS_FSM_Asset_Serial_Number__c,
            MS_FSM_Usage_End_Date_Time__c 	= isInstall ? null : s.MS_FSM_Timestamp__c
        );
        if (!String.isBlank(s.MS_FSM_Asset_Id__c)) {
            a.Id = s.MS_FSM_Asset_Id__c;
        } else {
            a.Product2Id  					= prodCodeToProdId.get(s.MS_FSM_Part_Number__c);
            a.Quantity 	  					= s.MS_FSM_Quantity__c;
            a.MS_FSM_Method_of_Creation__c 	= 'Upgrades';
        }
        if (isInstall) {
            a.MS_FSM_Install_Date_Time__c 		= s.MS_FSM_Timestamp__c;
            a.MS_FSM_Parent_Serial_Number__c 	= s.MS_FSM_Parent_Serial_Number__c;
            a.MS_FSM_Asset_Placement__c			= s.MS_FSM_Asset_Placement__c;
        } else {
            a.ParentId 							= null;
            a.MS_FSM_Removal_Disposition__c 	= s.MS_FSM_Removal_Disposition__c;
        }
        return a;
    }
    
    private MS_FSM_Asset_Transaction_Log__c createAtl(MS_FSM_EtaHub_Asset_Staging__c s, Asset a) {
        
        return new MS_FSM_Asset_Transaction_Log__c(
        	MS_FSM_Asset_Id__c 					 = a == null ? s.MS_FSM_Asset_Id__c : a.Id,
            MS_FSM_EtaHub_Record_Id__c           = s.MS_FSM_EtaHub_Record_Id__c,
            MS_FSM_Status__c                     = s.MS_FSM_Status__c,
            MS_FSM_Asset_Serial_Number__c        = s.MS_FSM_Asset_Serial_Number__c,
            MS_FSM_Parent_Asset_Serial_Number__c = s.MS_FSM_Parent_Serial_Number__c,
            MS_FSM_EtaHub_Source_Table__c        = s.MS_FSM_EtaHub_Table_Id__c,
            MS_FSM_Transaction_Type__c           = 'Status Change',
            MS_FSM_Method_of_Creation__c 		 = s.MS_FSM_Method_of_Creation__c,
            MS_FSM_Timestamp__c                  = s.MS_FSM_Timestamp__c,
            MS_FSM_Run_Hours__c                  = a == null || !assetIdToRunHours.containsKey(a.Id) ? null : (Decimal)assetIdToRunHours.get(a.Id).NewValue,
            MS_FSM_Root_Serial_Number__c         = s.MS_FSM_Root_Serial_Number__c
        );
    }
    
    private void buildRunHoursMap() {
        for (AssetHistory h : [SELECT CreatedDate, NewValue, AssetId 
                               FROM   AssetHistory
                               WHERE  AssetId      IN :assetIdToAsset.keySet()
                               AND    CreatedDate   < :maximum
                               AND    Field 		= 'MS_FSM_Run_Hours__c'
                               AND    CreatedById 	= :DATA_USER]) 
        {
            MS_FSM_EtaHub_Asset_Staging__c s = assetIdToStaging.get(h.AssetId);
            if (s == null || s.MS_FSM_Timestamp__c < h.CreatedDate) {
                continue;
            }
            AssetHistory r = assetIdToRunHours.get(h.AssetId);
            if (r == null || h.CreatedDate > r.CreatedDate) {
                assetIdToRunHours.put(h.AssetId, h);
            }
        }
    }
    
    private void buildAssetMap() {
        for (Asset a : [SELECT Id, MS_FSM_Run_Hours__c FROM Asset WHERE Id IN :assetIdToAsset.keySet()]) {
            assetIdToAsset.put(a.Id, a);
        }
    }
    
    private void buildProdMap() {
        for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode IN :prodCodeToProdId.keySet()]) {
            prodCodeToProdId.put(p.ProductCode, p.Id);
        }
    }                                                                                                                                           
    
    private void getAtl() {
        exAtl = [SELECT MS_FSM_Status__c,
            		     MS_FSM_Timestamp__c,
            			 MS_FSM_Parent_Asset_Serial_Number__c,
            			 MS_FSM_Asset_Id__c
            	  FROM   MS_FSM_Asset_Transaction_Log__c
            	  WHERE  MS_FSM_Asset_Id__c IN :assetIdToAsset.keySet()
            	  AND 	MS_FSM_Timestamp__c >= :minimum];
    }
}