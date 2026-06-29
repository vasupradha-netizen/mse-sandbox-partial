@isTest
private class MeterEmailHelperTest {
    @isTest
    static void testSendEmailNotification() {
        // Call the method with dummy values
        MeterEmailHelper.sendEmailNotification(
            Id.valueOf('001000000000000AAA'),
            new List<String>{'Test change'}
        );

        // No assertions needed for placeholder
    }
}