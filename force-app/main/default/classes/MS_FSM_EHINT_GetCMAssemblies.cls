/******************************************************************************
 * Name         : MS_FSM_EHINT_GetCMAssemblies
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : retrieves CM Assemblies that are marked ready for sync
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
public class MS_FSM_EHINT_GetCMAssemblies implements Queueable, Database.AllowsCallouts {

    @TestVisible private String dummyAcc;
    
    public String filterOverride;
    
    public void execute(QueueableContext q) {       
        List<Asset> newAssets 	= new List<Asset>();
        String 		f 		 	= String.isBlank(filterOverride) ? '{214.EX.1}AND{213.EX.}' : filterOverride;
        
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	assemblyDefs = MS_FSM_EHINT_Utils.getIntDefs('brv5unzwf');
        List<Map<Integer, Map<String, String>>> 				assemblyData = MS_FSM_EHINT_Utils.getEHData(assemblyDefs.values(), f, 0, 0);
        
        if (assemblyData.isEmpty()) {											// NO HITS
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(assemblyData)) {						// API TRANSACTION FAILURE
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - CM Assembly Failure', 
                assemblyData[0].get(0).get('error'), 
                'NA', 
                'MS_FSM_EHINT_GetCMAssemblies');
            return;
        }
        
        Map<String, Product2> 			revNumToProd 	= new Map<String, Product2>();
        Map<String, Schema.Location> 	locMap 			= new Map<String, Schema.Location>();
        Map<String, MS_FSM_Node__c> 	nodeMap 		= new Map<String, MS_FSM_Node__c>();
        
        for (Map<Integer, Map<String, String>> data : assemblyData) {            
            String revNum = data.get(121).get('value');
            if (!String.isBlank(revNum)) {
                revNumToProd.put(revNum, new Product2());
            }
            
            String nodeName = data.get(221).get('value');
            if (!String.isBlank(nodeName)) {
                nodeMap.put(nodeName, new MS_FSM_Node__c(Name = nodeName));
            }
            
            String locName = data.get(251).get('value');
            if (String.isBlank(locName)) {
                continue;
            }
            
            String accId = String.isBlank(dummyAcc) ? data.get(253).get('value') : dummyAcc;
            	   accId = String.isBlank(accId)    ? '001Qr00000DY7pBIAT' 		 : accId;		// default to Mainspring
            
            locMap.put(locName, new Schema.Location(
                Name 									= locName,
                LocationType 							= 'Site',
                MS_FSM_Account__c						= accId,
                MS_FSM_Customer_Site_Name__c 			= data.get(250).get('value'),
                MS_FSM_Location_Address__Street__s		= data.get(244).get('value') + ' ' + data.get(245).get('value'),
                MS_FSM_Location_Address__City__s 		= data.get(246).get('value'),
                MS_FSM_Location_Address__StateCode__s 	= MS_FSM_EHINT_Utils.getStateCode(data.get(247).get('value')),
                MS_FSM_Location_Address__PostalCode__s 	= data.get(248).get('value'),
                MS_FSM_Location_Address__CountryCode__s = MS_FSM_EHINT_Utils.getCountryCode(data.get(249).get('value'))
            ));
        }
        
        MS_FSM_EHINT_Utils.buildProductMap(revNumToProd);
        MS_FSM_EHINT_Utils.buildNodeMap(nodeMap);
        MS_FSM_EHINT_Utils.buildLocationMap(locMap);
        
        for (Map<Integer, Map<String, String>> data : assemblyData) {
            String serial = data.get(12).get('value');
            String revNum = data.get(121).get('value');
            if (String.isBlank(revNum) || !revNumToProd.containsKey(revNum)) {
                continue;
            }
            String p = revNumToProd.get(revNum).Id;
            
            String locName = data.get(251).get('value');
            Schema.Location l;
            if (!String.isBlank(locName) && locMap.containsKey(locName)) {
                l = locMap.get(locName);
            }
            
            String nodeName = data.get(221).get('value');
            MS_FSM_Node__c node;
            if (!String.isBlank(nodeName) && nodeMap.containsKey(nodeName)) {
                node = nodeMap.get(nodeName);
            }
            
            Asset a = new Asset(
            	Name 							= (serial + ' | ' + data.get(121).get('value') + ' - ' + data.get(10).get('value')).left(80),
                Status 							= 'Installed',
                MS_FSM_Manufactured_By__c 		= 'CM',
                MS_FSM_Method_of_Creation__c	= 'EtaHub',
                MS_FSM_Node__c					= node == null ? null : node.Id,
                Product2Id						= p,
                LocationId						= l == null ? null : l.Id,
                AccountId						= l.MS_FSM_Account__c,
                Top__c							= true,
                MS_FSM_EtaHub_Table_Id__c		= 'brv5unzwf',
                MS_FSM_Create_ATL__c			= true
            );
            
            MS_FSM_EHINT_Utils.mapValues(data, assemblyDefs, a);            
            newAssets.add(a);
        }
        
        AssetTriggerHandler.skipProcessing();
        INSERT newAssets;
        
        /* ### TO NEXT JOB ### */
        
        if (newAssets == null || newAssets.isEmpty()) { 			// early exit
            return; 										        // no next job
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