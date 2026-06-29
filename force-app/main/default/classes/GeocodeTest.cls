@isTest
private class GeocodeTest {

    @TestSetup
    static void setup() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());
        
        Opportunity opp = new Opportunity(
            Name 		= 'Test class Opportunity',
            StageName 	= 'Prospecting',
            CloseDate 	= Date.today().addDays(30)
        );
        INSERT opp;

        INSERT new Sites__c(
        	Street_1__c 	= '99 e middle field rd',
            City__c 		= 'Mountain View',
            State_Region__c = 'California',
            Country__c 		= 'United States',
            Postal_Code__c 	= '94043',
            Opportunity__c 	= opp.Id
        );
    }

    @isTest
    static void testInsert() {
        Sites__c site = [SELECT Geolocation__Latitude__s, Geolocation__Longitude__s, Elevation__c FROM Sites__c LIMIT 1];

        System.assertEquals(37.4224764, 	site.Geolocation__Latitude__s, 	'Latitude should match the mock response.');
        System.assertEquals(-122.0842499, 	site.Geolocation__Longitude__s, 'Longitude should match the mock response.');
        System.assertEquals(100, 			site.Elevation__c, 				'Elevation should match the mock response.');
    }
}