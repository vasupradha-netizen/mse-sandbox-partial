@isTest
private class CustomerDbTests {
    
    @TestSetup
    static void setup() {
        String pid = [SELECT Id FROM Profile WHERE Name  = 'System Administrator' LIMIT 1].Id;
        String rid = [SELECT Id FROM UserRole WHERE Name = 'Executive' LIMIT 1].Id;
        
        User e = new User(
        	EmailEncodingKey 	= 'UTF-8',
            TimeZoneSidKey		= 'America/Los_Angeles',
            LanguageLocaleKey	= 'en_US',
            LocaleSidKey		= 'en_US',
            LastName 			= 'execlast',
            FirstName 			= 'execfirst',
            Email				= 'exec@fake.mainspringcustomerdashboard',
            Username			= 'exec@fake.mainspringcustomerdashboard',
            Alias				= 'execuser',
            UserRoleId			= rid,
            ProfileId			= pid
        );
        INSERT e;
    }
    
    @isTest
    static void standard() {
        
        Account a = new Account(
        	Name 	= 'test',
            OwnerId = [SELECT Id FROM User WHERE LastName = 'execlast' LIMIT 1].Id
        );
        INSERT a;
        
        Contact c = new Contact(
        	AccountId 	= a.Id,
            LastName 	= 'testlast',
            FirstName 	= 'testfirst',
            Email		= 'test@fake.mainspringcustomerdashboard'
        );
        INSERT c;
        
        Customer_Dashboard_Setting__c s = new Customer_Dashboard_Setting__c(
        	Name 			= 'test',
            Project_Id__c 	= 'test',
            Public__c 		= true
        );
        INSERT s;
        
        String pid = [SELECT Id FROM Profile WHERE Name = 'Customer Dashboard' LIMIT 1].Id;
        
        User u = new User(
        	ContactId 			= c.Id,
            ProfileId 			= pid,
            EmailEncodingKey 	= 'UTF-8',
            TimeZoneSidKey		= 'America/Los_Angeles',
            LanguageLocaleKey	= 'en_US',
            LocaleSidKey		= 'en_US',
            LastName 			= 'testlast',
            FirstName 			= 'testfirst',
            Email				= 'test@fake.mainspringcustomerdashboard',
            Username			= 'test@fake.mainspringcustomerdashboard',
            Alias				= 'testuser'
        );
        INSERT u;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CustomerDbMock());
        System.runAs(u) {
            CustomerDbTocController.getSettings();
            CustomerDbViewerController.getUrl(s.Id);
        }
        Test.stopTest();
    }
}