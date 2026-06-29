public without sharing class CustomerDbTocController {

    @AuraEnabled(cacheable=true)
    public static List<Customer_Dashboard_Setting__c> getSettings() {
        User u = getUser();
        if (u == null) {
            return new List<Customer_Dashboard_Setting__c>();
        }
        return [SELECT 	Id, 
                		Name
                FROM   	Customer_Dashboard_Setting__c
                WHERE  	Public__c = true
                OR     	Id IN :getPermedDbs(u)];
    }
    
    private static User getUser() {
        return [SELECT ProfileId, Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()];
    }
    
    private static Set<String> getPermedDbs(User u) {
        Set<String> dbsids = new Set<String>();
        for (Customer_Dashboard_Permission__c p : [SELECT 	Customer_Dashboard_Setting__c 
                                                   FROM 	Customer_Dashboard_Permission__c
                                                   WHERE 	(Type__c = 'Profile' AND Value__c = :u.ProfileId)
                                                   OR    	(Type__c = 'Account' AND Value__c = :u.Contact.AccountId)]) 
        {
        	dbsids.add(p.Customer_Dashboard_Setting__c);
        }
        return dbsids;
    }
}