/**
 * @name         msFsmAddWoliMain.js
 * @description  accessed via a button on the Work Order page
 *               optimized for desktop
 *               this allows for adding 1 or more Work Order Line Items (woli)
 *               while enforcing validations
 * @author       Nathan Ehrmann nathan@empowherops.com
 * @date         2025-02-01
 *
 * Modification History:
 *   Date       | Author              | Change Description
 *   -----------|---------------------|------------------------------------------
 *   2025-02-01 | Nathan Ehrmann      | Initial write.
 *
 * Notes:
 * 
 */

import { LightningElement, api, track } from 'lwc';
import { RefreshEvent }                 from 'lightning/refresh';
import { ShowToastEvent }               from "lightning/platformShowToastEvent";

import getWorkOrder from '@salesforce/apex/MS_FSM_AddWoliController.getWorkOrder';
import getChildren  from '@salesforce/apex/MS_FSM_AddWoliController.getChildAssets';
import getTypes     from '@salesforce/apex/MS_FSM_AddWoliController.getWorkTypes';
import getProducts  from '@salesforce/apex/MS_FSM_AddWoliController.getProducts';
import submit       from '@salesforce/apex/MS_FSM_AddWoliController.submit';

export default class MsFsmAddWoliMain extends LightningElement {

    @api recordId = '0WOO9000005R9fROAS';

    screen1      = false;
    screen2      = false;
    nextDisabled = true;

    error;
    wo;
    rootId;
    
    childAssets;
    filteredChildAssets;
    @track displayChildAssets;
    childSize;
    childSearch = '';
    childMsg = '';
  
    allFams;
    @track availableFams;
    @track selectedFams = [];

    workTypes;
    @track filteredWorkTypes;
    selectedWorkType;
    showWorkTypes = true;
    installWorkType = false;

    prodSearchString = '';
    products = [];
    prodReady = false;
    selectedProduct = '';

    selectedIds = [];
    @track protoWoli   = [];

    submitLabel = 'Required Fields Missing';
    submitDisabled = true;

    toastSub = '';
    toastMsg = '';
    toastVar = '';

    sortDirection = 'asc';
    sortColumn    = 'Name';

    SCREEN_1_COLS = [
        { label: 'Asset Name',     fieldName: 'Name' },
        { label: 'Serial Number',  fieldName: 'SerialNumber' }
    ];

    SCREEN_2_COLS = [
        { label: '', type: 'button', typeAttributes: {variant: 'success', label: '+', name: 'add_child' }, fixedWidth: 75 },
        { label: 'Asset Name', hideDefaultActions: true, fieldName: 'name', wrapText : true, sortable: true },
        { label: 'Asset Product Family', hideDefaultActions: true, fieldName: 'prodFam' },
        { label: 'L2 Product Family', hideDefaultActions: true, fieldName: 'l2Fam' },
        { label: 'Parent Name', hideDefaultActions: true, fieldName: 'parentName', wrapText: true, sortable: true },
        { label: 'Run Hours', hideDefaultActions: true, fieldName: 'runHours' },
        { label: 'Asset Placement', hideDefaultActions: true, fieldName: 'placement' }
    ];

    WORK_TYPE_COLS = [
        { label: 'Name', hideDefaultActions: true, fieldName: 'Name' },
        { label: 'Family', hideDefaultActions : true, fieldName: 'MS_FSM_Family__c' },
        { label: 'Estimated Duration', hideDefaultActions: true, fieldName: 'MS_FSM_Duration_and_Duration_Type__c' }
    ]

    PROD_COLS = [
        { label: 'Name', hideDefaultActions: true, fieldName: 'Name', wrapText: true }
    ]

    PLANNED_REACTIVE_OPTS = [
        { label : 'Planned', value : 'Planned' },
        { label : 'Reactive', value : 'Reactive' }
    ];

    HOURS_MINUTES_OPTS = [
        { label : 'Hours',   value : 'Hours'   },
        { label : 'Minutes', value : 'Minutes' }
    ];

    connectedCallback() {
        getWorkOrder({ woid : this.recordId })
            .then(data => {
                this.rootId = data.AssetId;
                this.getChild();
            });
    }
    
    getFams() {
        let fams = [];
        for (let x of this.childAssets) {
            let f = x.prodFam;
            if (f && !fams.includes(f)) {
                fams.push(f);
            }
        }
        fams.sort();
        this.allFams = [];
        this.allFams.push({ label : 'None', value : 'None' });
        for (let x of fams) {
            this.allFams.push({ label : x, value : x });
        }
        this.availableFams = this.allFams;
        this.screen1 = true;
    }

    getWT() {
        let fs = [];
        this.protoWoli.forEach((x) => {
            if (x.family) {
                fs.push(x.family);
            }
        });
        getTypes({ families : fs })
            .then(data => {
                this.workTypes          = data;
                this.filteredWorkTypes  = data;
                this.screen2            = true;
            })
    }

    handleNext() {
        this.screen1        = false;
        this.nextDisabled   = true;
        this.initialProto();
        this.getWT();
        return;
    }

    handleSort(e) {
        let fieldName  = e.detail.fieldName;
        let sortDir    = ((fieldName == this.sortColumn && this.sortDirection == 'asc') ? 'desc' : 'asc');

        this.sortColumn     = fieldName;
        this.sortDirection  = sortDir;

        let parseData = JSON.parse(JSON.stringify(this.childAssets));

        parseData.sort((a, b) => {
            let x = a && a[fieldName] ? String(a[fieldName]) : '';
            let y = b && b[fieldName] ? String(b[fieldName]) : '';

            return (x > y ? 1 : -1) * (sortDir == 'asc' ? 1 : -1); 
        });
        this.childAssets = parseData;
        this.filterChildAssets();
    }
    
    goBack() {
        this.screen2    = false;
        this.resetProto();
    }

    initialProto() {
        this.protoWoli[0].selected = true;
        this.protoWoli[0].cssClass = 's3select';
        for (let i = 1; i < this.protoWoli.length; i++) {
            this.protoWoli[i].cssClass = 's3unselect';
        }
    }

    resetProto() {
        for (let x of this.protoWoli) {
            x.selected = false;
            x.cssClass = 's2select';
        }
        this.filterChildAssets();
        this.nextDisabled   = this.selectedIds.length == 0;
        this.screen1        = true;
    }

    getChild() {
        getChildren({ rootId : this.rootId })
            .then(data => {
                this.childAssets            = data;
                this.filteredChildAssets    = data;
                this.displayChildAssets     = this.filteredChildAssets.slice(0, 10);
                this.childSize              = this.filteredChildAssets.length;
                this.getFams();
            });
    }

    filterChildAssets() {
        let s = this.childSearch.toLowerCase();
        let r = [];
        
        for (let x of this.childAssets) {
            if (this.selectedIds.includes(x.id)) {
                continue;
            }

            if (s && !x.name.toLowerCase().includes(s)) {
                continue;
            }

            if (this.selectedFams.length == 0) {
                r.push(x);
                continue;
            }

            let a = x.prodFam;
            let b = x.l2Fam;

            if (this.selectedFams.includes(a) || this.selectedFams.includes(b)) {
                r.push(x);
                continue;
            }

            if (this.selectedFams.includes('None') && (!a || !b)) {
                r.push(x);
                continue;
            }
        }

        this.filteredChildAssets = r;
        this.childSize           = this.filteredChildAssets.length;
        this.displayChildAssets  = this.filteredChildAssets.slice(0, 10);

        let n = this.childSize < 10 ? this.childSize : 10;

        this.childMsg = 'Displaying ' + n + ' of ' + this.childSize + ' Child Assets.';
        if (this.childSize > 10) {
            this.childMsg += ' Use additional filters and search to locate desired Child Assets.';
        }
    }

    addFamily(e) {
        let f = e.target.value;
        this.selectedFams.push(f);
        this.availableFams = this.allFams.filter((s) => (!this.selectedFams.includes(s.label)));
        e.target.value = '';
        this.refreshFamilies();
    }

    removeFamily(e) {
        this.selectedFams = this.selectedFams.filter((s) => s != e.target.label);
        this.refreshFamilies();
    }

    refreshFamilies() {
        this.availableFams = this.allFams.filter((s) => (!this.selectedFams.includes(s.label)));
        this.filterChildAssets();
    }

    handleRowAction(e) {
        let r = e.detail.row;
        this.protoWoli.push({
            childId   : r.id,
            childName : r.name,
            placement : r.placement,
            family    : r.prodFam,
            parent    : r.l2Fam,
            parentId  : r.parentId,
            l2Id      : r.l2Id,
            cssClass  : 's2select',
            selected  : false,
            disabled  : false
        });
        this.selectedIds.push(r.id);
        this.filterChildAssets();
        this.checkNextTwo();
    }

    removeProto(e) {
        let i = e.target.dataset.id;
        this.protoWoli = this.protoWoli.filter((p) => p.childId != i);
        this.selectedIds = this.selectedIds.filter((p) => p != i);
        this.filterChildAssets();
        this.checkNextTwo();
    }

    checkNextTwo() {
        this.nextDisabled = this.selectedIds.length == 0;
    }

    searchChild(e) {
        this.childSearch = e.target.value;
        this.filterChildAssets();
    }

    searchTypes(e) {
        this.selectedWorkType   = null;
        this.showWorkTypes      = true;
        this.installWorkType    = false;
        this.filteredWorkTypes  = this.workTypes.filter((t) => t.Name.toLowerCase().includes(e.target.value.toLowerCase()));
        this.checkSubmission();
    }

    workTypeSelect(e) {
        let v = e.detail.selectedRows;
        if (v.length == 0) {
            return;
        }
        this.selectedWorkType = v[0];
        let w = this.selectedWorkType;
        let g = w.MS_FSM_Work_Group__c;
        this.installWorkType = (g == 'Installation' || g == 'Replacement' || g == 'Rework');

        let t = this.template.querySelector('[data-id="prodSearch"]');
        if (t) {
            t.value = '';
        }
        this.selectedProduct = '';
        
        this.template.querySelector('[data-id="duration"]').value       = w.EstimatedDuration;
        this.template.querySelector('[data-id="durationType"]').value   = w.DurationType;
        this.template.querySelector('[data-id="wtSearch"]').value       = w.Name + ' ✅';

        this.showWorkTypes = false;
        this.checkSubmission();

        let f = w.MS_FSM_Family__c;
        let c = 0;
        for (let x of this.protoWoli) {
            if (!f || x.family == f) {
                x.disabled = false;
                x.cssClass = x.selected ? 's3select' : 's3unselect';
            } else {
                x.selected = false;
                x.disabled = true;
                x.cssClass = 's3disabled';
            }
            c += x.selected ? 1 : 0;
        }
        if (c > 0) {
            return;
        }
        for (let x of this.protoWoli) {
            if (!x.disabled) {
                x.selected = true;
                x.cssClass = 's3select';
                return;
            }
        }
    }

    prodSearchChange(e) {
        this.prodSearchString = e.target.value;
    }

    prodSearch() {
        if (!this.prodSearchString) {
            return;
        }
        getProducts({ s : this.prodSearchString, f : this.selectedWorkType.MS_FSM_Family__c, n : this.selectedWorkType.Name })
            .then(data => {
                this.products = data;
                this.prodReady = true;
            });
    }

    prodSelect(e) {
        let v = e.detail.selectedRows;
        if (v.length == 0) {
            return;
        }
        this.selectedProduct = v[0].Id;
        this.template.querySelector('[data-id="prodSearch"]').value = (v[0].Name + ' ✅');
        this.prodReady = false;
        this.checkSubmission();
    }

    groupProto(e) {
        let i = e.target.dataset.id;
        for (let x of this.protoWoli) {
            if (x.childId == i) {
                x.selected = true;
                x.cssClass = 's3select';
            }
        }
        this.updateSubmitButton();
    }

    ungroupProto(e) {
        let i = e.target.dataset.id;
        for (let x of this.protoWoli) {
            if (x.childId == i) {
                x.selected = false;
                x.cssClass = 's3unselect';
            }
        }
        this.updateSubmitButton();
    }

    updateSubmitButton() {
        if (this.submitDisabled) {
            return;
        }
        let n = 0;
        for (let x of this.protoWoli) {
            if (x.selected) {
                n++;
            }
        }
        this.submitLabel = 'Create ' + n + ' Line Items';
    }

    checkSubmission() {
        let d = this.template.querySelector('[data-id="duration"]').value;
        let t = this.template.querySelector('[data-id="durationType"]').value;
        let r = this.template.querySelector('[data-id="plannedReactive"]').value;

        if (this.selectedWorkType && d && t && r && (!this.installWorkType || this.selectedProduct)) {
            this.submitDisabled = false;
            this.updateSubmitButton();
        } else {
            this.submitDisabled = true;
            this.submitLabel = 'Required Fields Missing';
        }
    }

    submitWoli() {
        this.submitDisabled = true;
        this.submitLabel    = 'Saving...';
        let children = [];
        for (let x of this.protoWoli) {
            if (x.selected) {
                children.push({ id : x.childId, parentId : x.parentId, l2Id : x.l2Id });
            }
        }
        
        let ip = {
            woid       : this.recordId,
            duration   : this.template.querySelector('[data-id="duration"]').value,
            dType      : this.template.querySelector('[data-id="durationType"]').value,
            planReact  : this.template.querySelector('[data-id="plannedReactive"]').value,
            childIds   : children,
            replaceId  : this.selectedProduct,
            wtypeid    : this.selectedWorkType.Id,
            wtypegroup : this.selectedWorkType.MS_FSM_Work_Group__c
        }

        submit({ ip : ip })
            .then(data => {
                if (data == 'SUCCESS') {
                    this.toastSub = 'Line Items Created!';
                    this.toastVar = 'success';

                    let p = [];
                    for (let x of this.protoWoli) {
                        if (x.selected) {
                            continue;
                        }
                        if (p.length == 0) {
                            x.selected = true;
                            x.cssClass = 's3select';
                        }
                        p.disabled = false;
                        p.push(x);
                    }
                    
                    this.protoWoli = p;

                    this.template.querySelector('[data-id="duration"]').value               = '';
                    this.template.querySelector('[data-id="durationType"]').value           = '';
                    this.template.querySelector('[data-id="plannedReactive"]').value        = '';
                    this.template.querySelector('[data-id="wtSearch"]').value               = '';

                    let t = this.template.querySelector('[data-id="prodSearch"]');
                    if (t) {
                        t.value = '';
                    }
                    
                    this.selectedWorkType  = '';
                    this.selectedProduct   = '';
                    this.filteredWorkTypes = this.workTypes;
                    this.showWorkTypes     = true;
                    
                    if (p.length == 0) {
                        this.goBack();
                    } else {
                        this.checkSubmission();
                    }
                    this.dispatchEvent(new RefreshEvent());
                } else {
                    this.toastSub = 'A problem occurred.';
                    this.toastMsg = data;
                    this.toastVar = 'error';
                }
            })
            .catch(error => {
                this.toastSub = 'A problem occurred.';
                this.toastMsg = error;
                this.toastVar = 'error';
            })
            .finally(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title   : this.toastSub,
                    message : this.toastMsg,
                    variant : this.toastVar
                }));
            });
    }
}