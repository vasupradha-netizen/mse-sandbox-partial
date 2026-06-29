import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
// import { CloseActionScreenEvent } from "lightning/actions";
import { updateRecord } from 'lightning/uiRecordApi';
import asset_object from "@salesforce/schema/Asset";
import asset_Placement from "@salesforce/schema/Asset.MS_FSM_Asset_Placement__c";
import { getBarcodeScanner } from 'lightning/mobileCapabilities';

export default class MsFsmInstallAssetScreenTwo extends LightningElement {

  //DONT ALLOW INPUT FOR SERIAL UNTIL SERILZED LIST HAS RETURNED
  @api serializedProductSuggestions;
  @api recordId;
  // @api detailsFetchedFromWoli;
  _objectToSend;
  infoFetchedFromWoli;//?
  assetPlacementSelection;
  hasObjectRendered = false; //why?
  showSerializedSuggestions = false;
  serialInput;
  serializedProductId;
  serialErrorMessage = true;
  assetPlacementErrorMessage = false;
  inputOverMax = false;
  inputMinMet = true;
  assetPlacementSelection;
  assetPlacementOptions;
  limitedSerializedSuggestions;
  selectedProduct;
  missingInventoryScreen = false;
  missingInventoryInput;
  displayImageCapture = false;

  connectedCallback() {
    this.addEventListener('returnToMissingInventoryScreen', this.returnToMissingInventoryScreen.bind(this));
  }

  returnToMissingInventoryScreen() {
    this.displayImageCapture = false;
  }

  @api
  get objectToSend() {
    return this._objectToSend;
  }

  set objectToSend(value) {
    if(value) {
      this._objectToSend = value;
    }
    if(value.hasAssetPlacement){
      this.assetPlacementSelection = value.selectedAssetPlacement;
    }
    if(value.serialNumber) {
      this.serialInput = value.serialNumber;
    }
    this.hasObjectRendered = true;
  }
  
  @api 
  get detailsFetchedFromWoli() {
    return this.infoFetchedFromWoli;
  }

  set detailsFetchedFromWoli(value) {
    this.infoFetchedFromWoli = value;
    this.assetPlacementSelection =  value?.Asset?.MS_FSM_Asset_Placement__c.value || '';
  }

  @wire(getObjectInfo, { objectApiName: asset_object })
  results({ error, data }) {
    if (data) {
      this.assetRecordTypeId = data.defaultRecordTypeId;
    } else if (error) {
      this.assetRecordTypeId = undefined;
    }
  }

  @wire(getPicklistValues, { recordTypeId: "$assetRecordTypeId", fieldApiName: asset_Placement })
  picklistResults({ error, data }) {
    if (data) {
      this.assetPlacementOptions = data.values;
    } else if (error) {
      console.log('picklisterror', error)
    }
  }

  handleSerializedChange(event) {
    this.showSerializedSuggestions = false;
    this.serialInput = event.target.value;
    if (!this.serialInput.length) {
      return;
    }
    let filteredProducts = this.serializedProductSuggestions.filter((product) =>
      product.serial.includes(this.serialInput)
    );
    this.limitedSerializedSuggestions = filteredProducts.slice(0, 3);
    this.showSerializedSuggestions =
      this.limitedSerializedSuggestions.length > 0;
  }

  handleSerializedProductSelect(event) {
    this.showSerializedSuggestions = false;
    this.serialInput = event.target.dataset.value; 
    const selectedProduct = this.serializedProductSuggestions.find(
      (product) => product.serial === this.serialInput
    );
    this.serializedProductId = selectedProduct.id;
    console.log('serial', this.serialInput, 'id', this.serializedProductId)
    if (selectedProduct) {
        this.serialInput = selectedProduct.serial;  
    }
  }

  handleBarcodeClick() {
    const targetInput = event.target.dataset.input;
    const myScanner = getBarcodeScanner();
    const scanningOptions = {
      showSuccessCheckMark: true,
      previewBarcodeData: false,
      manualConfirmation: false,
      successText: "barcode scanned",
      instructionText: "scan the barcode on your item",
    }; 

    if (myScanner.isAvailable()) {
      myScanner
        .scan(scanningOptions)
        .then((result) => {
          if (targetInput === 'scanInventory') {
            this.serialInput = result[0].value;
          } else if (targetInput === 'missingInventory') {
            this.missingInventoryInput = result[0].value; 
          }
          this.serialInput = result[0].value;
          this.handleSerializedChange();
        })
        .catch((error) => {
          console.log(error);
        })
        .finally(() => {
          myScanner.dismiss();
        });
    } else {
      console.log("you cannot scan on this device");
    }
  }

  handleAssetPlacement(event) {
    this.assetPlacementSelection = event.target.value;
  }

  handleScreenTwoNextSerialized() {
    const serialNumbers = this.serializedProductSuggestions.map((sp) => sp.serial);
    this.serialErrorMessage = serialNumbers.includes(this.serialInput);

    if (!this.serialInput && this.infoFetchedFromWoli.MS_FSM_Install_Swap_Product__r.MS_FSM_Require_Asset_Placement__c.value && !this.assetPlacementSelection) {
      this.assetPlacementErrorMessage = true;
      this.serialErrorMessage = false;
      return;
    } else if(this.infoFetchedFromWoli.MS_FSM_Install_Swap_Product__r.MS_FSM_Require_Asset_Placement__c.value && !this.assetPlacementSelection) {
      this.assetPlacementErrorMessage = true;
      return;
    }else if (this.infoFetchedFromWoli.MS_FSM_Install_Swap_Product__r.MS_FSM_Require_Asset_Placement__c.value && this.assetPlacementSelection) {
      this.assetPlacementErrorMessage = false;
    }

    if (!this.serialErrorMessage) {
      return;
    }

    const event = new CustomEvent('screenTwoData', {
      detail: {
        serialNumber            : this.serialInput,
        serializedProductId     : this.serializedProductId,
        selectedAssetPlacement  : this.assetPlacementSelection,
      },
      bubbles: true,
      composed: true,
    })
    this.dispatchEvent(event);
    this.dispatchSecondScreenNextPage();
  
  }

  dispatchSecondScreenNextPage() {
    const event = new CustomEvent('advanceSecondScreenPage', {
      detail: {
        message: 'advance to third',
      },
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(event);
  }

  handleMissingInventory() {
    this.missingInventoryScreen = true;
  }

  handleMissingInventoryInput(event) {
    this.missingInventoryInput = event.target.value;
  }

  handleUploadPhotos() {
    this.displayImageCapture = true;
  }

  handleMissingInventorySubmit() {
    if (!this.missingInventoryInput) {
      return;
    } else {
      Promise.all([this.updateWoli(), this.updateWorkStep()])
        .then(() => {
          this.dispatchCloseScreen();
        })
        .catch((error) => {
          console.error('Error during WOLI or Work Step update', error);
        });
    }
  }

  dispatchCloseScreen() {
    const event = new CustomEvent('closeFromScreenTwo', {
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(event);
  }
  
  updateWoli() {
    let woliInput = {
      fields: {
        Id: this.infoFetchedFromWoli.Id,
        MS_FSM_Missing_Inventory_Description__c: this.missingInventoryInput,
      },
    };
  
    return updateRecord(woliInput).catch((error) => {
      console.error(`Error updating Work Order Line Item: ${error.body.message}`);
      throw error;  
    });
  }
  
  updateWorkStep() {
    let workStepInput = {
      fields: {
        Id: this.recordId,
        Status: 'In Progress',
      },
    };
  
    return updateRecord(workStepInput)
      .catch((error) => {
      console.error(`Error updating Work Step: ${error.body.message}`);
      throw error;  
    });
  }
  
  
}