public class StageTimeCalculatorBatch implements Database.Batchable<sObject> {
    
    private Id bhId;
    private final Set<String> trackedStages = new Set<String>{'To Do', 'Ready for Analysis', 'Analysis', 'Validation'};
    private final Set<String> reviewAndFinalStages = new Set<String>{
        'Ready for Review', 'In Review', 'Finalize Proposal', 
        'Proposal Check', 'Ready for Dispatch', 'Released', 'Dormant'
    };
    private final String RESET_STAGE = 'Info Needed'; 
    private final String INITIAL_STAGE = 'To Do';

    @TestVisible private List<StageHistory> mockedHistory;

    public StageTimeCalculatorBatch() {
        this.bhId = getDefaultBusinessHoursId();
    }

    public class StageHistory {
        public String newValue;
        public Datetime createdDate;
        public StageHistory(String nv, Datetime cd) {
            this.newValue = nv;
            this.createdDate = cd;
        }
    }

    private Id getDefaultBusinessHoursId() {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        return (bh != null) ? bh.Id : null;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, CreatedDate, Stage__c,
                (SELECT NewValue, CreatedDate FROM Histories WHERE Field = 'Stage__c' ORDER BY CreatedDate ASC)
            FROM Analytics_Model__c
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Analytics_Model__c> scope) {
        List<Analytics_Model__c> recordsToUpdate = new List<Analytics_Model__c>();
        for(Analytics_Model__c record : scope) {
            processSingleRecord(record, recordsToUpdate);
        }
        if(!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }

    private void processSingleRecord(Analytics_Model__c record, List<Analytics_Model__c> updateList) {
        Long totalTrackedMillis = 0;
        String currentStage = INITIAL_STAGE; 
        
        // Use CreatedDate if available, otherwise fallback to Now (safety for tests)
        Datetime lastStageChangeDate = (record.CreatedDate != null) ? record.CreatedDate : System.now();
        Boolean hasReachedAdvancedStage = false; 
        
        String log = initializeLog(record);
        
        List<StageHistory> historyList = new List<StageHistory>();
        if (Test.isRunningTest() && mockedHistory != null) {
            historyList = mockedHistory;
        } else if (record.Histories != null) {
            for(Analytics_Model__History h : record.Histories) {
                historyList.add(new StageHistory((String)h.NewValue, h.CreatedDate));
            }
        }
        
        for(StageHistory hist : historyList) {
            String newVal = hist.newValue;
            Datetime historyDate = hist.createdDate;

            if(isTrackingRequired(currentStage)) {
                Long diff = calculateTimeDiff(lastStageChangeDate, historyDate);
                totalTrackedMillis += diff;
                log = appendLogEntry(log, currentStage, lastStageChangeDate, historyDate, diff);
            }

            if(reviewAndFinalStages.contains(currentStage)) {
                hasReachedAdvancedStage = true;
            }

            if(newVal == RESET_STAGE || (hasReachedAdvancedStage && isTrackingRequired(newVal))) {
                totalTrackedMillis = 0;
                log += '*** RESET: Regression/Info Needed from [' + currentStage + '] to [' + newVal + ']. ***\n';
                hasReachedAdvancedStage = false; 
            }

            currentStage = newVal;
            lastStageChangeDate = historyDate;
        }

        if(isTrackingRequired(currentStage)) {
            Long finalDiff = calculateTimeDiff(lastStageChangeDate, System.now());
            totalTrackedMillis += finalDiff;
            log = appendLogEntry(log, currentStage, lastStageChangeDate, System.now(), finalDiff);
        }

        record.KD_Testing_TTR__c = convertMillisToHours(totalTrackedMillis);
        record.KD_Testing_TTR_Notes__c = finalizeLog(log, record.KD_Testing_TTR__c);
        updateList.add(record);
    }

    private Boolean isTrackingRequired(String stageName) { return trackedStages.contains(stageName); }
    
    private Long calculateTimeDiff(Datetime startDt, Datetime endDt) {
        if(bhId == null || startDt == null || endDt == null) return 0;
        return BusinessHours.diff(bhId, startDt, endDt);
    }
    
    private Decimal convertMillisToHours(Long millis) {
        return (millis == null || millis == 0) ? 0.00 : Decimal.valueOf(millis).divide(3600000, 2, System.RoundingMode.HALF_UP);
    }
    
    private String initializeLog(Analytics_Model__c rec) {
        String createdStr = (rec.CreatedDate != null) ? rec.CreatedDate.format() : 'Unknown';
        return 'Start (Created: ' + createdStr + ')\nInitial: ' + INITIAL_STAGE + '\n';
    }
    
    private String appendLogEntry(String log, String stage, Datetime startDt, Datetime endDt, Long diff) {
        return log + 'Stage [' + stage + '] ' + startDt.format() + ' to ' + endDt.format() + ': ' + convertMillisToHours(diff) + ' hrs.\n';
    }
    
    private String finalizeLog(String log, Decimal total) {
        String res = log + '\nFINAL: ' + total + ' hours.';
        return (res.length() > 32000) ? res.substring(res.length() - 32000) : res;
    }

    public void finish(Database.BatchableContext BC) {}
}