import { LightningElement, wire, api }      from 'lwc';
import { CloseActionScreenEvent }           from "lightning/actions";
import { getRecord, updateRecord }          from 'lightning/uiRecordApi';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import { FlowNavigationFinishEvent }        from 'lightning/flowSupport';

import asset_object from "@salesforce/schema/Asset";

import removal_Disposition        from "@salesforce/schema/Asset.MS_FSM_Removal_Disposition__c";
import getCurrentWoliDetails      from '@salesforce/apex/MS_FSM_Woli_Controller.getCurrentWoliDetails';
import  WorkOrderLineItemId_field from '@salesforce/schema/WorkStep.WorkOrderLineItemId';

export default class mS_FSM_removeAsset extends LightningElement {
  @api recordId; 
  lineItemNumber;
  workOrderNumber;
  woliOriginalAssetName;
  rootAssetId;
  l2AssetSerial;
  l2AssetProductFamily;
  l2AssetRingsOfInspection;
  parentAssetName;
  selectedAssetToRemove;
  selectedAssetToRemoveName;
  displayRemoveAssetForm = true;//?
  relatedAssetLookup = [];
  errorMessage = '';
  removalDispositionSelection;
  error;
  assetSerial;
  assetProductFamily;
  showRingInspection = false;
  assetRecordTypeId;
  rootAssetName;

  removalComboBox=[
    { label: "Return to MSE", value: "Return to MSE" },
  ];

  @wire(getRecord, { recordId: '$recordId', fields: [WorkOrderLineItemId_field] })
  workStep({ error, data }) {
    if(data) {
      try {
        this.fetchWoliDetails(data.fields.WorkOrderLineItemId.value)
      } catch (error) {
        console.log(error)
      }
    } else if (error) {
      console.log(error)
    }
  }

  @wire(getObjectInfo, { objectApiName: asset_object })
  results({ error, data }) {
    if (data) {
      this.assetRecordTypeId = data.defaultRecordTypeId;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.assetRecordTypeId = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: "$assetRecordTypeId", fieldApiName: removal_Disposition })
  picklistResults({ error, data }) {
    if (data) {
      this.removalComboBox = data.values;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.removalComboBox = undefined;
    }
  }

  connectedCallback() {
    this.fetchWoliDetails();
  }

  fetchWoliDetails(param) {
    getCurrentWoliDetails({ woliId: param }) // woliId: '1WLRK000000QjZN4A0' })
      .then((res) => {
        if (res) {
            this.lineItemNumber = res.LineItemNumber;
            this.selectedAssetToRemove = res.AssetId;
            this.workOrderNumber = res.WorkOrder.WorkOrderNumber;
            this.selectedAssetToRemoveName = res.Asset.Name;
            this.rootAssetId = res.Asset.RootAssetId;
            this.l2AssetSerial = res.MS_FSM_L2_Asset__r.SerialNumber;
            this.l2AssetProductFamily = res.MS_FSM_L2_Asset__r.Product2.Family;
            this.assetSerial = res.Asset.RootAsset.SerialNumber;
            this.assetProductFamily = res.Asset.Product2.Family;
            this.rootAssetName = res.Asset.RootAsset.Name;
            this.l2AssetRingsOfInspection = res.MS_FSM_L2_Asset__r.MS_FSM_Return_Rings_for_Inspection__c;
            if(res.Asset.Product2.Family === 'AS Ring' || res.res.Asset.Product2.Family === 'PC Ring'){
              this.showRingInspection = true;
            }
        } else {
          console.log(error);
        }
    })
    .catch((error) => {
      console.log(error);
    });
  }


  handleDispositionSelection(event) {
    this.removalDispositionSelection = event.target.value;
  }


  async handleNext() {
    this.displayRemoveAssetForm = false;
    try{
      await this.updateAssetRecord();
      await this.updateWorkStep();
    }
    catch (error) {
      console.log(error)
    }
  }

  async handleFinish() {
    try {
      this.dispatchEvent(new CloseActionScreenEvent());
      this.dispatchEvent(new FlowNavigationFinishEvent());
    } catch (error) {
      console.log(error)
    }
  }

  updateAssetRecord() {
    let assetInput = {
      fields: {
        Id: this.selectedAssetToRemove,
        Status: 'Obsolete',
        MS_FSM_Usage_End_Date_Time__c: new Date().toISOString(),
        MS_FSM_Removal_Disposition__c: this.removalDispositionSelection,
      }
    };
    return updateRecord(assetInput)
  }

  updateWorkStep() {
    let wsInput = {
      fields: {
          Id: this.recordId, //'1WLRK000000QjZN4A0', 
          Status: "Completed"
      }
    };
    return updateRecord(wsInput);
  }
}