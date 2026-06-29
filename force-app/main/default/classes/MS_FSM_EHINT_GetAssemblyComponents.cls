/******************************************************************************
 * Name         : MS_FSM_EHINT_GetAssemblyComponents
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : recursive queueable - loops over all top-level Assemblies or 
 * 				  CM Assemblies retrieved on a given day and fetches their
 * 			      Assembly Components
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *   2025-09-16 | Nathan Ehrmann      | added FID 638 for upsert consideration
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_GetAssemblyComponents implements Queueable, Database.AllowsCallouts {
    
    public List<String> newTopAssetIds;
    public Integer 		index;
    public Boolean		skipWriteback = false;
    
    private Boolean hasError = false;
    
    public void execute(QueueableContext q) {
        if (newTopAssetIds == null || newTopAssetIds.isEmpty()) { 
            return; 
        }
        
        Asset topAsset = MS_FSM_EHINT_Utils.getTopAsset(newTopAssetIds[index]);
        
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	acompDefs = MS_FSM_EHINT_Utils.getIntDefs('bnnfe3sdc');
        List<Map<Integer, Map<String, String>>> 				acompData = MS_FSM_EHINT_Utils.getEHData(acompDefs.values(), '{437.EX.' + topAsset.SerialNumber + '}AND{44.EX.0}AND{12.XEX.}AND{580.EX.0}', 0, 0);
        
        if (acompData.isEmpty()) {
            nextJob();
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(acompData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - ' + topAsset.Id + ' - Assembly Component Failure', 
                acompData[0].get(0).get('error'), 
                topAsset.Id, 
                'MS_FSM_EHINT_GetAssemblyComponents');
            hasError = true;
            nextJob();
            return;
        }
        
        Map<String, Asset> assetMap = MS_FSM_EHINT_Utils.getAssetMap(acompData, 638, 12, 15);
        
        Map<String, Product2> revToProduct = new Map<String, Product2>();
        for (Map<Integer, Map<String, String>> d : acompData) {
            revToProduct.put(d.get(15).get('value'), new Product2());
        }
        
        MS_FSM_EHINT_Utils.buildProductMap(revToProduct);
        
        List<Asset> newAssets = new List<Asset>();
        for (Map<Integer, Map<String, String>> d : acompData) {
            String 	 s = d.get(12).get('value');					// serial number <--> Asset.SerialNumber
            String 	 r = d.get(15).get('value');					// rev number    <--> Product2.ProductCode
            String   t = d.get(21).get('value');
            
            Product2 p = revToProduct.get(r);
            if (String.isBlank(p?.Id) || p.MS_FSM_Product_Type__c == 'Part') {
                continue;
            }
            
            Asset a;
            if (assetMap.containsKey(r + s)) {
                a = assetMap.get(r + s);
            } else {
                a = new Asset(
                    Name 							= (d.get(12).get('value') + ' | ' + d.get(15).get('value') + ' - ' + d.get(14).get('value')).left(80),
                    MS_FSM_Manufactured_By__c		= 'MSE',
                    MS_FSM_LGen_SN_Short_Form__c 	= topAsset.MS_FSM_LGen_SN_Short_Form__c,
                    MS_FSM_Method_of_Creation__c	= 'EtaHub',
                    Product2Id						= p.Id,
                    MS_FSM_EtaHub_Table_Id__c		= 'bnnfe3sdc',
                    LocationId						= t == topAsset.SerialNumber ? topAsset.LocationId : null
                );
            }
            a.Status 				= 'Installed';
            a.AccountId 			= topAsset.AccountId;
            a.MS_FSM_Create_ATL__c 	= true;
            
            MS_FSM_EHINT_Utils.mapValues(d, acompDefs, a);
            a.InstallDate = a.MS_FSM_Install_Date_Time__c == null ? null : a.MS_FSM_Install_Date_Time__c.date();
            
            newAssets.add(a);
        }
        
        AssetTriggerHandler.skipProcessing();
        UPSERT newAssets;
        
        nextJob();
    }
    
    private void nextJob() {
        if (!hasError) {
            index++;
        } else {
            newTopAssetIds.remove(index);			// remove this LGEN from processing and proceed
            if (newTopAssetIds.isEmpty()) {			// or halt if no more LGENs
                return;
            }
        }
        if (index == newTopAssetIds.size()) { 
            MS_FSM_EHINT_GetCMAssemblyComponents 	j 				 = new MS_FSM_EHINT_GetCMAssemblyComponents();
            										j.newTopAssetIds = newTopAssetIds;
            										j.index 	     = 0;
            										j.skipWriteback  = skipWriteback;
            if (!Test.isRunningTest()) {
                System.enqueueJob(j);
            }
        } else {
            MS_FSM_EHINT_GetAssemblyComponents  j 					= new MS_FSM_EHINT_GetAssemblyComponents();
        										j.newTopAssetIds 	= newTopAssetIds;
        										j.index 			= index;
            									j.skipWriteback     = skipWriteback;
            System.enqueueJob(j);
        }
    }
}