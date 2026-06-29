/**
 * @name         MsFsmAssetActionsScreenTwo.js
 * @description  Component bundle facilitates update to Serialized Product, Work Order Line Item, and Work Step Records
 * @author       Priscilla Paxton | priscilla@empowherops.com
 * @date         2024-06-01
 *
 *
 * Modification History:
 *   Date       | Author           | Change Description
 *   -----------|------------------|------------------------------------------
 *   2024-06-01 | Priscilla Paxton | Initial creation
 *   2025-08-22 | Priscilla Paxton | Current version no longer passes the Serialized Product to the parent, only the Serial Number
 *
 */

import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo, getPicklistValues } from "lightning/uiObjectInfoApi";
import asset_object from "@salesforce/schema/Asset";
import asset_Placement from "@salesforce/schema/Asset.MS_FSM_Asset_Placement__c";
import { getBarcodeScanner } from 'lightning/mobileCapabilities';

export default class MsFsmAssetActionsScreenTwo extends LightningElement {
  @api serializedProductSnOnly;
  @api recordId;
  _objectToSend;
  infoFetchedFromWoli;
  assetPlacementSelection;
  hasObjectRendered = false;
  showSerializedSuggestions = false;
  serialInput;
  serializedProductId;
  serialErrorMessage = true;
  assetPlacementErrorMessage = false;
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
    if(value.selectedAssetPlacement){
      this.assetPlacementSelection = value.selectedAssetPlacement;
    }
    if(value.serialNumber) {
      this.serialInput         = value.serialNumber;
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
    let filteredProducts = this.serializedProductSnOnly.filter((product) =>
      product.label.includes(this.serialInput)
    );

    this.limitedSerializedSuggestions = filteredProducts.slice(0, 3);
    this.showSerializedSuggestions = true;
    this.limitedSerializedSuggestions.length > 0;
  }

  handleSerializedProductSelect(event) {
    this.showSerializedSuggestions = false;
    this.serialInput = event.target.dataset.value; 
    
    const selectedProduct = this.serializedProductSnOnly.find(
      (product) => product.label === this.serialInput
    );
    if (selectedProduct) {
        this.serialInput = selectedProduct.label;  
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

  handleScreenTwoNext() {
    const serialNumbers = this.serializedProductSnOnly.map((sp) => sp.label);
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
        selectedAssetPlacement  : this.assetPlacementSelection,
      },
      bubbles: true,
      composed: true,
    })
    
    console.log('passed data two', event.detail);

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
    const event = new CustomEvent('missingInventoryData', {
      detail: {
        missingSerialNumber     : this.missingInventoryInput,
      },
      bubbles: true,
      composed: true,
    })
    this.dispatchEvent(event);
  }
}