import { LightningElement, wire, api }      from 'lwc';
import { getRecord, updateRecord }          from 'lightning/uiRecordApi';
import { CloseActionScreenEvent }           from 'lightning/actions';
import { FlowNavigationFinishEvent }        from 'lightning/flowSupport';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import { gql, graphql }                     from 'lightning/uiGraphQLApi';

import WorkOrderLineItemId_field            from '@salesforce/schema/WorkStep.WorkOrderLineItemId';
import asset_object                         from '@salesforce/schema/Asset';
import removal_Disposition                  from '@salesforce/schema/Asset.MS_FSM_Removal_Disposition__c';

export default class MsFsmInstallAssetParent extends LightningElement {

  @api recordId;

  VERSION = '2025-01-29_01';
  //component now contains GQL to query data

  error          = null;
  errorSrc       = '';
  showError      = false;
  displaySpinner = false;

  dataFetchedFromWorkStep;
  serializedProductSuggestions;
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
  
  screenOne     = false;
  screenTwo     = false;
  screenThree   = false;

  objectToSend = {
    parentAssetId           : '',
    workOrderId             : '',
    workOrderLineItemId     : '',
    productId               : '',
    productItemId           : '',
    selectedProductName     : '',
    serialNumber            : '',
    quantityInput           : '0',
    serializedProductId     : '',
    selectedAssetPlacement  : '',
    dispoSelection          : '',
  };

  jsonInitial;

  @wire(getRecord, { recordId: '$recordId', fields: [WorkOrderLineItemId_field] })
  workStep({ error, data }) {
    if(data) {
      try {
        this.dataFetchedFromWorkStep = data; 
        this.objectToSend = {...this.objectToSend, workOrderLineItemId: data.fields.WorkOrderLineItemId.value};
        this.woliIdGql = data.fields.WorkOrderLineItemId.value
        // this.fetchCurrentDetails(data.fields.WorkOrderLineItemId.value);
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
      console.log('dispo', this.dispoPicklist)
    } else if (error) {
      this.errorDisplay(error, 'GET PICKLIST VALUES');
    }
  }

  //potentially move gql wires to bottom of class?
  //import a helper? (read into this)
  //need to add default removal dispo to remove asset also in sprint 3


  woliIdGql = '';

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
                  MS_FSM_Installed_Asset_Install_Date_Time__c {
                    value
                  }
                  MS_FSM_Installed_Asset_Product_Item__c {
                    value
                  }
                  MS_FSM_Installed_Asset_Quantity__c {
                    value
                  }
                  MS_FSM_Installed_Asset_Serial_Number__c {
                    value
                  }
                  MS_FSM_Removed_Asset_Removal_Disposition__c {
                    value
                  }
                  MS_FSM_Removed_Asset_Usage_End_Date_Time__c {
                    value
                  }
                  MS_FSM_Run_Asset_Actions__c {
                    value
                  }
                  MS_FSM_Missing_Inventory_Description__c {
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
                    ServiceTerritoryId {
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
                    IsSerialized {
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
    if (data) {
      const results                   = data.uiapi.query.WorkOrderLineItem.edges[0].node;
      this.detailsFetchedFromWoli     = results; 
      //data for params
      this.serviceTerritoryGql        = results.WorkOrder.ServiceTerritoryId.value;
      this.serializedProductGql       = results.MS_FSM_Install_Swap_Product__r.MS_FSM_Parent_Product__c.value;

      //data for UI 
      this.rootAssetSerial            = results.MS_FSM_Root_Asset__r.SerialNumber.value;
      this.rootAssetProductFamily     = results.MS_FSM_Root_Asset__r.Product2.Family.value;
      this.l2AssetSerial              = results.MS_FSM_L2_Asset__r.SerialNumber.value;
      this.l2AssetProductFamily       = results.MS_FSM_L2_Asset__r.Product2.Family.value;
      this.parentAssetSerial          = results.MS_FSM_Parent_Asset__r.SerialNumber.value;
      this.parentAssetProductFamily   = results.MS_FSM_Parent_Asset__r.Product2?.Family.value ?? '';
      this.woliWorkType               = results.WorkType.MS_FSM_Work_Group__c.value;

      //data for record actions
      this.objectToSend = {
        ...this.objectToSend, 
        parentAssetId                 : results.MS_FSM_Parent_Asset__c.value, //delete
        workOrderId                   : results.WorkOrderId.value, //delete
        workOrderLineItemId           : results.Id,
        isSerialized                  : results.MS_FSM_Install_Swap_Product__r.IsSerialized.value,//will delete
        selectedProductName           : results.MS_FSM_Install_Swap_Product__r.Name.value,//will delete
        productId                     : results.MS_FSM_Install_Swap_Product__c.value,//will delete
        serialNumber                  : results.MS_FSM_Installed_Asset_Serial_Number__c.value ?? '',
      };
      console.log('withgql', this.objectToSend)

      //UI actions
      this.screenOne                  = true;
      console.log('res woli', results);
    }
    if (errors) {
      this.errors = errors;
      console.log('errs', this.errors);
    }
  };

  get currentInstallDetails() {
    return {
      woliId: this.woliIdGql
    };
  }

  serviceTerritoryGql = '';

  @wire(graphql, {
    query: gql`
      query getServiceTerritory($sTerritoryId: ID!) {
        uiapi {
          query {
            ServiceTerritoryLocation(where: { ServiceTerritoryId: { eq: $sTerritoryId } }) {
              edges {
                node {
                  LocationId {
                    value
                  }
                }
              }
            }
          }
        }
      }
    `,
    variables: '$serviceTerritoryDetails'
  })
  serviceTerritoryData({ data, errors }) {
    console.log('st data', data)
    if (data) {
      const results = data.uiapi.query.ServiceTerritoryLocation.edges
      console.log('ST res', results);
      this.serviceTerritoryIdsGql = results.map(record => record.node.LocationId.value);
    }
    if (errors) {
      this.errors = errors;
      console.log('errs', this.errors);
    }
  };

  get serviceTerritoryDetails() {
    return {
      sTerritoryId: this.serviceTerritoryGql
    };
  }

  serializedProductGql = '';
  serviceTerritoryIdsGql = '';

  @wire(graphql, {
    query: gql`
      query getSerializedProducts( $parentProductId: ID!, $locationIds: [ID!]!) {
        uiapi {
          query {
            SerializedProduct(
              first: 2000 
              where: {
                Status: { eq: "Available" }
                Product2: { MS_FSM_Parent_Product__c: { eq: $parentProductId } }
                ProductItem: { LocationId: { in: $locationIds } }
              }
            ) {
              edges {
                node {
                  Id 
                  ProductItemId {
                    value
                  }
                  ProductItem {
                    LocationId {
                      value
                    }
                  }
                  Status {
                    value
                  }
                  Name {
                    value
                  }
                  SerialNumber {
                    value
                  }
                  MS_FSM_Product_Cost__c {
                    value
                  }
                  Product2Id {
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
    if (data) {
      const results = data.uiapi.query.SerializedProduct.edges
      this.serializedProductSuggestions = results.map(item => ({
        label: item.node.SerialNumber.value,
        value: item.node.Product2Id.value,
        serial: item.node.SerialNumber.value,
        name: item.node.Name.value,
        id: item.node.Id,
        serializedPrice: item.node.MS_FSM_Product_Cost__c.value,//maybe delete
      }));
      console.log('spsuggest', this.serializedProductSuggestions);
    }
    if (errors) {
      this.errors = errors;
      console.log('errs', this.errors);
    }
  };

  get serializedProductDetails() {
    return {
      parentProductId: this.serializedProductGql,
      locationIds: this.serviceTerritoryIdsGql
    };
  }

  connectedCallback() {
    this.addEventListener('screenOneData', this.updateDataToSend.bind(this));
    this.addEventListener('screenTwoData', this.updateDataToSend.bind(this));
    this.addEventListener('advanceFirstScreenPage', this.advanceToSecondPage.bind(this));
    this.addEventListener('advanceSecondScreenPage', this.advanceToThirdPage.bind(this));
    this.addEventListener('closeFromScreenTwo', this.closeFromScreenTwo.bind(this));
  }

  updateDataToSend(event) {
    const data = event.detail;
    for (const key in data) {
      if(data.hasOwnProperty(key) && this.objectToSend.hasOwnProperty(key)) {
        this.objectToSend[key] = data[key];
        console.log('updated obj', this.objectToSend)
      }
    }
  }

  advanceToSecondPage(event) {
    const data = event.detail.message;
    if (data != 'advance to second') {
      this.errorDisplay('CANNOT ADVANCE TO SECOND PAGE. PROVIDED MESSAGE IS ' + data, 'ADVANCE TO SECOND PAGE');
      return;
    }

    this.screenOne    = false;
    this.screenTwo    = true;
    this.screenThree  = false;

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

    if (this.objectToSend.isSerialized === false) {
      this.objectToSend.newAssetName = `${this.objectToSend.quantityInput} ${this.objectToSend.selectedProductName}`;
    } else {
      this.objectToSend.newAssetName = `${this.objectToSend.serialNumber} ${this.objectToSend.selectedProductName}`;
    }
  }

  closeFromScreenTwo() {
    this.dispatchEvent(new CloseActionScreenEvent());
    this.dispatchEvent(new FlowNavigationFinishEvent());
  }

  updateWoli() {
    const PLACE       = this.objectToSend.selectedAssetPlacement;
    const IS_REPLACE  = this.detailsFetchedFromWoli.WorkType.MS_FSM_Work_Group__c === 'Replacement';
    return updateRecord({
      fields : {
        Id                                          : this.objectToSend.workOrderLineItemId,
        MS_FSM_Run_Asset_Actions__c                 : true,
        MS_FSM_Component_Version__c                 : this.VERSION, 
        MS_FSM_Installed_Asset_Install_Date_Time__c : new Date().toISOString(),
        MS_FSM_Installed_Asset_Serial_Number__c     : this.objectToSend.serialNumber,
        MS_FSM_Removed_Asset_Removal_Disposition__c : IS_REPLACE  ? this.objectToSend.dispoSelection  : null,
        MS_FSM_Removed_Asset_Usage_End_Date_Time__c : IS_REPLACE  ? new Date().toISOString()          : null,
        MS_FSM_Installed_Asset_Asset_Placement__c   : PLACE       ? PLACE                             : null
      }
    });
  }

  updateWorkStep() {
    let workStepInput = {
      fields: {
        Id: this.recordId,
        Status: "Completed",
      },
    };
    return updateRecord(workStepInput);
  }

  async createAllRecords() {
    this.displaySpinner = true;
    try {
      const woliRes = await this.updateWoli();
      const woRes   = await this.updateWorkStep();

      this.displaySpinner = false;

      this.dispatchEvent(new CloseActionScreenEvent());
      this.dispatchEvent(new FlowNavigationFinishEvent());
    } catch (error) {
      this.handleErrors(error);
    }
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
    this.showError  = true;
  }
}