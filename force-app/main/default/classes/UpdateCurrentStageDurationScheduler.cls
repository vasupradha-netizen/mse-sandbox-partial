/*
// Schedule the job to run every hour
String cronExp = '0 0 * * * ?';  // Every hour at the top of the hour
System.schedule('Update Current Stage Duration', cronExp, new UpdateCurrentStageDurationScheduler());
*/
global class UpdateCurrentStageDurationScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        // Call the batch class to update the stage duration
        UpdateCurrentStageDurationBatch batch = new UpdateCurrentStageDurationBatch();
        Database.executeBatch(batch, 200); // Run the batch with a scope of 200 records at a time
    }
}