/******************************************************************************
 * Name         : MS_FSM_AssetSubtreeHelper
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2025-02-01
 * Description  : static helper class for subtree builds
 *
 * Modification History:
 *   Date       | Author           	  | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-02-01 | Nathan Ehrmann      | Initial write for core swaps / subtree builds.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_AssetSubtreeTests
 ******************************************************************************/
public class MS_FSM_AssetSubtreeHelper {
    
	/********************************************************
	 * Purpose: determine if a newly installed Asset qualifies
	 * 			for a subtree / hierarchy build based on
	 * 		    attributes from a matched Serialized Product
	 *          based on Product Code + Serial Number.
	 *          the build hierarchy attribute is synced from
	 *          EtaHub in our 15-minute inventory syncs.
	 * Input:	ats = list of qualified Assets (based on transaction)
	 * 			from AssetTriggerHandler
	 * Output:	! none ! - qualifying records will be sent 
	 * 			to SCHEDULED APEX (+1 minute)
	 ********************************************************/
    public static void getSubtreeQualified(List<Asset> ats) {
        if (ats.isEmpty()) {
            return;
        }
        
        List<String> r  = new List<String>();
        Set<String> aid = new Set<String>();
        Set<String> sns = new Set<String>();
        Set<String> prs = new Set<String>();
        
        for (Asset a : ats) {
            sns.add(a.SerialNumber);
            prs.add(a.Product2Id);
            aid.add(a.Id);
        }
        
        Set<String> coveredKeys = new Set<String>();
        for (Asset a : [SELECT SerialNumber, Product2Id 
                        FROM   Asset 
                        WHERE  Id NOT IN :aid 
                        AND    SerialNumber IN :sns
                        AND    Product2Id IN :prs]) {
            coveredKeys.add(a.Product2Id + a.SerialNumber);
        }
        
        Set<String> qsn = new Set<String>();
        for (SerializedProduct s : [SELECT 	Id, SerialNumber, Product2Id
                                    FROM 	SerializedProduct
                                    WHERE 	MS_FSM_Build_Hierarchy__c = true
                                    AND     SerialNumber IN :sns
                                    AND		Product2Id IN :prs]) 
        {
            qsn.add(s.Product2Id + s.SerialNumber);
        }
        
        for (Asset a : ats) {
            String k = a.Product2Id + a.SerialNumber;
            if (!coveredKeys.contains(k) && qsn.contains(k)) {
                r.add(a.Id);
            }
        }
        
        if (r.isEmpty()) {
            return;
        }
        
        DateTime 	p = System.now().addMinutes(1);
        String 		c = p.second() + ' ' + p.minute() + ' ' + p.hour() + ' ' + p.day() + ' ' + p.month() + ' ? ' + p.year();
        System.schedule('Asset Subtree Build - ' + String.valueOf(p) + ' - ' + r[0], c, new MS_FSM_AssetSubtreeSched(r));
    }
    
    /********************************************************
	 * Purpose: to assist in our later parenting process, we apply
	 * 			the subtree-qualified Asset's SerialNumber to the
	 * 			LGen Short Form field, which is usually used by our
	 * 		    overnight EH build sync.
	 * 			this temporarily assists with parenting, and is later
	 * 			overwritten by our SnChainRebuild jobs.
	 * Input:	aids = Asset Ids
	 * Output:	! none ! - this just performs an update
	 ********************************************************/
    public static void applySnToLgen(List<String> aids) {
        List<Asset> ats = [SELECT Id, SerialNumber
                           FROM   Asset
                           WHERE  Id IN :aids];
        for (Asset a : ats) {
            a.MS_FSM_LGen_SN_Short_Form__c = a.SerialNumber;
        }
        AssetTriggerHandler.skipProcessing();
        UPDATE ats;
    }
}