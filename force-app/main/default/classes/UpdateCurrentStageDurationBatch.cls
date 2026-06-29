global class UpdateCurrentStageDurationBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Define the query to get records that need stage duration updates
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id, Stage__c,Time_Spent_in_To_Do__c, Stage_Start_Time__c, Time_Spent_in_Info_Needed__c, Time_Spent_in_Ready_for_Review__c, ' +
            'Time_Spent_in_Ready_for_Analysis__c, Time_Spent_in_Analysis__c, Time_Spent_in_Validation__c ' +
            'FROM Analytics_Model__c ' +
            'WHERE Stage__c = \'To Do\' OR Stage__c = \'Info Needed\' OR Stage__c = \'Ready for Analysis\' OR Stage__c = \'Analysis\' OR Stage__c = \'Validation\' ' +
            'ORDER BY CreatedDate DESC'
        );
    }

    // Process each batch of records
    global void execute(Database.BatchableContext BC, List<Analytics_Model__c> records) {
        // Get the Business Hours ID (replace with your business hours ID)
        Id businessHoursId = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1].Id;

        List<Analytics_Model__c> recordsToUpdate = new List<Analytics_Model__c>();

        // Loop through each record to update the current stage duration
        for (Analytics_Model__c record : records) {
            // Calculate the current duration in the current stage
                DateTime now = DateTime.now();
                DateTime stageStartTime ;
                if(record.Stage__c == 'To Do'){
                    stageStartTime = record.Stage_Start_Time__c;
                    if(stageStartTime != null){
                    Long timeSpentInCurrentStage = BusinessHours.diff(businessHoursId, stageStartTime, now)/1000; // Time calculated in seconds
                    timeSpentInCurrentStage = timeSpentInCurrentStage/60; // Time calculated in minutes
                    record.Time_Spent_in_To_Do__c = timeSpentInCurrentStage/60;
                    recordsToUpdate.add(record);
                    }
                }
                else if(record.Stage__c == 'Info Needed'){
                    stageStartTime = record.Stage_Start_Time__c;
                    if(stageStartTime != null){
                    Long timeSpentInCurrentStage = BusinessHours.diff(businessHoursId, stageStartTime, now)/1000; // Time calculated in seconds
                    timeSpentInCurrentStage = timeSpentInCurrentStage/60; // Time calculated in minutes
                    record.Time_Spent_in_Info_Needed__c = timeSpentInCurrentStage/60;                   
                    recordsToUpdate.add(record);
                    }
                }
                else if(record.Stage__c == 'Ready for Analysis'){
                    stageStartTime = record.Stage_Start_Time__c;
                    if(stageStartTime != null){
                    Long timeSpentInCurrentStage = BusinessHours.diff(businessHoursId, stageStartTime, now)/1000; // Time calculated in seconds
                    timeSpentInCurrentStage = timeSpentInCurrentStage/60; // Time calculated in minutes
                    record.Time_Spent_in_Ready_for_Analysis__c = timeSpentInCurrentStage/60;                   
                    recordsToUpdate.add(record);
                    }
                }
                else if(record.Stage__c == 'Analysis'){
                    stageStartTime = record.Stage_Start_Time__c;
                    if(stageStartTime != null){
                    Long timeSpentInCurrentStage = BusinessHours.diff(businessHoursId, stageStartTime, now)/1000; // Time calculated in seconds
                    timeSpentInCurrentStage = timeSpentInCurrentStage/60; // Time calculated in minutes
                    record.Time_Spent_in_Analysis__c = timeSpentInCurrentStage/60;                   
                    recordsToUpdate.add(record);
                    }
                }
                 else if(record.Stage__c == 'Validation'){
                    stageStartTime = record.Stage_Start_Time__c;
                    if(stageStartTime != null){
                    Long timeSpentInCurrentStage = BusinessHours.diff(businessHoursId, stageStartTime, now)/1000; // Time calculated in seconds
                    timeSpentInCurrentStage = timeSpentInCurrentStage/60; // Time calculated in minutes
                    record.Time_Spent_in_Validation__c = timeSpentInCurrentStage/60;
                    recordsToUpdate.add(record);
                    }
                }

            }
             // Update the records with the new duration values
        if (!recordsToUpdate.isEmpty()) {
        system.debug('list size:' +recordsToUpdate.size());
            update recordsToUpdate;
        }

    }

    // Finish method
    global void finish(Database.BatchableContext BC) {
        // Optional: Send email notifications or logs when the batch finishes
    }
}