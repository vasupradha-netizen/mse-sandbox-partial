/******************************************************************************
 * Name         : MS_FSM_AssetStagingTriggerHandler
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-06-01
 * Description  : trigger handler for Asset Staging records
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-06-01 | Nathan Ehrmann      | BEFORE INSERT - check for missing data / errors
 *										AFTER  INSERT - send to MS_FSM_AssetStagingProcessing
 *   2025-09-15 | Nathan Ehrmann	  | added pre-check for existing assets via composite id (rev + serial number)
 * 
 * Notes:
 * 
 * Tests:
 * MS_FSM_AssetStagingTest
 ******************************************************************************/
public class MS_FSM_AssetStagingTriggerHandler {
    
    private static Boolean hasRun = false;
    
    public static void mainEntry(Boolean isBefore,
                                 Boolean isAfter,
                                 Boolean isInsert,
                                 List<MS_FSM_EtaHub_Asset_Staging__c> newRecs) 
    {
        if (!isInsert || hasRun) {
            return;
        }
        if (isAfter) {
            hasRun = true;
        }
        
        Set<String> inAssetIds  = new Set<String>();
        Set<String> inProdCodes = new Set<String>();
        for (MS_FSM_EtaHub_Asset_Staging__c s : newRecs) {
            addToSet(s.MS_FSM_Asset_Id__c, 		inAssetIds);
            addToSet(s.MS_FSM_Part_Number__c, 	inProdCodes);
        }
        
        Set<String> exAssetIds  = getExAssetIds(inAssetIds);
        Set<String> exProdCodes = getExProdCodes(inProdCodes);
        
        List<MS_FSM_EtaHub_Asset_Staging__c> exCheck	= new List<MS_FSM_EtaHub_Asset_Staging__c>();
        List<MS_FSM_EtaHub_Asset_Staging__c> processing = new List<MS_FSM_EtaHub_Asset_Staging__c>();
        
        for (MS_FSM_EtaHub_Asset_Staging__c s : newRecs) {
            if (isBefore) {
                s.MS_FSM_Stage__c = 'New';
				errorCheck(s, 'MS_FSM_Asset_Id__c', 	exAssetIds,  'Unable to find Asset with Record Id: ' + s.MS_FSM_Asset_Id__c);
				errorCheck(s, 'MS_FSM_Part_Number__c', 	exProdCodes, 'Product Missing');                
            	
                if (String.isBlank(s.MS_FSM_Asset_Id__c) && !s.MS_FSM_Is_New_Asset_Record__c) {
                    exCheck.add(s);
                }
            }
            if (isAfter) {
                if (s.MS_FSM_Stage__c == 'New') {
                    processing.add(s);
                }
            }
        }
        
        checkExisting(exCheck);
        
        if (!processing.isEmpty()) {
            MS_FSM_AssetStagingProcessing j = new MS_FSM_AssetStagingProcessing(processing);
            j.execute();
        }
    }
        
    private static Set<String> getExAssetIds(Set<String> inAssetIds) {
        Set<String> exAssetIds = new Set<String>();
        for (Asset a : [SELECT Id FROM Asset WHERE Id IN :inAssetIds]) {
            exAssetIds.add(a.Id);
        }
        return exAssetIds;
    }
    
    private static Set<String> getExProdCodes(Set<String> inProdCodes) {
        Set<String> exProdCodes = new Set<String>();
        for (Product2 p : [SELECT ProductCode FROM Product2 WHERE ProductCode IN :inProdCodes]) {
            exProdCodes.add(p.ProductCode);
        }
        return exProdCodes;
    } 
    
    private static void addToSet(String v, Set<String> t) {
        if (!String.isBlank(v)) {
            t.add(v);
        }
    }
    
    private static void errorCheck(MS_FSM_EtaHub_Asset_Staging__c s, String f, Set<String> compare, String errMsg) {
        String v = (String)s.get(f);
        if (!String.isBlank(v) && !compare.contains(v)) {
            s.MS_FSM_Stage__c 			= 'Error';
            s.MS_FSM_Error_Message__c 	= errMsg;
        }
    }
    
    private static void checkExisting(List<MS_FSM_EtaHub_Asset_Staging__c> checks) {
        if (checks.isEmpty()) {
            return;
        }
        Set<String> revs = new Set<String>();
        Set<String> sns  = new Set<String>();
        for (MS_FSM_EtaHub_Asset_Staging__c c : checks) {
            if (String.isBlank(c.MS_FSM_Part_Number__c) || String.isBlank(c.MS_FSM_Asset_Serial_Number__c)) {
                continue;
            }
            revs.add(c.MS_FSM_Part_Number__c);
            sns.add(c.MS_FSM_Asset_Serial_Number__c);
        }
        Map<String, String> compIdToAssetId = new Map<String, String>();
        for (Asset a : [SELECT Id, 
                               Product2.ProductCode, 
                               SerialNumber 
                        FROM   Asset 
                        WHERE  Product2.ProductCode IN :revs 
                        AND    SerialNumber 		IN :sns]) 
        {
        	compIdToAssetId.put(a.Product2.ProductCode + a.SerialNumber, a.Id);    
        }
        for (MS_FSM_EtaHub_Asset_Staging__c c : checks) {
            if (String.isBlank(c.MS_FSM_Part_Number__c) || String.isBlank(c.MS_FSM_Asset_Serial_Number__c)) {
                continue;
            }
            c.MS_FSM_Asset_Id__c = compIdToAssetId.get(c.MS_FSM_Part_Number__c + c.MS_FSM_Asset_Serial_Number__c);
        }
    }
}