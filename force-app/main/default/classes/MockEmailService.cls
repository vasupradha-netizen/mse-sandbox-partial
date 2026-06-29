@isTest
public class MockEmailService {
    private static List<Messaging.SingleEmailMessage> sentEmails = new List<Messaging.SingleEmailMessage>();

    public static void captureEmail(Messaging.SingleEmailMessage email) {
        sentEmails.add(email);
    }

    public static List<Messaging.SingleEmailMessage> getCapturedEmails() {
        return sentEmails;
    }

    public static void clearEmails() {
        sentEmails.clear();
    }
}