trigger OpportunityTrigger on Opportunity (before insert,
                                           after  insert,
                                           before update,
                                           after  update,
                                           before delete,
                                           after  delete) 
{
	OpportunityTriggerHandler.mainEntry(Trigger.isBefore,
                                        Trigger.isAfter,
                                        Trigger.isInsert,
                                        Trigger.isUpdate,
                                        Trigger.isDelete,
                                        Trigger.new,
                                        Trigger.oldMap);
}