/**
 * Test class to provide test coverage for the MainspringCiceroQueueable and MainspringCiceroSchedulable
 * Created by DaizyLogik Nov 2023
 */
@isTest
public class TestMainspringCiceroQueueable {
    private static final String jsonError = '{"response": { "errors":[ "No geocoding results found for address"],"messages": [], "results": {"candidates": []}}}';

    @istest
    private static void testMainspringCiceroQueueable() {
        //create Site
       Opportunity opp = new Opportunity(Name ='Test', StageName = 'Initial Assessment', CloseDate=date.today()); 
       insert opp;
       Sites__c site = new Sites__c(Opportunity__c=opp.Id, Name='Test Site', Street_1__c='615 7th Ave', Active_Sale__c = true,
                                       City__c='Santa Cruz', State_Region__c='California', Postal_Code__c='95062');
       insert site;
       List<Sites__c> sites = [select id from Sites__c where id=:site.Id];
       Test.setMock(HttpCalloutMock.class, new MainspringCiceroMockImpl(jsonError));
       test.startTest();
            MainspringCiceroQueueable msq = new MainspringCiceroQueueable(sites, sites.size(), 0);
            System.enqueueJob(msq);
       test.stopTest();
       System.assertEquals(1, msq.numberOfSites);
    }

    @istest
    private static void testMainspringCiceroSchedulable() {
       Test.setMock(HttpCalloutMock.class, new MainspringCiceroMockImpl(jsonError));
       test.startTest();
            String cronExp ='0 48 * * * ?';
            String jobId = System.schedule('JobName', cronExp, new MainspringCiceroSchedulable());
       test.stopTest();     
       CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]; 
       System.assertNotEquals(null, String.valueOf(ct.NextFireTime));   
    }
}