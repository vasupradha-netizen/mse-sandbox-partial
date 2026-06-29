public class MS_FSM_PredictiveMaintenanceBatch implements Database.Batchable<MS_FSM_PredictiveMaintenanceBatch.RootAssetFamilies>, Database.Stateful {

    public class RootAssetFamilies {
        public Id 			rootAssetId;
        public Set<String> 	productFamilies;
        public RootAssetFamilies(Id rootId, Set<String> families) {
            rootAssetId 	= rootId;
            productFamilies = families;
        }
    }

    private List<RootAssetFamilies> scope;

    public MS_FSM_PredictiveMaintenanceBatch(List<RootAssetFamilies> rootFamiliesList) {
        scope = rootFamiliesList;
    }

    public Iterable<RootAssetFamilies> start(Database.BatchableContext bc) {
        return scope;
    }

    public void execute(Database.BatchableContext bc, List<RootAssetFamilies> batchScope) {
        for (RootAssetFamilies pair : batchScope) {
            MS_FSM_PredictiveMaintenance j = new MS_FSM_PredictiveMaintenance(pair.rootAssetId, pair.productFamilies);
            j.execute();
        }
    }

    public void finish(Database.BatchableContext bc) { /* DO NOTHING */ }
}