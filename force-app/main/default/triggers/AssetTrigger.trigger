trigger AssetTrigger on Asset (after insert, after update) {
    AssetTriggerHandler.mainEntry(Trigger.isBefore, Trigger.isAfter, Trigger.isInsert, Trigger.isUpdate, Trigger.isDelete, Trigger.new, Trigger.oldMap);
}