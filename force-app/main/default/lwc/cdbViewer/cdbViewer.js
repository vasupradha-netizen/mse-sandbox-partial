import { LightningElement, wire }   from 'lwc';
import { CurrentPageReference }     from 'lightning/navigation';
import getUrl from '@salesforce/apex/CustomerDbViewerController.getUrl';

export default class CdbViewer extends LightningElement {

    url;
    dbid;
    loading = false;

    @wire(CurrentPageReference)
    getParams(currentPageReference) {
        if (currentPageReference) {
            this.dbid = currentPageReference.state?.dbid;
        }
    }

    connectedCallback() {
        if (!this.dbid) {
            return;
        }
        getUrl({ dbid : this.dbid }).then(result => {
            this.url        = result;
            this.loading    = true;
            this.loadingTimeout();
        }).catch(error => {
            console.log('error getting url');
            console.log(error);
        })
    }

    loadingTimeout() {
        setTimeout(() => {
            this.loading = false;
        }, 10000);
    }
}