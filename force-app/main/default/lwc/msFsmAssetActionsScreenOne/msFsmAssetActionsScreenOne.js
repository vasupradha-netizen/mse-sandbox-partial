/**
 * @name         MsFsmAssetActionsScreenOne.js
 * @description  Component bundle facilitates update to Serialized Product, Work Order Line Item, and Work Step Records
 * @author       Priscilla Paxton | priscilla@empowherops.com
 * @date         2024-06-01
 *
 *
 * Modification History:
 *   Date       | Author           | Change Description
 *   -----------|------------------|------------------------------------------
 *   2024-06-01 | Priscilla Paxton | Initial creation
 *   2025-05-28 | Priscilla Paxton | Current version handles record update errors within UI
 *
 * Notes:
 *   The Asset Actions Screen One facilitates Override Timestamp selection and removal disposition
 *   (if removal/replacement)
 */

import { LightningElement, api } from 'lwc';

export default class MsFsmAssetActionsScreenOne extends LightningElement {
  @api dispoPicklist;
  @api displayOverrideDateTimeSelect;
  _isReplacement;
  _isRemoval;
  _isInstall;
  _detailsFetchedFromWoli;
  showRingInspection = false;
  l2AssetRingsOfInspection;
  dispoSelection;
  dateTime;
  showMissingInventoryForm = false;
  removedAssetText;

  selectedAssetToRemoveName; 
  buttontext = '';
  dispoSelectionErrorMessage = false;

  @api
  get detailsFetchedFromWoli() {
    return this._detailsFetchedFromWoli;
  }
  
  set detailsFetchedFromWoli(value) {
    if(value) {
      this._detailsFetchedFromWoli    = value;
      this._isReplacement             = value?.WorkType?.MS_FSM_Work_Group__c.value === 'Replacement';
      this._isInstall                 = value?.WorkType?.MS_FSM_Work_Group__c.value === 'Installation';
      this._isRemoval                 = value?.WorkType?.MS_FSM_Work_Group__c.value === 'Removal';
      if (!this._isRemoval) {
        this.buttontext = 'ENTER ASSET DETAILS';
      } else {
        this.buttontext = 'CLICK TO REMOVE ASSET';
      }

      this.dispoSelection                 = value.MS_FSM_Removed_Asset_Removal_Disposition__c?.value || '';
      this.selectedAssetToRemoveName      = value.Asset?.Name?.value || ''; 
      const returnRingsForInspection      = value.MS_FSM_L2_Asset__r?.MS_FSM_Return_Rings_for_Inspection__c.value || null;
      const productFamily                 = value.Asset?.Product2?.Family?.value || '';
      if (returnRingsForInspection && (productFamily === 'PC Ring' || productFamily === 'AS Ring')) {
          this.showRingInspection         = true;
          this.l2AssetRingsOfInspection   = returnRingsForInspection;
      } else {
          this.showRingInspection         = false;
      }
      if (!this._isRemoval) {
        const assetName = value.Asset?.Name.value || '';
        const placement = value.Asset?.MS_FSM_Asset_Placement__c.value || '';
        this.removedAssetText = placement ? `${assetName} ${placement}` : assetName;
      }
    }
  }

  @api
  get objectToSend() {
    return null;
  }

  set objectToSend(value) {
    if (value) {
      this.selectedProductLabel = value.selectedProductName;
      this.selectedProduct = {
        label: value.selectedProductName,
        value: value.productId,
        productItemId: value.productItemId,
        isSerialized: value.isSerialized,
        quantity: value.quantityOnHand,
        nonSerializedPrice: value.nonSerializedPrice
      }
    }
  }

  handleDateTimeInput(event) {
    console.log('time', event.target.value);
    this.dateTime = event.target.value;
  }

  handleDispositionSelection(event) {
    this.dispoSelection = event.target.value;
  }

  handleNext() {
    if (!this._isInstall && this.dispoSelection) {
      this.dispatchScreenOneData();
    } else if (!this._isInstall && !this.dispoSelection){
      this.dispoSelectionErrorMessage = true;
      return;
    } else if (this._isInstall) {
      this.dispatchScreenOneData();
    } else {
      return;
    }
  }

  dispatchScreenOneData() {
    let eventDetail = {
      dispoSelection : this.dispoSelection
    };

    if (this.dateTime) {
      eventDetail.installEndDateOverride = this.dateTime;
    }

    console.log('passed data', eventDetail);

    const event = new CustomEvent('screenOneData', {
        detail: eventDetail,
        bubbles: true,
        composed: true,
    });
    
    this.dispatchEvent(event);
    this.dispatchNextPage();
  }

  dispatchNextPage() {
    const event = new CustomEvent('advanceFirstScreenPage', {
      detail: {
        message: 'advance to second',
      },
      bubbles: true,
      composed: true
    });
    this.dispatchEvent(event);
  }
}