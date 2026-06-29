import { LightningElement, api, wire } from 'lwc';

export default class MsFsmInstallAssetScreenOne extends LightningElement {
  // @api productSuggestions;
  @api dispoPicklist;
  // _inventoryLocationName;//?
  _isReplacement;
  _detailsFetchedFromWoli;
  showRingInspection = false;
  l2AssetRingsOfInspection;
  dispoSelection;
  showMissingInventoryForm = false;
  removedAssetText;

  // @api 
  // get inventoryLocationName() {
  //   return this._inventoryLocationName;
  // }//?

  // set inventoryLocationName(value) {
  //   if (value) {
  //     this._inventoryLocationName = value;
  //   }
  // }//?

  @api
  get detailsFetchedFromWoli() {
    return this._detailsFetchedFromWoli;
  }
  
  set detailsFetchedFromWoli(value) {
    if(value) {
      this._detailsFetchedFromWoli = value;
      this._isReplacement = value?.WorkType?.MS_FSM_Work_Group__c.value === 'Replacement';
      this.dispoSelection = value?.Asset?.MS_FSM_Removal_Disposition__c.value || '';

      const returnRingsForInspection = value.MS_FSM_L2_Asset__r.MS_FSM_Return_Rings_for_Inspection__c;//?
      const productFamily = value.Asset?.Product2.Family;
      if (returnRingsForInspection && (productFamily === 'PC Ring' || productFamily === 'AS Ring')) {
          this.showRingInspection = true;
          this.l2AssetRingsOfInspection = returnRingsForInspection;
      } else {
          this.showRingInspection = false;
      }

      const assetName = value.Asset?.Name.value;
      const placement = value.Asset?.MS_FSM_Asset_Placement__c.value || '';
      this.removedAssetText = placement ? `${assetName} ${placement}` : assetName;
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

  handleDispositionSelection(event) {
    this.dispoSelection = event.target.value;
  }

  handleMissingInventory() {

  }//?

  handleNext() {
    if (this._isReplacement && this.dispoSelection) {
      this.dispatchScreenOneData();
    } else if (!this._isReplacement) {
      this.dispatchScreenOneData();
    } else {
      return
    }
  }

  dispatchScreenOneData() {
    const eventDetail = {
      dispoSelection : this.dispoSelection
    };

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