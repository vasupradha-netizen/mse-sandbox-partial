trigger MS_FSM_AssetStagingTrigger on MS_FSM_EtaHub_Asset_Staging__c (before insert, after insert) {
    MS_FSM_AssetStagingTriggerHandler.mainEntry(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.new);
}