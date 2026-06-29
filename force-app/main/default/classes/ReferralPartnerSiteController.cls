/**
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 * Class Name      : ReferralPartnerSiteController
 * Author          : <YourName>
 * Created Date    : May 29, 2026
 * Last Modified By: <YourName>
 * Last Modified On: May 29, 2026
 * Description     : This class implements for......
 *  
 * Change History  :
 *  Date          │   Author     │   Change
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 *  May 29, 2026  │ <YourName>   │ Initial version
 * ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
 */
public with sharing class ReferralPartnerSiteController {

    @AuraEnabled(cacheable=true)
    public static List<QuestionWrapper> getQuestions() {

        List<QuestionWrapper> result = new List<QuestionWrapper>();

        for(Partner_Application_Qus__mdt q : [

            SELECT Questions__c,
                   Question_Number__c,
                   Label

            FROM Partner_Application_Qus__mdt
            ORDER BY Question_Number__c

        ]) {

            result.add(new QuestionWrapper(
                q.Questions__c,
                q.Question_Number__c,
                q.Label
            ));
        }

        return result;
    }

    public class QuestionWrapper {

        @AuraEnabled public String question;
        @AuraEnabled public String qusnumber;
        @AuraEnabled public String Label;
       

        public QuestionWrapper(
            String question,
            String qusnumber,
            String Label
        ) {
            this.question = question;
            this.qusnumber = qusnumber;
            this.Label = Label;
        }
    }
}