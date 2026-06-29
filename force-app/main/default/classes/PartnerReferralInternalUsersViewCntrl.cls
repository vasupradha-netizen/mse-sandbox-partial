/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : PartnerReferralInternalUsersViewCntrl
 * Author          : <YourName>
 * Created Date    : Jun 25, 2026
 * Last Modified By: <YourName>
 * Last Modified On: Jun 25, 2026
 * Description     : This class implements for the internal users view for Partner Application
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  Jun 25, 2026  │ Exafort  │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */

public with sharing class PartnerReferralInternalUsersViewCntrl {

@AuraEnabled(cacheable=true)
    public static SObject getApplicationData(Id recordId) {
        String objectName = recordId.getSObjectType().getDescribe().getName();
        
        String query = 'SELECT ' + 
            String.join(new List<String>(Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().keySet()), ',') + 
            ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1';
            
        return Database.query(query);
    }
}