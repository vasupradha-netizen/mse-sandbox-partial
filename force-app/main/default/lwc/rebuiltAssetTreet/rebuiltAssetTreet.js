/**
 * @name         rebuiltAssetTreet.js [yes, unfortunately, "treet" is a typo for "tree"]
 * @description  accessed via a button on Asset page, this allows for rebuilding an entire Asset tree
 *               assuming that there are no Work Orders
 * @author       Nathan Ehrmann nathan@empowherops.com
 * @date         2024-11-01
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2024-11-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 *   - not optimized for mobile, especially offline given the imperative apex used
 *   - there was a long-investigated question for rebuilding a "subtree",
 *     and as of June 2025, it is not considered to be worth the effort
 */

import { LightningElement, api } from 'lwc';
import initialChecks from '@salesforce/apex/MS_FSM_rebuiltAssetTree.initialChecks';
import rebuildTree from '@salesforce/apex/MS_FSM_rebuiltAssetTree.rebuildTree';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class RebuiltAssetTreet extends LightningElement {

    @api recordId;
    
    errorMsg    = '';
    ready       = false;
    showSpinner = false;

    connectedCallback() {
        setTimeout(() => {
            this.delayedStart();
        }, 5);
    }

    delayedStart() {                                        // we apply a 5-millisecond wait
        initialChecks({ assetId : this.recordId })          // to ensure proper loading
        .then((response) => {
            if (response != 'SUCCESS') {
                this.errorMsg = response;
            } else {
                this.errorMsg = '';
            }
            this.ready = true;
            console.log(this.recordId);
        })
        .catch((error) => {
            console.log(error);
        });
    }
    
    onButtonClick() {                                       // user clicks button to confirm desire to
        this.ready          = false;                        // rebuild tree
        this.showSpinner    = true;
        
        rebuildTree({ assetId : this.recordId })
        .catch((error) => {
            console.log(error);
        });
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}