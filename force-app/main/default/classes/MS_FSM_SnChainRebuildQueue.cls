// STEP 2 of 2 -- see MS_FSM_SnChainRebuildSched for full description
public class MS_FSM_SnChainRebuildQueue implements Queueable {

    private Integer 		index;
    private List<String> 	topIds;
    private Set<String> 	parents;
    
    private Asset			topAsset;
    private Map<Id, Asset>  parentAssets;
    private List<Asset>		children;
    
    private Set<String>     	nextParents;
    private Set<String>			l2serials;
    private Map<String, String> l2Map;
    
    public MS_FSM_SnChainRebuildQueue(Integer i, List<String> tids, Set<String> pids) {
        index 	= i;
        topIds 	= tids;
        parents = pids ?? new Set<String>{topIds[index]};
    }
    
    public void execute(QueueableContext qc) {
        getTopAsset();
        getParents();
        getChildren();
        applySnChain();
        getL2();
        applyL2();
        updates();
        nextJob();
    }
    
    private void getTopAsset() {
        topAsset = [SELECT Id, MS_FSM_LGen_SN_Short_Form__c FROM Asset WHERE Id = :topIds[index]];
    }
    
    private void getParents() {
        parentAssets = new Map<Id, Asset>([SELECT Id, SerialNumber, MS_FSM_Serial_Chain__c FROM Asset WHERE Id IN :parents]);
    }
    
    private void getChildren() {
       	children = [SELECT Id, ParentId FROM Asset WHERE ParentId IN :parents];
    }
    
    private void applySnChain() {
        l2serials 	= new Set<String>();
        nextParents = new Set<String>();
        for (Asset t : children) {
            Asset p = parentAssets.get(t.ParentId);
            if (p == null) {
                continue;
            }
            
            String s = p.SerialNumber;
            String c = p.MS_FSM_Serial_Chain__c;
            
            t.MS_FSM_Serial_Chain__c 		= String.isBlank(c) ? s : (c + ', ' + s);
            t.MS_FSM_Lgen_SN_Short_Form__c 	= topAsset.MS_FSM_LGen_SN_Short_Form__c;
            
            nextParents.add(t.Id);
            l2serials.add(getL2sn(t));
        }
    }
    
    private void getL2() {
        l2Map = new Map<String, String>();
        if (l2serials.isEmpty()) {
            return;
        }
        for (Asset t : [SELECT 	Id, 
                        		SerialNumber 
                        FROM 	Asset 
                        WHERE 	SerialNumber IN :l2serials
                        AND     SerialNumber != ''
                        AND 	MS_FSM_Lgen_SN_Short_Form__c = :topAsset.MS_FSM_LGen_SN_Short_Form__c]) 
        {
        	l2Map.put(t.SerialNumber, t.Id);    
        }
    }
    
    private void applyL2() {
        if (l2Map.values().isEmpty()) {
            return;
        }
        for (Asset t : children) {
            t.MS_FSM_L2_Asset__c = l2Map.get(getL2sn(t));
        }
    }
    
    private void updates() {
        AssetTriggerHandler.skipProcessing();
        UPDATE children;
    }
    
    private void nextJob() {
        if (Test.isRunningTest()) {
            return;
        }
        if (nextParents.isEmpty()) {
            index++;
            if (index < topIds.size()) {
                System.enqueueJob(new MS_FSM_SnChainRebuildQueue(index, topIds, null));
            }
        } else {
         	System.enqueueJob(new MS_FSM_SnChainRebuildQueue(index, topIds, nextParents));
        }
    }
    
    private String getL2sn(Asset t) {
        List<String> sns = t.MS_FSM_Serial_Chain__c.split(',');
        if (sns.size() < 2) {
            return '';
        }
        return sns[1].trim();
    }
}