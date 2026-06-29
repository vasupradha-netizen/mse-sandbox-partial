import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getSettings from '@salesforce/apex/CustomerDbTocController.getSettings';

export default class CdbToc extends NavigationMixin(LightningElement) {

    settings    = [];
    ready       = false;

    connectedCallback() {
        getSettings().then(result => {
            this.settings = result;
            if (result.length == 1) {
                this.clickToNavigate({ target: { dataset: { id: result[0].Id }}});
                return;
            }
            this.ready = true;
        }).catch(error => {
            console.log('Error getting settings');
            console.log(error);
        });
    }
    
    clickToNavigate(e) {
        try {
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    name: 'DashboardViewer__c'
                },
                state: {
                    dbid: e.target.dataset.id
                }
            });
        } catch (x) {
            console.log(x);
        }
    }
}