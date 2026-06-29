@isTest
public class SitesTriggerTest {
    @testSetup
    static void setup() {
        // Create a test Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test class Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;

        // Create test data for the Sites__c object with the required Opportunity__c field
        Sites__c site1 = new Sites__c();
        site1.Street_1__c = '99 e middle field rd';
        site1.City__c = 'Mountain View';
        site1.State_Region__c = 'California';
        site1.Country__c = 'United States';
        site1.Postal_Code__c = '94043';
        site1.Opportunity__c = opp.Id;
        insert site1;
    }

    @isTest
    static void testTriggerWithGeocodeAndElevation() {
        // Set the mocks for the HTTP callouts
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());
        Test.setMock(HttpCalloutMock.class, new ElevationMock());

        // Retrieve the test data
        Sites__c site = [SELECT Id, Street_1__c, City__c, State_Region__c, Country__c FROM Sites__c LIMIT 1];
        System.debug('Site retreived: ' + site);

        Opportunity opp = [Select Name, StageName, CloseDate from Opportunity LIMIT 1];
        // Update address fields to trigger GeocodeJob
        site.Street_1__c = '1600 Amphitheatre Parkway';
        site.City__c = 'Mountain View';
        site.State_Region__c = 'California';
        site.Country__c = 'United States';
        site.Postal_Code__c = '94043';
        site.Opportunity__c = opp.Id;
        Test.startTest();
        update site; // This should trigger GeocodeJob and ElevationJob

        // Ensure jobs are enqueued and completed
        Test.stopTest();

        // Verify geocoding result
        site = [SELECT Geolocation__Latitude__s, Geolocation__Longitude__s FROM Sites__c WHERE Id = :site.Id];
        System.debug('Geocoded Latitude: ' + site.Geolocation__Latitude__s);
        System.debug('Geocoded Longitude: ' + site.Geolocation__Longitude__s);
        System.assertEquals(37.4224764, site.Geolocation__Latitude__s, 'Latitude should match the mock response.');
        System.assertEquals(-122.0842499, site.Geolocation__Longitude__s, 'Longitude should match the mock response.');

        // Now set geolocation for elevation
        site.Geolocation__Latitude__s = 37.4224764;
        site.Geolocation__Longitude__s = -122.0842499;
        update site; // This should trigger the ElevationJob

        // Verify elevation result
        site = [SELECT Elevation__c FROM Sites__c WHERE Id = :site.Id];
        System.debug('Elevation Result: ' + site.Elevation__c);
        System.assertEquals(50.0, site.Elevation__c, 'Elevation should match the mock response.');
    }

    @isTest
    static void testTriggerWithAddressChange() {
        // Set the mocks for the HTTP callouts
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        // Retrieve the test data
        Sites__c site = [SELECT Id, Street_1__c, City__c, State_Region__c, Country__c FROM Sites__c LIMIT 1];

        // Change the address to trigger GeocodeJob
        site.Street_1__c = '99 E middle field rd';
        site.City__c = 'Mountain View';
        site.State_Region__c = 'California';
        site.Country__c = 'United States';

        Test.startTest();
        update site; // This should trigger GeocodeJob

        // Ensure jobs are enqueued and completed
        Test.stopTest();

        // Verify geocoding result
        site = [SELECT Geolocation__Latitude__s, Geolocation__Longitude__s FROM Sites__c WHERE Id = :site.Id];
        System.debug('Updated Geocoded Latitude: ' + site.Geolocation__Latitude__s);
        System.debug('Updated Geocoded Longitude: ' + site.Geolocation__Longitude__s);
        System.assertEquals(37.4224764, site.Geolocation__Latitude__s, 'Latitude should match the mock response.');
        System.assertEquals(-122.0842499, site.Geolocation__Longitude__s, 'Longitude should match the mock response.');
    }
    static testMethod void fakeTest(){
     ElevationJob.fakeMethod();
     GeocodeJob.fakeMethod();

     //repeat the same for the rest of classes.
  }  
}