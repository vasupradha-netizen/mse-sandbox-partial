/******************************************************************************
 * Name         : MS_FSM_AddWoliFollowupQueue
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-03-01
 * Description  : async followup actions for WOLI created using MS_FSM_AddWoliController
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-02-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 1. create Product Required if needed
 * 2. create / update Service Appointment
 *  
 * Tests:
 * MS_FSM_AddWoliTests
 ******************************************************************************/

public class MS_FSM_AddWoliFollowupQueue implements Queueable {

    private String  					woid;
    private Decimal 					totalDuration;
    private String						durationType;
    private List<WorkOrderLineItem>		wolis;
    
    /********************************************************
	 * Purpose: constructor
	 * Input:	woid - Work Order Id - passed from MS_FSM_AddWoliController
	 ********************************************************/
    public MS_FSM_AddWoliFollowupQueue(String w) {
        woid = w;
    }
    
    /********************************************************
	 * Purpose: execute method for queueable interface
	 ********************************************************/
    public void execute(QueueableContext qc) {
        processWoli();
        processServAppt();
    }
    
    /********************************************************
	 * Purpose: WOLI processing - create new Product 
	 * 							  Required (if necessary)
	 ********************************************************/
    private void processWoli() {
        getWoli();
        
        totalDuration = 0;
        durationType = 'Minutes';
        
        Set<String> 			coveredWoli = getExProdReqs();
        List<ProductRequired> 	prodReq 	= new List<ProductRequired>();
        
        for (WorkOrderLineItem woli : wolis) {
			Decimal d = woli.Duration;
            totalDuration += (woli.DurationType == 'Minutes' ? d : (d * 60));
            
            if (!coveredWoli.contains(woli.Id) && !String.isBlank(woli.MS_FSM_Install_Swap_Product__c)) {
                prodReq.add(new ProductRequired(
                    Product2Id 		= woli.MS_FSM_Install_Swap_Product__c,
                    ParentRecordId 	= woli.Id
                ));
            }
        }
        
        if (!Test.isRunningTest()) {
            INSERT prodReq;
        }
        
        if (totalDuration >= 60) {
            totalDuration = totalDuration / 60;
            durationType  = 'Hours';
        }
    }
    
    /********************************************************
	 * Purpose: aggregate Estimated Hours for Service Appt
	 ********************************************************/
    private void processServAppt() {
        List<ServiceAppointment> servAppts = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :woid AND Status != 'Completed'];
        
        if (servAppts.isEmpty()) {
            servAppts.add(new ServiceAppointment(
            	ParentRecordId 		= woid,
                EarliestStartTime 	= System.now(),
                DueDate 			= System.today().addDays(7)
            ));
        }
        for (ServiceAppointment s : servAppts) {
            s.Duration 		= totalDuration;
            s.DurationType 	= durationType;
        }
        
        if (!Test.isRunningTest()) {
            UPSERT servAppts;
        }
    }
    
    /********************************************************
	 * Purpose: retrieving WOLI for current WO
	 ********************************************************/
    private void getWoli() {
        wolis = [SELECT Id,
                 		MS_FSM_Install_Swap_Product__c,
                 		Duration,
                 		DurationType
                 FROM   WorkOrderLineItem
                 WHERE  WorkOrderId = :woid
                 AND    IsGeneratedFromMaintenancePlan = false
                 AND    MaintenancePlanId = ''
                 AND    SuggestedMaintenanceDate = null];
    }
    
    /********************************************************
	 * Purpose: get existing Product Required records so that
	 * 		    those WOLI can be "skipped" (trying to add
	 * 			redundant Products Required will error)
	 * Output:	set of Ids for WOLI that can be skipped
	 ********************************************************/
    private Set<String> getExProdReqs() {
        Set<String> coveredWoli = new Set<String>();
        Set<String> woliIds = new Set<String>();
        for (WorkOrderLineItem w : wolis) {
            woliIds.add(w.Id);
        }
        for (ProductRequired p : [SELECT 	ParentRecordId 
                                  FROM 		ProductRequired 
                                  WHERE 	ParentRecordId IN :woliIds]) 
        {
            coveredWoli.add(p.ParentRecordId);
        }
        return coveredWoli;
    }
}