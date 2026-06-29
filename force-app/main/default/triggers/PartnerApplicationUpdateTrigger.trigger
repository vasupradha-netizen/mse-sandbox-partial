trigger PartnerApplicationUpdateTrigger on Partner_Application_Update_Event__e (after insert) {
    
    if (Trigger.isAfter && Trigger.isInsert) {
        PartnerApplicationUpdateHandler.handleAfterInsert(Trigger.new);
    }
    
}