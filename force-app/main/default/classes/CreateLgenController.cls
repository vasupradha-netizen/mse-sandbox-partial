public class CreateLgenController {
    
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> checkSerial(String spid) {
        Map<String, Object> r = new Map<String, Object>();
        String sn = [SELECT SerialNumber FROM SerializedProduct WHERE Id = :spid].SerialNumber;
        
        Boolean found 	= false;
        String 	f 		= '{12.EX.' + sn + '}';
        String  table   = '';
        
        for (MS_FSM_EtaHub_Integration_Definition__c d : [SELECT MS_FSM_EH_Column_Number__c,
                                                          		 MS_FSM_Target_Field__c,
                                                          		 MS_FSM_Data_Type__c,
                                                          		 MS_FSM_EH_Table_Id__c
                                                          FROM 	 MS_FSM_EtaHub_Integration_Definition__c
                                                          WHERE  MS_FSM_EH_Column_Number__c = '12'
                                                          AND    (MS_FSM_EH_Table_Id__c = 'brv5unzwf' OR  MS_FSM_EH_Table_Id__c = 'bnnfe2qf9')]) 
        {
            if (!found) {
                found = !MS_FSM_EHINT_Utils.getEHData(new List<MS_FSM_EtaHub_Integration_Definition__c>{d}, f, 0, 0).isEmpty();
                table = found ? d.MS_FSM_EH_Table_Id__c : '';
            }
        }
        r.put('serial', sn);
		r.put('found',  found);
        r.put('table',  table);
        return r;
    }
    
    @AuraEnabled(cacheable=false)
    public static String buildLgen(String spid, String sn, String tid) {
        try {
            UPDATE new SerializedProduct(Id = spid, LGen_Requested__c = true, LGen_Requester_Email__c = UserInfo.getUserEmail());
            
            String f = '{12.EX.' + sn + '}';
            
            if (tid == 'bnnfe2qf9') {
                MS_FSM_EHINT_GetAssemblies j = new MS_FSM_EHINT_GetAssemblies();
                j.filterOverride = f;
                System.enqueueJob(j);
            }
            if (tid == 'brv5unzwf') {
                MS_FSM_EHINT_GetCMAssemblies j = new MS_FSM_EHINT_GetCMAssemblies();
                j.filterOverride = f;
                System.enqueueJob(j);
            }
        } catch (Exception ex) {
            return ex.getMessage();
        }
        return 'SUCCESS';
    }
}