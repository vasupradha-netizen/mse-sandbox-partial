/** 
 * DaizyLogik 2023
 * Class to support the page component that shows the paused interviews for an Opportunity
*/
public class InterviewsByRecordController {

    @AuraEnabled
    public static List<FlowRecordRelation> getInterviews(Id recordId) {
        return [ SELECT 
                    ParentId, Parent.InterviewLabel, Parent.PauseLabel, 
                    Parent.CurrentElement, Parent.CreatedDate, Parent.Owner.Name 
                FROM FlowRecordRelation 
                WHERE RelatedRecordId = :recordId ];
    }

    @AuraEnabled
    public static FlowInterview deleteInterview(Id interviewId) {
        FlowInterview interview;
        List<FlowInterview> interviews = [Select Id from FlowInterview Where Id = :interviewId limit 1];
        if (!interviews.isEmpty()) {
            interview = interviews[0];
            delete interview;
        }
        return interview;
    }
}