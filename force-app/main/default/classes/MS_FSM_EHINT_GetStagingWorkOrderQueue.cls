/******************************************************************************
 * Name         : MS_FSM_EHINT_GetStagingWorkOrderQueue
 * Author       : Nathan Ehrmann - nathan@empowherops.com
 * Created Date : 2024-11-01
 * Description  : triggered by a Staging Work Order being created via pipeline;
 * 				  creates a Work Order and Work Order Line Item;
 * 				  may match to an existing Work Order based on L2 Asset;
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
* 	 2024-06-01 | Nathan Ehrmann	  | Matching on L2 Asset instead of LGEN.
 *
 * Notes:
 * 
 * Tests:
 * MS_FSM_EHINT_Tests
 ******************************************************************************/
public class MS_FSM_EHINT_GetStagingWorkOrderQueue implements Queueable, Database.AllowsCallouts {

    private MS_FSM_EtaHub_Work_Order_Staging__c rec;
    private String                              status;
    private Boolean                             updateWoliOnly = false;
    
    private Map<Integer, MS_FSM_EtaHub_Integration_Definition__c>   swoDefs;
    private List<Map<Integer, Map<String, String>>>                 swoDatas;
    private Map<Integer, Map<String, String>>                       swoData;
    private List<Map<Integer, Map<String, String>>>                 swoSubData;
    
    private WorkOrder               wo;
    private Map<String, WorkType>   woTypeMap;
    private Schema.Location         loc;
    private Map<String, Product2>   prodMap;
    private String                  assetSerial;                    
    private Map<String, String>     assetIdMap;
    private List<WorkOrderLineItem> wolis;
    private String                  alphaWoliId;
    private String					locationId;
    
    private Boolean isUpdate 			= false; 
    private Boolean integrationError 	= false;
    
    private final String METHOD = 'MS_FSM_Eta_Hub';
    private final String PLAN   = 'Planned';
    
    public void execute(QueueableContext qc) {
        getRecord();
        if (rec == null) {
            return;
        }
        
        initialize();
        if (integrationError) {
            nextWorkOrder();
            return;
        }
        
        existingWoli();
        if (updateWoliOnly) {
            nextWorkOrder();
            return;
        }
        
        setWorkTypes();
        setProdMap();
        setAssetIdMap();
        getWorkOrder();
        buildWorkOrder();
        buildWolis();        
        createProductRequired();
        updateStagingWo();
        nextJob();
    }
    
    private void getRecord() {
        List<MS_FSM_EtaHub_Work_Order_Staging__c> newRecs = [SELECT Id, Name FROM MS_FSM_EtaHub_Work_Order_Staging__c WHERE Status__c = 'NEW'];
        if (newRecs.isEmpty()) {
            return;
        } else {
            rec = newRecs[0];
        }
    }
    
    private void initialize() {
        swoDefs  = MS_FSM_EHINT_Utils.getIntDefs('bufd2pu5y');
        swoDatas = MS_FSM_EHINT_Utils.getEHData(swoDefs.values(), '{3.EX.' + rec.Name + '}', 0, 0);
        
        if (swoDatas.isEmpty()) {
            status = 'EH RECORD NOT FOUND FOR ID';
            integrationError = true;
            return;
        }
        
        if (MS_FSM_EHINT_Utils.handleError(swoDatas)) {													// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Staging Work Order Failure for Alpha WOLI', 
                swoDatas[0].get(0).get('error'), 
                rec.Id, 
                'MS_FSM_EHINT_GetStagingWorkOrderQueue');
            integrationError = true;
            status = 'INTEGRATION ERROR';
            return;
        }
        
        swoData    = swoDatas[0];
        swoSubData = MS_FSM_EHINT_Utils.getEHData(swoDefs.values(), '{29.EX.' + rec.Name + '}', 0, 0);
        
        if (!swoSubData.isEmpty() && MS_FSM_EHINT_Utils.handleError(swoSubData)) {						// ERROR DURING API TRANSACTION
            MS_FSM_EHINT_Utils.createIntegrationError(
                String.valueOf(System.today()) + ' - Staging Work Order Failure for Beta WOLI', 
                swoDatas[0].get(0).get('error'), 
                rec.Id, 
                'MS_FSM_EHINT_GetStagingWorkOrderQueue');
            integrationError = true;
            status = 'INTEGRATION ERROR';
        }
    }
    
    private void existingWoli() {
        List<WorkOrderLineItem> exWoli = [SELECT Id FROM WorkOrderLineItem WHERE MS_FSM_EtaHub_Id__c = :rec.Name];
        if (exWoli.isEmpty()) {
            return;
        }
        UPDATE new WorkOrderLineItem(Id = exWoli[0].Id, MS_FSM_Installed_Asset_Serial_Number__c = getTxt(swoData, 15));
        status = 'EXISTING STAGING WO - LINE UPDATED ONLY';
        updateWoliOnly = true;
    }
    
    private void getWorkOrder() {
        List<WorkOrderLineItem> wolis = [SELECT WorkOrderId, WorkOrder.Description
                                         FROM   WorkOrderLineItem 
                                         WHERE  MS_FSM_L2_Asset__c = :assetIdMap.get('ltwo')
                                         AND    WorkOrder.Staging_Work_Order_Date__c = :MS_FSM_EHINT_Utils.datevalue(swoData.get(13).get('value'))
                                         AND    WorkOrder.Status != 'Completed'];
        if (wolis.isEmpty()) {
            return;
        }
        wo = new WorkOrder(Id           = wolis[0].WorkOrderId,
                           Description  = newDescription(wolis[0].WorkOrder.Description));
        UPDATE wo;
        status = 'LINE ADDED TO EXISTING WO';
    }
    
    private void buildWorkOrder() {
        if (wo != null) {
            return;
        }
        
        status = 'NEW WO ORDER CREATED';
        
        wo = new WorkOrder(
            WorkTypeId                      = woTypeMap.get('Standard Work Order')?.Id,
            AssetId                         = assetIdMap.get('lgen'),
            MS_FSM_Method_of_Creation__c    = METHOD,
            MS_FSM_EtaHub_Link__c           = 'https://etagen.quickbase.com/nav/app/bnjiec2we/table/bufd2pu5y/action/dr?rid=' + swoData.get(3).get('value')
        );
        MS_FSM_EHINT_Utils.mapValues(swoData, swoDefs, wo);
        
        if (String.isBlank(wo.Subject)) {
            wo.Subject = getTxt(swoData, 25) + ' ' + getTxt(swoData, 9);
        }
        
        try {
            Schema.Location l = [SELECT Id, 
                                        MS_FSM_Account__c,
                                        MS_FSM_Default_Inventory_Location__c
                                 FROM   Location 
                                 WHERE  Id = :locationId];
            wo.LocationId                   = l.Id;
            wo.AccountId                    = l.MS_FSM_Account__c;
            wo.MS_FSM_Inventory_Location__c = l.MS_FSM_Default_Inventory_Location__c;
        } 
        catch (Exception ex) { /* DO NOTHING */ }
        
        INSERT wo;
    }
    
    private void buildWolis() {
        wolis = new List<WorkOrderLineItem>();
        buildAlphaWoli();
        buildBetaWolis();
        INSERT wolis;
        alphaWoliId = wolis[0].Id;
    }
    
    private void buildAlphaWoli() {
        WorkType wt = woTypeMap.get(getTxt(swoData, 9));
        
        wolis.add(new WorkOrderLineItem(
            MS_FSM_Root_Asset__c                    = assetIdMap.get('lgen'),
            MS_FSM_Parent_Asset__c                  = assetIdMap.get('asset'),
            AssetId                                 = wt?.MS_FSM_Work_Group__c == 'Installation' ? null : assetIdMap.get('asset'),
            WorkTypeId                              = wt?.Id,
            WorkOrderId                             = wo.Id,
            MS_FSM_Install_Swap_Product__c          = prodMap?.get('main')?.MS_FSM_Parent_Product__c,
            MS_FSM_EtaHub_Id__c                     = rec.Name,
            MS_FSM_Installed_Asset_Serial_Number__c = getTxt(swoData, 15),
            MS_FSM_Planned_or_Reactive__c           = PLAN,
            MS_FSM_Method_of_Creation__c            = METHOD
        ));
    }
    
    private void buildBetaWolis() {
        for (Map<Integer, Map<String, String>> d : swoSubData) {
            
            String rev = getTxt(d, 27) + '%';
            if (rev.length() == 1) {
                continue;
            }
            
            WorkType wt = woTypeMap.get(getTxt(d, 9));
            
            for (Asset a : [SELECT Id 
                            FROM   Asset 
                            WHERE  MS_FSM_Serial_Chain__c LIKE :('%' + assetSerial + '%') 
                            AND    Product2.ProductCode LIKE :rev]) 
            {
                wolis.add(new WorkOrderLineItem(
                    MS_FSM_Root_Asset__c                        = assetIdMap.get('lgen'),
                    MS_FSM_Parent_Asset__c                      = assetIdMap.get('asset'),
                    WorkOrderId                                 = wo.Id,
                    WorkTypeId                                  = wt?.Id,
                    MS_FSM_Install_Swap_Product__c				= wt?.Name == 'Rework Retrofit' ? prodMap?.get('retro')?.Id : null,
                    MS_FSM_Removed_Asset_Removal_Disposition__c = getTxt(d, 28),
                    MS_FSM_Planned_or_Reactive__c               = PLAN,
                    MS_FSM_Method_of_Creation__c                = METHOD,
                    AssetId                                     = wt?.MS_FSM_Work_Group__c == 'Installation' ? null : a.Id,
                    MS_FSM_EtaHub_Id__c                         = getTxt(d, 3) + '-beta-from-' + rec.Name
                ));
            }
        }
    }
    
    private void setWorkTypes() {
        woTypeMap = new Map<String, WorkType>();
        for (WorkType w : [SELECT Id, Name, MS_FSM_Work_Group__c FROM WorkType]) {
            woTypeMap.put(w.Name, w);
        }
    }
    
    private void setProdMap() {
        Set<String> prodCodes = new Set<String>();
        String e = getTxt(swoData, 25);
        String r = getTxt(swoData, 42);
        if (!String.isBlank(e)) {
            prodCodes.add(e);
        }
        if (!String.isBlank(r)) {
            prodCodes.add(r);
        }
        if (prodCodes.isEmpty()) {
            return;
        }
        prodMap = new Map<String, Product2>();
        for (Product2 p : [SELECT Id, ProductCode, MS_FSM_Parent_Product__c FROM Product2 WHERE ProductCode IN :prodCodes]) {
            if (p.ProductCode == e) {
                prodMap.put('main', p);
            }
            if (p.ProductCode == r) {
                prodMap.put('retro', p);
            }
        }
    }
    
    private void setAssetIdMap() {
        String lgenSerial   = getTxt(swoData, 7);
               assetSerial  = getTxt(swoData, 8);
               assetIdMap   = new Map<String, String>();
        for (Asset a : [SELECT Id, 
                               SerialNumber,
                               MS_FSM_L2_Asset__c,
                        	   LocationId
                        FROM   Asset 
                        WHERE  SerialNumber != '' 
                        AND    SerialNumber IN :(new Set<String>{lgenSerial, assetSerial})]) 
        {
            if (a.SerialNumber == lgenSerial) {
                locationId = a.LocationId;
                assetIdMap.put('lgen', a.Id);
            }
            if (a.SerialNumber == assetSerial) {
                assetIdMap.put('asset', a.Id);
                assetIdMap.put('ltwo', String.isBlank(a.MS_FSM_L2_Asset__c) ? a.Id : a.MS_FSM_L2_Asset__c);
                // if L2 is blank, then the Asset itself is an L2 Core
            }
        }
    }
    
    private void createProductRequired() {
        if (prodMap == null) {
            return;
        }

        INSERT new ProductRequired(
            ParentRecordId          = alphaWoliId,
            Product2Id              = prodMap.get('main')?.Id,
            QuantityRequired        = Decimal.valueOf(getTxt(swoData, 16)),
            MS_FSM_Serial_Number__c = getTxt(swoData, 15)
        );
    }
    
    private String newDescription(String s) {
        s += (' | ' + getTxt(swoData, 12));
        return s;
    }
    
    private void updateStagingWo() {
        UPDATE new MS_FSM_EtaHub_Work_Order_Staging__c(Id = rec.Id, Status__c = status);
    }
    
    private void nextJob() {
        DateTime    p = System.now().addSeconds(30);
        String      c = '' + p.second() + ' ' + p.minute() + ' ' + p.hour() + ' ' + p.day() + ' ' + p.month() + ' ? ' + p.year();

        if (!Test.isRunningTest()) {
            System.schedule('Staging Work Order Steps ' + rec.Name + ' ' +  String.valueOf(p), c, new MS_FSM_EHINT_StagingWorkOrderStepsSched(rec.Name, alphaWoliId, wo.Id));
        }
    }
    
    private String getTxt(Map<Integer, Map<String, String>> d, Integer i) {
        return d.get(i).get('value');
    }
    
    private void nextWorkOrder() {
        updateStagingWo();
        if (!Test.isRunningTest()) {
            System.enqueueJob(new MS_FSM_EHINT_GetStagingWorkOrderQueue());
        }
    }
}