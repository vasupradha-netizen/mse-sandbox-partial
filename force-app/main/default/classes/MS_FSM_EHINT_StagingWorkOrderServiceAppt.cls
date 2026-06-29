/******************************************************************************
 * Name         : MS_FSM_EHINT_StagingWorkOrderServiceAppt
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : once a Retrofit Work Order is created and settled, then we can
 * 				  create or update a Service Appointment
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_StagingWorkOrderServiceAppt implements Queueable {

    private String woid;
    private String woliid;
    private String ehId;
    
    public MS_FSM_EHINT_StagingWorkOrderServiceAppt(String e, String w, String l) {
        ehId   = e;
        woid   = w;
        woliid = l;
    }
    
    public void execute(QueueableContext qc) { 
    	WorkOrder wo = [SELECT Id,
                        	   Staging_Work_Order_Date__c,
                        	   Subject,
                        	   Location.MS_FSM_Location_Address__Street__s,
                        	   Location.MS_FSM_Location_Address__City__s,
                               Location.MS_FSM_Location_Address__StateCode__s,
                        	   Location.MS_FSM_Location_Address__PostalCode__s,
                               Location.MS_FSM_Location_Address__CountryCode__s,
                               (SELECT Duration, DurationType FROM WorkOrderLineItems)
                        FROM 	WorkOrder
                        WHERE 	Id = :woid];
        
        Decimal d = 0;
        for (WorkOrderLineItem woli : wo.WorkOrderLineItems) {
            if (woli.Duration == null) {
                continue;
            }
            d += (woli.DurationType == 'Hours' ? woli.Duration : woli.Duration / 60);
        }
        d = Math.min(8, d);
        
        List<ServiceAppointment> sas = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :wo.Id];
        if (!sas.isEmpty()) {
            UPDATE new ServiceAppointment(Id = sas[0].Id, Duration = d);
        } else {
            Date wodate = wo.Staging_Work_Order_Date__c;
            INSERT new ServiceAppointment(
                Subject 			= wo.Subject,
                DueDate 			= DateTime.newInstance(wodate < System.today() ? System.today() : wodate, Time.newInstance(17,0,0,0)),
                ParentRecordId 		= wo.Id,
                Street				= wo.Location.MS_FSM_Location_Address__Street__s,
                City				= wo.Location.MS_FSM_Location_Address__City__s,
                StateCode			= wo.Location.MS_FSM_Location_Address__StateCode__s,
                PostalCode			= wo.Location.MS_FSM_Location_Address__PostalCode__s,
                CountryCode			= wo.Location.MS_FSM_Location_Address__CountryCode__s,
                DurationType		= 'Hours',
                Duration			= d
            );
        }
        
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_EHINT_StagingWorkOrderWriteback(ehId, woid, woliid));
        }
    }
}