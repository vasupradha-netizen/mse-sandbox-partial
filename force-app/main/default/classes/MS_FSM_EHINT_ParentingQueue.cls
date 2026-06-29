/******************************************************************************
 * Name         : MS_FSM_EHINT_ParentingQueue
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : recursive queueable that executes a "top-down" parenting
 * 				  for LGENs; also assigns L2 Asset
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
public class MS_FSM_EHINT_ParentingQueue implements Queueable {

    private List<String>		topIds;
    private Integer				index;
    private Set<String> 		parentIds;			// current-level ids -- starts with top-level assemblies and works down
    
    private Map<String, Asset> 	serialToAsset;
    private List<Asset> 		assetsToParent;
    private String				topLgen;
    private Set<String>			nextIds;
    
    public MS_FSM_EHINT_ParentingQueue(List<String> tids, Integer i, Set<String> pids) {
        topIds 		= tids;
        index 		= i;
        parentIds 	= pids == null ? new Set<String>{topIds[index]} : pids;
    }
    
    public void execute(QueueableContext qc) {
        setSerialMap();
        setAssets();
        
        Boolean notTest = !Test.isRunningTest();
        
        if (assetsToParent.isEmpty()) {
            index++;
            if (notTest) {
                if (index < topIds.size()) {
                    System.enqueueJob(new MS_FSM_EHINT_ParentingQueue(topIds, index, null));		// next top-level asset
                } else {
                    Database.executeBatch(new MS_FSM_EHINT_CreateLogsBatch());						// next major step - create logs
                }
            }
            return;
        }
        
        updateAssets();
        
        if (notTest) {
            System.enqueueJob(new MS_FSM_EHINT_ParentingQueue(topIds, index, nextIds));				// next tree level
        }
    }
    
    public void setSerialMap() {
        serialToAsset = new Map<String, Asset>();
        for (Asset a : [SELECT 	Id, 
                        	    SerialNumber, 
                        		MS_FSM_Serial_Chain__c, 
                        		MS_FSM_LGen_SN_Short_Form__c 
                        FROM 	Asset 
                        WHERE 	Id IN :parentIds 
                        AND 	SerialNumber != '']) 
        {
            serialToAsset.put(a.SerialNumber.toUpperCase(), a);
        }
        topLgen = serialToAsset.values().isEmpty() ? '' : serialToAsset.values()[0].MS_FSM_LGen_SN_Short_Form__c;
    }
    
    private void setAssets() {
        assetsToParent = [SELECT Id, MS_FSM_Parent_Serial_Number__c, SerialNumber
                          FROM   Asset 
                          WHERE  MS_FSM_Parent_Serial_Number__c IN :serialToAsset.keySet() 
                          AND    MS_FSM_LGen_SN_Short_Form__c = :topLgen
                          AND    MS_FSM_Method_of_Creation__c = 'EtaHub'];
    }
    
    private void updateAssets() {
        Set<String> l2sns 	= new Set<String>();
        			nextIds = new Set<String>();
        for (Asset a : assetsToParent) {
        	String s = a.MS_FSM_Parent_Serial_Number__c;
            Asset  p = serialToAsset.get(s.toUpperCase());
            if (p == null) {
                continue;
            }
            
            nextIds.add(a.Id);
            
            String c = p.MS_FSM_Serial_Chain__c;
            
            a.ParentId 							= p.Id;
            a.MS_FSM_Parent_Serial_Number__c 	= '';
            a.MS_FSM_Serial_Chain__c 			= String.isBlank(c) ? s : (c + ', ' + s);
            
            List<String> chainSns = a.MS_FSM_Serial_Chain__c.split(',');
            if (chainSns.size() < 2) {
                continue;
            }
            l2sns.add(chainSns[1].trim());
        }
        
        Map<String, String> l2snToId = getL2map(l2sns);
        
        for (Asset a : assetsToParent) {
            String c = a.MS_FSM_Serial_Chain__c;
            if (String.isBlank(c)) {
                continue;
            }
            
            List<String> chainSns = a.MS_FSM_Serial_Chain__c.split(',');
            if (chainSns.size() < 2) {
                continue;
            }
            
            a.MS_FSM_L2_Asset__c = l2snToId.get(chainSns[1].trim());
        }
        
        AssetTriggerHandler.skipProcessing();
        UPDATE assetsToParent;
    }
    
    private Map<String, String> getL2map(Set<String> l2sns) {
        Map<String, String> l2snToId = new Map<String, String>();
        if (l2sns.isEmpty()) {
            return l2snToId;
        }
        for (Asset t : [SELECT Id, 
                        	   SerialNumber 
                        FROM   Asset 
                        WHERE  SerialNumber IN :l2sns 
                        AND    MS_FSM_LGen_SN_Short_Form__c = :topLgen]) {
            l2snToId.put(t.SerialNumber, t.Id);
        }
        return l2snToId;
    }
}