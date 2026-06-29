/**
 * @name         MsFsmAssetActionsParent.js
 * @description  Component bundle facilitates update to Serialized Product, Work Order Line Item, and Work Step Records
 * @author       Priscilla Paxton | priscilla@empowherops.com
 * @date         2025-08-22
 *
 *
 * Modification History:
 *   Date       | Author           | Change Description
 *   -----------|------------------|------------------------------------------
 *   2024-06-01 | Priscilla Paxton | Initial creation
 *   2025-05-28 | Priscilla Paxton | Current version handles record update errors within UI
 *   2025-06-09 | Priscilla Paxton | Bug fix for child component rendering
 *   2025-08-22 | Priscilla Paxton | Bug fix for null Serialized Product during record update
 *   2026-04-24 | Reid Byers | Handle Rework Work Type
 * 
 *   
 *
 * Notes:
 *   The Asset Actions Parent Component manages state between Children Screen One and Screen Two components, 
 *   queries Work Order Line Item, Work Step, and Serialized Product Data, and executes record Updates
 */

import { LightningElement, wire, api }      from 'lwc';
import { getRecord, updateRecord }          from 'lightning/uiRecordApi';
import { CloseActionScreenEvent }           from 'lightning/actions';
import { FlowNavigationFinishEvent }        from 'lightning/flowSupport';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { gql, graphql }                     from 'lightning/uiGraphQLApi';

import ProfileName                          from '@salesforce/schema/User.Profile.Name';
import Id                                   from '@salesforce/user/Id';
import WorkOrderLineItemId_field            from '@salesforce/schema/WorkStep.WorkOrderLineItemId';
import WorkOrderId_field                    from '@salesforce/schema/WorkStep.WorkOrderId';
import asset_object                         from '@salesforce/schema/Asset';
import removal_Disposition                  from '@salesforce/schema/Asset.MS_FSM_Removal_Disposition__c';

export default class MsFsmAssetActionsParent extends LightningElement {
@api recordId;

  VERSION = '2026-05-05_partial';
  //handles missing Serialized Product Id during Serialized Product record update
  error          = null;
  errorSrc       = '';
  showError      = false;
  displaySpinner = false;

  dataFetchedFromWorkStep;
  serializedProductIdandSerial;
  serializedProductSnOnly;
  installSwapProduct;
  assetRecordTypeId;
  dispoPicklist;
  l2AssetRingsOfInspection;
  rootAssetSerial;
  rootAssetProductFamily;
  l2AssetSerial;
  l2AssetProductFamily;
  parentAssetSerial;
  parentAssetProductFamily;
  woliWorkType;
  productSerialized   = false;
  serviceTerritoryIds = [];
  selectedAssetToRemoveName;
  workTypeIsRemove = false;
  workTypeIsRework = false;
  workTypeIsNotRemoveOrRework = false;
  recordUpdateButtonDisabled = false;
  dontCompleteWorkStep = false;

  //querying variables
  woliIdGql = '';
  workOrderIdGql = '';
  allwoliSerialNumbers = '';
  serializedProductGql = '';
  tempSpAmount = '';
  currentWoliInstalledSn;
  
  showComponent          = true;
  screenOne              = false;
  screenTwo              = false;
  screenThree            = false;
  missingInventoryScreen = false;

  objectToSend = {
    workOrderLineItemId     : '',
    selectedProductName     : '',
    serialNumber            : '',
    serializedProductId     : '',
    missingSerialNumber     : '',
    serializedProductId     : '',
    selectedAssetPlacement  : '',
    dispoSelection          : '',
    installEndDateOverride  : '',
  };

  jsonInitial;
  
  displayOverrideDateTimeSelect = true;

  @wire(getRecord, {recordId: Id, fields: [ProfileName]})
    userDetails({ error, data }) {
      if(data) {
        if (data.fields.Profile.displayValue.toLowerCase().includes('tech')) {
          this.displayOverrideDateTimeSelect = false;
        }
      }
    }

  @wire(getRecord, { recordId: '$recordId', fields: [WorkOrderLineItemId_field, WorkOrderId_field] })
  workStep({ error, data }) {
    if(data) {
      try {
        this.workOrderIdGql = data.fields.WorkOrderId.value;
        this.dataFetchedFromWorkStep = data; 
        this.objectToSend = {...this.objectToSend, workOrderLineItemId: data.fields.WorkOrderLineItemId.value};
        this.woliIdGql = data.fields.WorkOrderLineItemId.value;
      } catch (error) {
        this.errorDisplay(JSON.stringify(error), 'WORK STEP CATCH 2');
      }
    } else if (error) {
      this.errorDisplay(JSON.stringify(error), 'WORK STEP CATCH 1');
    }
  }

  @wire(getObjectInfo, { objectApiName: asset_object })
  results({ error, data }) {
    if (data) {
      this.assetRecordTypeId = data.defaultRecordTypeId;
    } else if (error) {
      this.assetRecordTypeId = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: '$assetRecordTypeId', fieldApiName: removal_Disposition })
  picklistResults({ error, data }) {
    if (data) {
      this.dispoPicklist = data.values;
    } else if (error) {
      this.errorDisplay(error, 'GET PICKLIST VALUES');
    }
  }

  connectedCallback() {
    this.addEventListener('screenOneData', this.updateDataToSend.bind(this));
    this.addEventListener('screenTwoData', this.updateDataToSend.bind(this));
    this.addEventListener('advanceFirstScreenPage', this.advanceToSecondPage.bind(this));
    this.addEventListener('advanceSecondScreenPage', this.advanceToThirdPage.bind(this));
    this.addEventListener('missingInventoryData', this.updateDataToSend.bind(this));
  }

  updateDataToSend(event) {
    const data = event.detail;
    if(data.serialNumber) {
      const selectedSp = this.serializedProductIdandSerial.find(
        (product) => product.serial === data.serialNumber
      );
      this.objectToSend.serializedProductId = selectedSp.id;
    }
    for (const key in data) {
      if(data.hasOwnProperty(key) && this.objectToSend.hasOwnProperty(key)) {
        this.objectToSend[key] = data[key];
      }
    }
    
    console.log('updated obj', this.objectToSend)
    if(this.objectToSend.missingSerialNumber) {
      this.screenOne              = false;
      this.screenTwo              = false;
      this.screenThree            = true;
      this.missingInventoryScreen = true;
      this.completeWorkStep('In Progress');
    }
  }
  
  handleCompleteInstall() {
    this.recordUpdateButtonDisabled = true;
    this.completeWorkStep('Completed');
  }

  advanceToSecondPage(event) {
    const data = event.detail.message;
    if (data != 'advance to second') {
      this.errorDisplay('CANNOT ADVANCE TO SECOND PAGE. PROVIDED MESSAGE IS ' + data, 'ADVANCE TO SECOND PAGE');
      return;
    }
    if (this.workTypeIsNotRemoveOrRework) {
      this.screenOne    = false;
      this.screenTwo    = true;
      this.screenThree  = false;
    } else {
      this.screenOne    = false;
      this.screenTwo    = false;
      this.screenThree  = true;
    }

  }

  advanceToThirdPage(event) {
    const data = event.detail.message;
    if (data != 'advance to third') {
      this.errorDisplay('CANNOT ADVANCE TO THIRD PAGE. PROVIDED MESSAGE IS ' + data, 'ADVANCE TO THIRD PAGE');
      return;
    }

    this.screenOne    = false;
    this.screenTwo    = false;
    this.screenThree  = true;
    this.objectToSend.newAssetName = `${this.objectToSend.serialNumber} ${this.objectToSend.selectedProductName}`;
  }

  closeFromScreenTwo() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.dispatchEvent(new FlowNavigationFinishEvent());
  }

  buildWoliFields() {
    const PLACE                   = this.objectToSend.selectedAssetPlacement;
    const IS_INSTALL              = this.detailsFetchedFromWoli.WorkType.MS_FSM_Work_Group__c.value === 'Installation';
    const IS_REPLACE              = this.detailsFetchedFromWoli.WorkType.MS_FSM_Work_Group__c.value === 'Replacement';
    const IS_REMOVE               = this.detailsFetchedFromWoli.WorkType.MS_FSM_Work_Group__c.value === 'Removal';
    const IS_REWORK               = this.detailsFetchedFromWoli.WorkType.MS_FSM_Work_Group__c.value === 'Rework';
    const IS_MISSING              = this.objectToSend.missingSerialNumber;
    const INSTALL_ENDDATE_UPDATE  = this.objectToSend.installEndDateOverride;

   let fields = {
      Id                                          : this.objectToSend.workOrderLineItemId,
      MS_FSM_Component_Version__c                 : this.VERSION,
    }

    if(INSTALL_ENDDATE_UPDATE) {
      fields.MS_FSM_InstalledUsageEndDateTimeOverride__c = this.objectToSend.installEndDateOverride;
    }

    if(IS_MISSING) {
      fields.MS_FSM_Missing_Inventory_Description__c = this.objectToSend.missingSerialNumber;
    }
    if(IS_REPLACE || IS_REMOVE) {
      fields.MS_FSM_Removed_Asset_Removal_Disposition__c = this.objectToSend.dispoSelection;
    }
    if(!IS_MISSING) {
      fields.MS_FSM_Installed_Removed_Timestamp__c = new Date().toISOString();
      fields.MS_FSM_Run_Asset_Actions__c           = true;

    }
    if(IS_INSTALL || IS_REPLACE) {
      fields.MS_FSM_Installed_Asset_Serial_Number__c     = this.objectToSend.serialNumber;
      fields.MS_FSM_Installed_Asset_Asset_Placement__c   = PLACE ? PLACE :null;
      fields.MS_FSM_Installed_Asset_SerializedProduct__c = this.objectToSend.serializedProductId;
      fields.MS_FSM_InstalledAssetSerializedProductId__c = this.objectToSend.serializedProductId;
    }
    console.log('fields to update woli with', fields)
    return fields;
  }

  ///woli json fields
  woliJsonFields;
  ///DELETE

  constructor() {
    super();
    console.log('constructor', this.objectToSend);
  }

  async updateWoli() {

    let delay = 0;
    let fields = this.buildWoliFields();

    if (this.workTypeIsRework) {
      fields.MS_FSM_Installed_Removed_Timestamp__c = new Date().toISOString();
      fields.MS_FSM_Run_Asset_Actions__c           = true;
      fields.MS_FSM_Component_Version__c           = this.VERSION;
    }
    
    for (let attempt = 0; attempt <= 3; attempt++) {
      let ignoredFields = [
        'MS_FSM_Installed_Asset_SerializedProduct__c',
        'MS_FSM_InstalledAssetSerializedProductId__c',
        'MS_FSM_Installed_Asset_Asset_Placement__c'
      ];
      if (this.objectToSend.missingSerialNumber) {
        ignoredFields.push('MS_FSM_Installed_Asset_Serial_Number__c');
      }
      const missingFields = Object.entries(fields)
        .filter(([key, value]) => {
          if (ignoredFields.includes(key)) {
            return false;
          }
          return value === null || value === undefined || value === '';
        });
      if (missingFields.length === 0) {
        try {
          await updateRecord({ fields });
          return;
        } catch (error) {
          throw error;
          }
        } else if (attempt < 3) {
            delay += 2000;
            console.log('delay', delay, 'milliseconds')
            await new Promise((resolve) => setTimeout(resolve, delay));
            fields = this.buildWoliFields();
        } else {
          this.dontCompleteWorkStep = true;
          fields = {
            Id                                          : this.objectToSend.workOrderLineItemId,
            MS_FSM_Component_Version__c                 : this.VERSION,
            //Inventory_Transaction_Failure_Root_Cause__c : 'Asset Actions LWC missing required field value',
          }
          this.woliJsonFields = JSON.stringify(fields);
          await updateRecord({ fields });
          return;
      }
    }
  }

  updateSerializedProduct() {
    const spId = this.objectToSend.serializedProductId;
    let fields = {
      Id: spId,
      MS_FSM_Exclude_from_Consumption__c: true
    }
    this.sPJsonFields = JSON.stringify(fields);
    console.log('sp fields', fields);
    return updateRecord({ fields });
  }

  updateWorkStep(status) {
    let fields = {
        Id: this.recordId,
        Status: status,
      }
    return updateRecord({ fields });
  }

  async completeWorkStep(param) {
    console.log("WOLI Work Type is", this.woliWorkType)
    this.displaySpinner = true;
    try {
      if((this.woliWorkType === 'Installation' || this.woliWorkType === 'Replacement') 
        && !this.objectToSend.missingSerialNumber
      ) {
        await this.updateSerializedProduct();
      }
      await this.updateWoli();
      if(this.dontCompleteWorkStep) {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new FlowNavigationFinishEvent()); 
        return;
      }
      await this.updateWorkStep(param);
      this.dispatchEvent(new CloseActionScreenEvent());
      this.dispatchEvent(new FlowNavigationFinishEvent());  
    }
    catch (error) {
      console.log('record update error', error);
      this.handleErrors(error);
    }
    this.displaySpinner = false;
  }

  handleErrors(error) {
    let errorMessage = 'An unexpected error occurred.';
    if (error.body && error.body.message) {
        errorMessage = error.body.message;
    } else if (error.message) {
        errorMessage = error.message;
    }
    this.errorDisplay(errorMessage, 'HANDLE UPDATE ERRORS');
  }

  errorDisplay(error, src) {
    this.error      = error;
    this.errorSrc   = src;
    this.showComponent = false;
    this.showError  = true;
  }

  relatedWoliSn = false;
  allwoliAssetSn;
  allWoliSn;

  allWoliSerializedDataQueryCount = 0;

  ////QUERY ALL WOLIS IN WORKORDER TO GET SERIALIZED PRODUCT IDS
  @wire(graphql, {
    query: gql`
      query getAllWoliSpIds( $workOrderId: ID! ) {
        uiapi {
          query {
            WorkOrderLineItem(
              where: {
                WorkOrderId: { eq: $workOrderId }
              }
            ) {
              edges {
                node {
                  Asset {
                    SerialNumber {
                      value
                    }
                  }
                  MS_FSM_Installed_Asset_Serial_Number__c {
                    value
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: '$currentWorkOrderId'
  })
  allWoliSerializedData({ data, errors }) {
    this.allWoliSerializedDataQueryCount++;
    console.log('allWoliSerializedData query run times:', this.allWoliSerializedDataQueryCount, 'data?', data);
    if (data) {
      this.allwoliAssetSn = data.uiapi.query.WorkOrderLineItem.edges
        .filter((data) => data.node.Asset && data.node.Asset.SerialNumber?.value)
        .map((data) => data.node.Asset?.SerialNumber?.value)
      this.allWoliSn = data.uiapi.query.WorkOrderLineItem.edges
        .filter((data) => data.node.MS_FSM_Installed_Asset_Serial_Number__c?.value)
        .map((data) => data.node.MS_FSM_Installed_Asset_Serial_Number__c.value)
      this.relatedWoliSn = true;
    }
    if (errors) {
      this.errors = errors;
    }
  };
  get currentWorkOrderId() {
    return {
      workOrderId: this.workOrderIdGql,
    };
  }
  woliDataQueryTimes = 0;
  ///QUERY CURRENT WOLI DATA
  @wire(graphql, {
    query: gql`
      query GetWorkOrderLineItem($woliId: ID!) {
        uiapi {
          query {
            WorkOrderLineItem(where: { Id: { eq: $woliId } }) {
              edges {
                node {
                  Id
                  LineItemNumber {
                    value
                  }
                  WorkTypeId {
                    value
                  }
                  MS_FSM_Installed_Asset_Asset_Placement__c {
                    value
                  }
                  MS_FSM_Parent_Asset__c {
                    value
                  }
                  MS_FSM_Installed_Asset_Serial_Number__c {
                    value
                  }
                  MS_FSM_Removed_Asset_Removal_Disposition__c {
                    value
                  }
                  MS_FSM_Install_Swap_Product__c {
                    value
                  }
                  WorkOrderId {
                    value
                  }
                  MS_FSM_Root_Asset__c {
                    value
                  }
                  AssetId {
                    value
                  }
                  MS_FSM_L2_Asset__c {
                    value
                  }
                  WorkType {
                    MS_FSM_Work_Group__c {
                      value
                    }
                  }
                  WorkOrder {
                    WorkOrderNumber {
                      value
                    }
                  }
                  MS_FSM_Install_Swap_Product__r {
                    MS_FSM_Parent_Product__c {
                      value
                    }
                    Name {
                      value
                    }
                    MS_FSM_Require_Asset_Placement__c {
                      value
                    }
                  }
                  MS_FSM_Parent_Asset__r {
                    Name {
                      value
                    }
                    SerialNumber {
                      value
                    }
                    Product2 {
                      Family {
                        value
                      }
                    }
                  }
                  MS_FSM_L2_Asset__r {
                    SerialNumber {
                      value
                    }
                    MS_FSM_Return_Rings_for_Inspection__c {
                      value
                    }
                    Product2 {
                      Family {
                        value
                      }
                    }
                  }
                  Asset {
                    Name {
                      value
                    }
                    MS_FSM_Asset_Placement__c {
                      value
                    }
                    SerialNumber {
                      value
                    }
                    MS_FSM_Removal_Disposition__c {
                      value
                    }
                    Product2 {
                      Family {
                        value
                      }
                    }
                  }
                  MS_FSM_Root_Asset__r {
                    SerialNumber {
                      value
                    }
                    Name {
                      value
                    }
                    Product2 {
                      Family {
                        value
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: '$currentInstallDetails'
  })
  woliData({ data, errors }) {
    this.woliDataQueryTimes++;
    console.log('woliData query run times:', this.woliDataQueryTimes, 'data?', data);
    if (data) {
      console.log('raw', data);
      const results                   = data.uiapi.query.WorkOrderLineItem.edges[0].node;
      this.detailsFetchedFromWoli     = results; 

      //data for params
      this.currentWoliInstalledSn     = results.MS_FSM_Installed_Asset_Serial_Number__c?.value;
      this.serializedProductGql       = results.MS_FSM_Install_Swap_Product__c.value ?? '';

      //data for UI 
      this.rootAssetSerial          = results.MS_FSM_Root_Asset__r?.SerialNumber?.value ?? '';
      this.rootAssetProductFamily   = results.MS_FSM_Root_Asset__r?.Product2?.Family?.value ?? '';
      this.l2AssetSerial            = results.MS_FSM_L2_Asset__r?.SerialNumber?.value ?? '';
      this.l2AssetProductFamily     = results.MS_FSM_L2_Asset__r?.Product2?.Family?.value ?? '';
      this.parentAssetSerial        = results.MS_FSM_Parent_Asset__r?.SerialNumber?.value ?? '';
      this.parentAssetProductFamily = results.MS_FSM_Parent_Asset__r?.Product2?.Family?.value ?? '';
      this.woliWorkType             = results.WorkType?.MS_FSM_Work_Group__c?.value ?? '';

      if (this.woliWorkType === 'Removal') {
        this.workTypeIsRemove   = true;
      }

      if (this.woliWorkType === 'Rework') {
        this.workTypeIsRework   = true;
      }
      
      if (this.woliWorkType !== 'Remove' && this.woliWorkType !== 'Rework') {
        this.workTypeIsNotRemoveOrRework   = true;
      }

      //data for record actions
      this.objectToSend = {
        ...this.objectToSend, 
        workOrderLineItemId           : results.Id,
        selectedProductName           : results.MS_FSM_Install_Swap_Product__r?.Name.value ?? '',
        serialNumber                  : results.MS_FSM_Installed_Asset_Serial_Number__c.value ?? '',
        selectedAssetPlacement        : results.MS_FSM_Installed_Asset_Asset_Placement__c.value ?? '',
      };
      //UI actions
      if(!this.screenTwo && !this.screenThree && !this.missingInventoryScreen && !this.workTypeIsRework) {
        this.screenOne = true;
      }

      if(this.workTypeIsRework){
        this.screenThree = true;
      }
    
      console.log('res woli', results);
    }
    if (errors) {
      this.errors = errors;
      console.log('woli errs', this.errors);
    }
  };
  get currentInstallDetails() {
    console.log('param', this.woliIdGql, this.woliIdGql.length);
    if(!this.woliIdGql.length) {
      return 
    } else {
      return {
        woliId: this.woliIdGql
      };
    }
  }

  serializedProductDataQueryCount = 0;
  //QUERY SERIALIZED PRODUCTS FOR WOLI
  @wire(graphql, {
    query: gql`
      query getSerializedProducts( $woliInstallSwapProduct: ID!) {
        uiapi {
          query {
            SerializedProduct(
              first: 2000 
              where: {
                Status: { eq: "Available" }
                Product2: { MS_FSM_Parent_Product__c: { eq: $woliInstallSwapProduct } }
                MS_FSM_Exclude_from_Consumption__c: { eq: false }
              }
            ) {
              edges {
                node {
                  Id
                  Status {
                    value
                  }
                  MS_FSM_Exclude_from_Consumption__c  {
                    value
                  }
                  SerialNumber {
                    value
                  }
                  Product2 {
                    MS_FSM_Parent_Product__c {
                      value
                    }
                    Name {
                      value
                    }
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: '$serializedProductDetails'
  })
  serializedProductData({ data, errors }) {
    this.serializedProductDataQueryCount++;
    console.log('serializedProductData query run times:', this.serializedProductDataQueryCount, 'data?', data);
    if (data) {
      const results = data.uiapi.query.SerializedProduct.edges
      const woliAssetSn = this.allWoliSn.filter(serial => serial !== this.currentWoliInstalledSn);
      const filteredRes = results.filter(res =>
        !this.allwoliAssetSn.includes(res.node.SerialNumber.value) && 
        !woliAssetSn.includes(res.node.SerialNumber.value)
      );

      this.serializedProductSnOnly = filteredRes.map(item => ({
        label: item.node.SerialNumber.value,
      }));

      this.serializedProductIdandSerial = filteredRes.map(item => ({
        serial: item.node.SerialNumber.value,
        id: item.node.Id
      }));
      const spOnWoli = this.serializedProductIdandSerial.find((sp => (
        sp.serial === this.objectToSend.serialNumber
      )));
      if (spOnWoli) {
        this.objectToSend.serializedProductId = spOnWoli.id;
      }
    }
    if (errors) {
      this.errors = errors;
    }
  };
  get serializedProductDetails() {
    if(!this.relatedWoliSn) {
      return;
    } else {
      return {
        woliInstallSwapProduct: this.serializedProductGql
      };
    }
  }
}