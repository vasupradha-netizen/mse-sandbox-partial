/** 
 * DaizyLogik 2023
 * Class to test controller that supports the page component that shows the paused interviews for an Opportunity
*/
@isTest
private class TestInterviewsByRecordController {
    @isTest
    static void testInterviewsByRecordController() {
        Contact c = new Contact(FirstName='Test', LastName='Test');
        insert c;
        test.startTest();
            List<FlowRecordRelation> interviews = InterviewsByRecordController.getInterviews(c.id);
            System.assert(interviews.size() == 0);
            System.assert(InterviewsByRecordController.deleteInterview(null) == null);
        test.stopTest();    
    }
}