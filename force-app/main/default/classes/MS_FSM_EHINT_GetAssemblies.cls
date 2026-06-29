/******************************************************************************
 * Name         : MS_FSM_EHINT_GetAssemblies
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : retrieves Assemblies that are marked ready for sync
 * 				  then proceeds to next queueable jobs for getting components, parenting, etc.
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_GetAssemblies implements Queueable, Database.AllowsCallouts {
    
    @TestVisible private String dummyAcc;
    
    public String filterOverride;
    
    public void execute(QueueableContext q) {       
        List<Asset> newAssets 	= new List<Asset>();
        String 		f 		 	= String.isBlank(filterOverride) ? '{514.EX.1}AND{515.EX.}' : filterOverride;
        
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	assemblyDefs = MS_FSM_EHINT_Utils.getIntDefs('bnnfe2qf9');
        List<Map<Integer, Map<String, String>>> 				assemblyData = MS_FSM_EHINT_Utils.getEHData(assemblyDefs.values(), f, 0, 0);
        
        if (assemblyData.isEmpty()) {											// NO HITS FROM EH
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(assemblyData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Assembly Failure', 
                assemblyData[0].get(0).get('error'), 
                'NA', 
                'MS_FSM_EHINT_GetAssemblies');
            return;
        }
        
        Map<String, Product2> 			revNumToProd 	= new Map<String, Product2>();
        Map<String, Schema.Location> 	locMap 			= new Map<String, Schema.Location>();
        Map<String, MS_FSM_Node__c> 	nodeMap 		= new Map<String, MS_FSM_Node__c>();
        
        for (Map<Integer, Map<String, String>> data : assemblyData) {
            String revNum = data.get(7).get('value');
            if (!String.isBlank(revNum)) {
                revNumToProd.put(revNum, new Product2());
            }
            
            String nodeName = data.get(525).get('value');
            if (!String.isBlank(nodeName)) {
                nodeMap.put(nodeName, new MS_FSM_Node__c(Name = nodeName));
            }
            
            String locName = data.get(559).get('value');
            if (String.isBlank(locName)) {														// SKIP PROCESSING - no location
                continue;
            }
            
            String accId = String.isBlank(dummyAcc) ? data.get(561).get('value') : dummyAcc;	// dummy Account value used for testing
                   accId = String.isBlank(accId)    ? '001Qr00000DY7pBIAT' 		 : accId;		// default to Mainspring
            
            locMap.put(locName, new Schema.Location(
                Name 									= locName,
                LocationType 							= 'Site',
                MS_FSM_Account__c						= accId,
                MS_FSM_Customer_Site_Name__c 			= data.get(560).get('value'),
                MS_FSM_Location_Address__Street__s 		= data.get(553).get('value') + ' ' + data.get(554).get('value'),
                MS_FSM_Location_Address__City__s 		= data.get(555).get('value'),
                MS_FSM_Location_Address__StateCode__s 	= MS_FSM_EHINT_Utils.getStateCode(data.get(556).get('value')),
                MS_FSM_Location_Address__PostalCode__s 	= data.get(557).get('value'),
                MS_FSM_Location_Address__CountryCode__s = MS_FSM_EHINT_Utils.getCountryCode(data.get(558).get('value'))
            ));
        }
        
        MS_FSM_EHINT_Utils.buildProductMap(revNumToProd);
        MS_FSM_EHINT_Utils.buildNodeMap(nodeMap);
        MS_FSM_EHINT_Utils.buildLocationMap(locMap);
        
        for (Map<Integer, Map<String, String>> data : assemblyData) {
            String revNum = data.get(7).get('value');
            if (String.isBlank(revNum) || !revNumToProd.containsKey(revNum)) {			// SKIP PROCESSING - no rev (Product2)
                continue;
            }
            String p = revNumToProd.get(revNum).Id;
            
            String locName = data.get(559).get('value');
            Schema.Location l;
            if (!String.isBlank(locName) && locMap.containsKey(locName)) {
                l = locMap.get(locName);
            }
            
            String nodeName = data.get(525).get('value');
            MS_FSM_Node__c node;
            if (!String.isBlank(nodeName) && nodeMap.containsKey(nodeName)) {
                node = nodeMap.get(nodeName);
            }
            
            Asset a = new Asset(
            	Name 							= (data.get(12).get('value') + ' | ' + data.get(7).get('value') + ' - ' + data.get(8).get('value')).left(80),
                Status 							= 'Installed',
                MS_FSM_Manufactured_By__c 		= 'MSE',
                MS_FSM_Method_of_Creation__c	= 'EtaHub',
                MS_FSM_Node__c					= node == null ? null : node.Id,
                Product2Id						= p,
                LocationId						= l == null ? null : l.Id,
                AccountId						= l.MS_FSM_Account__c,
                Top__c							= true,
                MS_FSM_EtaHub_Table_Id__c		= 'bnnfe2qf9',
                MS_FSM_Create_ATL__c			= true
            );
            MS_FSM_EHINT_Utils.mapValues(data, assemblyDefs, a);            
            newAssets.add(a);
        }
        
        AssetTriggerHandler.skipProcessing();
        INSERT newAssets;
        
        /* ### TO NEXT JOB ### */
        
        if (newAssets == null || newAssets.isEmpty()) { 							// EARLY EXIT - no top-levels, processed
            return; 															    // therefore no need for rest of chain
        }
        
        List<String> newAssetIds = new List<String>();
        for (Asset t : newAssets) { 
            newAssetIds.add(t.Id);
        }
        
        MS_FSM_EHINT_GetAssemblyComponents 	j 					= new MS_FSM_EHINT_GetAssemblyComponents();
        									j.newTopAssetIds 	= newAssetIds;
        									j.index 			= 0;
        if (!Test.isRunningTest()) {
            System.enqueueJob(j);            
        }
    }
}