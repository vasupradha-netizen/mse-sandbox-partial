import { LightningElement, api, wire }  from "lwc";
import { CloseActionScreenEvent }       from "lightning/actions";
import { createRecord, updateRecord }   from 'lightning/uiRecordApi';
import { FlowNavigationFinishEvent }    from 'lightning/flowSupport';

import getWorkOrderLine      from "@salesforce/apex/MS_FSM_ConsumeProductsController.getWorkOrderLine";
import getProductItems       from "@salesforce/apex/MS_FSM_ConsumeProductsController.getProductItems";
import getProductRequired    from "@salesforce/apex/MS_FSM_ConsumeProductsController.getProductRequired";

export default class ConsumeProducts extends LightningElement {

  @api recordId = '1WLRK000000SQxF4AW';   // test default

  woli;

  init        = false;
  woliInit    = false;
  prodInit    = false;

  reqProds;
  productIds;
  prodLines;

  disableSubmit = false;

  woliid;
  isWorkStep;
  locationId;

  tableHeaders = [
      { label : 'Include?',       value : 'Include',      width : '10%' },
      { label : 'Part Name',      value : 'Part Name',    width : '75%' },
      { label : 'Qty Needed',     value : 'Qty Needed',   width : '15%' },
  ];

  @wire(getWorkOrderLine, { recordId : '$recordId' })
    getWorkOrderLineInit( {error, data} ) {
        if (data) {
            this.woliid             = data.Id;
            this.woli               = data;
            this.isWorkStep         = this.woliid != this.recordId;
            this.locationId         = this.woli.WorkOrder.MS_FSM_Inventory_Location__c;
            
            this.woliInit = true;
        }
        if (error) {
            console.log('error retrieving work order');
        }
  }

  @wire(getProductRequired, { woliid : '$woliid' })
    getProdItemsInit( {error, data} ) {
      if (data) {
        let pids = [];
        for (let p of data) {
          pids.push(p.Product2Id);
        }
        this.productIds   = pids;
        this.reqProds     = data;
      }
      if (error) {
        console.log('error retrieving required products');
      }
    }

    @wire(getProductItems, { productIds : '$productIds', locationId : '$locationId' })
      getProdItemsFromLoc( {error, data }) {
        if (data) {
          this.prodItems = data;
          this.buildProductLines();
        }
        if (error) {
          console.log('error retrieving product items');
        }
      }

    buildProductLines() {
      this.prodInit = false;

      let prods = [];
      let m     = 0;
      for (let p of this.reqProds) {
        let n = {
          index           : m,
          pid             : p.Product2Id,
          serial          : p.Product2.IsSerialized,
          name            : p.Product2.Name,
          qtyNeed         : p.QuantityRequired,
          cost            : p.Product2.MS_FSM_Cost__c,
          include         : true,
          disableInclude  : false,
          disableQty      : false
        }

        for (let i of this.prodItems) {
          if (i.Product2Id == n.pid) {
            n.piid    = i.Id;
          }
        }
      
        if (!n.hasOwnProperty('piid')) {
          n.qtyHand = 0;
          this.badProduct(n);
        }

        prods.push(n);
        m++;
      }
      this.prodLines = prods;
      this.prodInit = true;
      this.checkSubmit();
    }

    badProduct(x) {
      x.valid           = false;
      x.nameClass       = 'red';
      x.name           += ' ❌';
      x.include         = false;
      x.disableInclude  = true;
      x.disableQty      = true;
    }

    checkSubmit() {
      let e = 0;
      for (let p of this.prodLines) {
        e += p.include ? 1 : 0;
      }
      this.disableSubmit = e == 0;
    }

    onQuantityChange(e) {
      this.prodLines[e.target.dataset.id].qtyNeed = e.target.value;
    }

    onEnableToggle(e) {
      this.prodLines[e.target.dataset.id].include = e.target.checked;
      this.checkSubmit();
    }

    clickSubmit() {
      for (let p of this.prodLines) {
        if (!p.include || p.qtyNeed == 0) {
          continue;
        }

        let ip = {
          apiName : 'ProductConsumed',
          fields : {
            ProductItemId          : p.piid,
            QuantityConsumed       : p.serial ? 0 : p.qtyNeed,
            WorkOrderLineItemId    : this.woliid,
            WorkOrderId            : this.woli.WorkOrderId,
            MS_FSM_Product_Cost__c : p.cost
          }
        };
        createRecord(ip);
      }
      if (this.isWorkStep)
      updateRecord({
          fields : {
            Id      : this.recordId,
            Status  : 'Completed'
          }
        });
      this.dispatchEvent(new CloseActionScreenEvent());
      this.dispatchEvent(new FlowNavigationFinishEvent());
    }
}