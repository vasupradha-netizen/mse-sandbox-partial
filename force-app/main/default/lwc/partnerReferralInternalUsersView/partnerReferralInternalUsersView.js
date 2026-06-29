import { LightningElement, api, track } from 'lwc';
import getApplicationData from '@salesforce/apex/PartnerReferralInternalUsersViewCntrl.getApplicationData';
import { INTERNAL_SCHEMA } from './schemaConfig'; 

export default class PartnerReferralInternalUsersView extends LightningElement {
    @api recordId;
    @track processedSchema = [];
    @track isLoading = true;
    
    recordData = {};

    async connectedCallback() {
        try {
            this.recordData = await getApplicationData({ recordId: this.recordId });
            this.buildUIModel();
        } catch (error) {
            console.error('Error loading questionnaire data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    buildUIModel() {
        if (!INTERNAL_SCHEMA.steps) return;

        this.processedSchema = INTERNAL_SCHEMA.steps.map(step => {
            const processedQuestions = step.questions.map((q, index) => {
                
                const rawValue = q.apiName ? this.recordData[q.apiName] : null;

                let isVisible = true;
                if (q.dependsOn) {
                    const actualValue = this.recordData[q.dependsOn.apiName];
                    const expectedValue = q.dependsOn.value;
                    const dependentValue = q.apiName ? this.recordData[q.apiName] : null;
                    isVisible = this._matchesExpectedValue(actualValue, expectedValue) || this._hasValue(dependentValue);
                }

                const isHeadingOnly = q.isHeading && !q.apiName;
                const isEmail = q.type === 'email';
                const isBooleanType = q.type === 'checkbox' || q.type === 'radio';
                const isStandardText = !isEmail && !isBooleanType && !isHeadingOnly;

                let generatedShortLabel = q.displayText
                    ? q.displayText
                    : (q.apiName
                        ? q.apiName.replace('__c', '').replace(/_/g, ' ')
                        : '');

                let booleanIcon = '';
                let currentValueDisplay = rawValue;
                
                if (isBooleanType) {
                    if (rawValue === 'Yes' || rawValue === true) {
                        booleanIcon = 'utility:check';
                        currentValueDisplay = q.type === 'checkbox' ? 'Checked' : 'Yes';
                    } else if (rawValue === 'No' || rawValue === false) {
                        booleanIcon = 'utility:close';
                        currentValueDisplay = q.type === 'checkbox' ? 'Unchecked' : 'No';
                    } else {
                        currentValueDisplay = '—';
                    }
                }

                return {
                    ...q,
                    uniqueKey: q.apiName || `heading_${step.stepNumber}_${index}`,
                    isVisible: isVisible,
                    isHeadingOnly: isHeadingOnly,
                    isEmail: isEmail,
                    isBooleanType: isBooleanType,
                    isStandardText: isStandardText,
                    fullText: q.displayText,
                    shortLabel: generatedShortLabel,
                    layoutSize: q.type === 'textarea' || isHeadingOnly ? '12' : '6', 
                    booleanIcon: booleanIcon,
                    currentValueDisplay: currentValueDisplay,
                    currentValue: rawValue ? rawValue : '—'
                };
            });

            return {
                ...step,
                questions: processedQuestions
            };
        });
    }

    _matchesExpectedValue(actualValue, expectedValue) {
        if (actualValue === null || actualValue === undefined || actualValue === '') {
            return false;
        }

        if (typeof actualValue === 'string') {
            const normalizedActual = actualValue.trim().toLowerCase();
            const normalizedExpected = String(expectedValue).trim().toLowerCase();
            return normalizedActual === normalizedExpected || normalizedActual.includes(normalizedExpected);
        }

        return actualValue === expectedValue;
    }

    _hasValue(value) {
        return value !== null && value !== undefined && String(value).trim() !== '';
    }
}