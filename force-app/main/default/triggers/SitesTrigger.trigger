trigger SitesTrigger on Sites__c (after insert, after update) {
    
    SitesTriggerHandler.mainEntry(Trigger.isBefore,
                                  Trigger.isAfter,
                                  Trigger.isInsert,
                                  Trigger.isUpdate,
                                  Trigger.isDelete,
                                  Trigger.new,
                                  Trigger.oldMap);
}