@isTest
public class BusinessHoursHelperTest {

    @testSetup
    static void setupTestData() {
        // In test setup, we assume that default Business Hours already exists in the org, so no need to insert it
        // We retrieve it in the test methods instead
    }

    @isTest
    static void testBusinessHoursCalculation() {
        // Retrieve the default Business Hours for testing
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        // Test when start and end date times are within business hours
        List<BusinessHoursHelper.Request> requests = new List<BusinessHoursHelper.Request>();

        BusinessHoursHelper.Request req1 = new BusinessHoursHelper.Request();
        req1.startDateTime = Datetime.newInstance(2024, 9, 11, 10, 0, 0); // Within business hours
        req1.endDateTime = Datetime.newInstance(2024, 9, 11, 12, 0, 0); // Within business hours

        BusinessHoursHelper.Request req2 = new BusinessHoursHelper.Request();
        req2.startDateTime = Datetime.newInstance(2024, 9, 12, 16, 0, 0); // 1 hour before end of business hours
        req2.endDateTime = Datetime.newInstance(2024, 9, 13, 10, 0, 0); // Spans into the next day

        requests.add(req1);
        requests.add(req2);

        // Call the invocable method
        Test.startTest();
        List<Decimal> results = BusinessHoursHelper.calculateBusinessHoursDifference(requests);
        Test.stopTest();

        // Validate the results
        System.assertEquals(2, results.size());
        System.assertEquals(2.00, results[0], 'First request should return 2 hours');
        System.assertEquals(2.00, results[1], 'Second request should return 2 hours of business time');
    }

    @isTest
    static void testWithNullDateTimes() {
        // Retrieve the default Business Hours for testing
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        // Test when start and end date times are null
        List<BusinessHoursHelper.Request> requests = new List<BusinessHoursHelper.Request>();

        BusinessHoursHelper.Request req1 = new BusinessHoursHelper.Request();
        req1.startDateTime = null;
        req1.endDateTime = Datetime.newInstance(2024, 9, 11, 10, 0, 0); 

        BusinessHoursHelper.Request req2 = new BusinessHoursHelper.Request();
        req2.startDateTime = Datetime.newInstance(2024, 9, 11, 10, 0, 0);
        req2.endDateTime = null;

        requests.add(req1);
        requests.add(req2);

        // Call the invocable method
        Test.startTest();
        List<Decimal> results = BusinessHoursHelper.calculateBusinessHoursDifference(requests);
        Test.stopTest();

        // Validate the results
        System.assertEquals(2, results.size());
        System.assertEquals(0, results[0], 'First request should return 0 because start time is null');
        System.assertEquals(0, results[1], 'Second request should return 0 because end time is null');
    }

    @isTest
    static void testBusinessHoursOutsideWorkingHours() {
        // Retrieve the default Business Hours for testing
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];

        // Test when start and end date times are outside business hours
        List<BusinessHoursHelper.Request> requests = new List<BusinessHoursHelper.Request>();

        BusinessHoursHelper.Request req1 = new BusinessHoursHelper.Request();
        req1.startDateTime = Datetime.newInstance(2024, 9, 11, 18, 0, 0); // Outside business hours
        req1.endDateTime = Datetime.newInstance(2024, 9, 11, 19, 0, 0); // Still outside business hours

        requests.add(req1);

        // Call the invocable method
        Test.startTest();
        List<Decimal> results = BusinessHoursHelper.calculateBusinessHoursDifference(requests);
        Test.stopTest();

        // Validate the results
        System.assertEquals(1, results.size());
        System.assertEquals(0, results[0], 'Request should return 0 because times are outside business hours');
    }
}