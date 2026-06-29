trigger MS_FSM_WorkOrderStagingTrigger on MS_FSM_EtaHub_Work_Order_Staging__c (after insert) {
    for (MS_FSM_EtaHub_Work_Order_Staging__c w : Trigger.new) 
    {
        final List<String> CHAIN_CLASS_IDS = new List<String>{
            '01pQr000002MyMA', // MS_FSM_EHINT_GetStagingWorkOrderSched
            '01pQr000002MyM9', // MS_FSM_EHINT_GetStagingWorkOrderQueue
            '01pQr000002MyMB', // MS_FSM_EHINT_StagingWorkOrderServiceAppt
            '01pQr000002MyMC', // MS_FSM_EHINT_StagingWorkOrderSteps
            '01pQr000002MyMD', // MS_FSM_EHINT_StagingWorkOrderStepsSched
            '01pQr000002MyME'  // MS_FSM_EHINT_StagingWorkOrderWriteback 
        };
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE ApexClassId IN :CHAIN_CLASS_IDS AND Status != 'Completed' AND Status != 'Failed'];
        if (!jobs.isEmpty()) {
            return;   // early exit -- there is already a chain of jobs running (and we will catch this on the next iteration)
        }
        
        DateTime p = System.now().addMinutes(1);
        String c = '' + p.second() + ' ' + p.minute() + ' ' + p.hour() + ' ' + p.day() + ' ' + p.month() + ' ? ' + p.year();
        System.schedule('Staging Work Order ' + w.Name + ' ' + String.valueOf(p), c, new MS_FSM_EHINT_GetStagingWorkOrderSched());
    }
}