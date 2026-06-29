import { LightningElement, api } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import initialCheck from '@salesforce/apex/CreateLgenController.checkSerial';
import submit       from '@salesforce/apex/CreateLgenController.buildLgen';

export default class CreateLgen extends LightningElement {

    @api recordId;

    serial;
    found;
    table;

    // initialize
    // call out to both assembly tables
    // with serial number
    // see if we can get a hit
    // return a variable that controls proceed or error screen

    renderedCallback() {
        initialCheck({ spid : this.recordId })
        .then(data => {
            this.serial = data.serial;
            this.found  = data.found;
            this.table  = data.table;
        })
        .catch(error => {
            // toast
        })
    }

    createLgen() {
        submit({ spid : this.recordId, sn : this.serial, tid : this.table })
        .then(data => {
            if (data == 'SUCCESS') {
                this.dispatchEvent(new CloseActionScreenEvent());
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Creation Initiated",
                        message: "You will receive an email when the asset tree is complete.",
                        variant: "success",
                    }),
                );
            } else {
                // toast

            }
        })
        .catch(error => {
            // toast
        })
    }
}