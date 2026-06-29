public class ScorecardSnapshotSched implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ScorecardSnapshotBatch('Account'));
    }
}