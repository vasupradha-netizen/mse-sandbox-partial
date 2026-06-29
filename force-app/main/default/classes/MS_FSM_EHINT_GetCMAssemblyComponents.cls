/******************************************************************************
 * Name         : MS_FSM_EHINT_GetCMAssemblyComponents
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : recursive queueable - loops over all top-level Assemblies or 
 * 				  CM Assemblies retrieved on a given day and fetches their
 * 			      CM Assembly Components
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *   2025-09-15 | Nathan Ehrmann      | added considered for FID 355 for upsert check
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_GetCMAssemblyComponents implements Queueable, Database.AllowsCallouts {

    public List<String> newTopAssetIds;
    public Integer 		index;
    public Boolean		skipWriteback;
    
    private Boolean hasError = false;
    private String  sourceTable;
    
    public void execute(QueueableContext q) { 
        if (newTopAssetIds == null || newTopAssetIds.isEmpty()) { 
            return; 
        }
        
        Asset topAsset = MS_FSM_EHINT_Utils.getTopAsset(newTopAssetIds[index]);
        sourceTable = topAsset.MS_FSM_EtaHub_Table_Id__c;
        
        Map<Integer, MS_FSM_EtaHub_Integration_Definition__c> 	cmCompDefs = MS_FSM_EHINT_Utils.getIntDefs('brv5up2nq');
        List<Map<Integer, Map<String, String>>> 				cmCompData = MS_FSM_EHINT_Utils.getEHData(cmCompDefs.values(), '{203.EX.' + topAsset.SerialNumber + '}AND{72.EX.0}AND{82.XEX.}AND{313.EX.0}', 0, 0);
        
        if (cmCompData.isEmpty()) {
            nextJob();
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(cmCompData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - ' + topAsset.Id + ' - CM Assembly Component Failure', 
                cmCompData[0].get(0).get('error'), 
                topAsset.Id, 
                'MS_FSM_EHINT_GetCMAssemblyComponents');
            hasError = true;
            nextJob();
            return;
        }
        
        Map<String, Asset> assetMap = MS_FSM_EHINT_Utils.getAssetMap(cmCompData, 355, 82, 130);
            
        Map<String, Product2> revToProduct = new Map<String, Product2>();
        for (Map<Integer, Map<String, String>> d : cmCompData) {
            revToProduct.put(d.get(130).get('value'), new Product2());
        }
        
        MS_FSM_EHINT_Utils.buildProductMap(revToProduct);
        
        List<Asset> newAssets = new List<Asset>();
        for (Map<Integer, Map<String, String>> d : cmCompData) {
            String   s = d.get(82).get('value');
            String   r = d.get(130).get('value');
            String   t = d.get(15).get('value');
            Product2 p = revToProduct.get(r);
            
            if (String.isBlank(p?.Id) || p.MS_FSM_Product_Type__c == 'Part') {
                continue;
            }
            
            Asset a;
            
            if (assetMap.containsKey(r + s)) {
                a = assetMap.get(r + s);
            } else {
                a = new Asset(
                    Name 							= (d.get(82).get('value') + ' | ' + d.get(130).get('value') + ' - ' + d.get(131).get('value')).left(80),
                    MS_FSM_Manufactured_By__c		= 'CM',
                    MS_FSM_Method_of_Creation__c	= 'EtaHub',
                    MS_FSM_LGen_SN_Short_Form__c 	= topAsset.MS_FSM_LGen_SN_Short_Form__c,
                    Product2Id						= p.Id,
                    MS_FSM_EtaHub_Table_Id__c		= 'brv5up2nq',
                    LocationId						= t == topAsset.SerialNumber ? topAsset.LocationId : null
                );
            }
            a.Status 				= 'Installed';
            a.AccountId 			= topAsset.AccountId;
            a.MS_FSM_Create_ATL__c 	= true;
            
            MS_FSM_EHINT_Utils.mapValues(d, cmCompDefs, a);
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
            newTopAssetIds.remove(index);
            if (newTopAssetIds.isEmpty()) {
                return;
            }
        }
        if (index == newTopAssetIds.size()) {
            MS_FSM_EHINT_AssemblyWriteback j = new MS_FSM_EHINT_AssemblyWriteback(
                newTopAssetIds,
                sourceTable,
                sourceTable == 'bnnfe2qf9' ? '515' : '213',
                skipWriteback
            );
            if (!Test.isRunningTest()) {
                System.enqueueJob(j);
            }
        }
        else {
            MS_FSM_EHINT_GetCMAssemblyComponents j 					= new MS_FSM_EHINT_GetCMAssemblyComponents();
            							  		 j.newTopAssetIds 	= newTopAssetIds;
            							  		 j.index 			= index;
            									 j.skipWriteback	= skipWriteback;
            System.enqueueJob(j);
        }
    }
}