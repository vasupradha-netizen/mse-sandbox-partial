public class WorkOrderLineItemNetsuiteBatch implements Database.Batchable<sObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, 
            MS_FSM_Installed_Asset__r.MS_FSM_Netsuite_Id__c, MS_FSM_Removed_Asset__r.MS_FSM_Netsuite_Id__c, 
            MS_FSM_Installed_Asset_Netsuite_Id__c, MS_FSM_Removed_Asset_Netsuite_Id__c 
            FROM WorkOrderLineItem 
            where MS_FSM_Installed_Asset__c <> NULL 
            or MS_FSM_Removed_Asset__c <> NULL
        ]);
    }

	public void execute(Database.BatchableContext bc, List<WorkOrderLineItem> scope) {

        List<WorkOrderLineItem> updates = new List<WorkOrderLineItem>();
        
        for (WorkOrderLineItem woli : scope) {
            boolean update_flag = false;
            
            if (woli.MS_FSM_Installed_Asset__c != null) {
                String sourceInstallNetsuiteId = woli.MS_FSM_Installed_Asset__r.MS_FSM_Netsuite_Id__c;
                if (woli.MS_FSM_Installed_Asset_Netsuite_Id__c != sourceInstallNetsuiteId) {
                    woli.MS_FSM_Installed_Asset_Netsuite_Id__c = sourceInstallNetsuiteId;
                    update_flag = true;
                }
            }
            
            if (woli.MS_FSM_Removed_Asset__c != null) {
                String sourceRemovedNetsuiteId = woli.MS_FSM_Removed_Asset__r.MS_FSM_Netsuite_Id__c;
                if (woli.MS_FSM_Removed_Asset_Netsuite_Id__c != sourceRemovedNetsuiteId) {
                    woli.MS_FSM_Removed_Asset_Netsuite_Id__c = sourceRemovedNetsuiteId;
                    update_flag = true;
                }
            }
            if(update_flag){
                updates.add(woli);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Success: All Work Orders have been processed.');
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new WorkOrderLineItemNetsuiteBatch());
    }
}