import { LightningElement, track } from 'lwc';
import schemaResource from '@salesforce/resourceUrl/Referral_Partner_Questionnaire_Schema';
import MAINSPRING_LOGO from '@salesforce/resourceUrl/MainspringLogo';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOrgStateCountryMapping from '@salesforce/apex/ReferralPartnerQuestionnaireController.getOrgStateCountryMapping';
import validateTokenAndGetRecord from '@salesforce/apex/ReferralPartnerQuestionnaireController.validateTokenAndGetRecord';
import saveRecord from '@salesforce/apex/ReferralPartnerQuestionnaireController.saveRecord';
import requestNewAccessLink from '@salesforce/apex/ReferralPartnerQuestionnaireController.requestNewAccessLink';

// ─── Constants ─────────────────────────────────────────────────────────────
const STANDARD_INPUT_TYPES = new Set(['text', 'email', 'tel', 'date', 'number', 'url']);

// Field + value on the record that indicate the questionnaire has already
// been finally submitted. ADJUST to match your object's actual API name and
// picklist value (e.g. a Status__c picklist, or a Boolean such as
// Is_Submitted__c — in which case compare against `true` instead).
const SUBMITTED_STATUS_FIELD = 'Status__c';
//const SUBMITTED_STATUS_VALUE = 'Submitted';
const EDITABLE_STATUS_VALUE = 'Draft';

/**
 * PartnerReferralFormLWC
 * Multi-step due-diligence questionnaire wizard for Referral Partner onboarding.
 *
 * Architecture:
 *  - Reads form schema from a JSON Static Resource.
 *  - Token-gated: validates a URL token via Apex before rendering.
 *  - Delegates the final review rendering to the child c-partner-referral-review.
 *  - Persists progress to Salesforce via Apex on every step save.
 */
export default class PartnerReferralFormLWC extends LightningElement {

    // ── Deeply reactive (objects/arrays require @track) ──────────────────────
    @track currentStep    = 1;
    @track schema         = [];
    @track formData       = {};
    @track validationErrors = {};

    // ── Primitives (reactive by default in LWC; @track unnecessary) ─────────
    isLoading            = true;
    isTokenValid         = false;
    showSuccessScreen    = false;
    successTitle         = '';
    successMessage       = '';
    hasValidationError   = false;
    verificationEmail    = '';
    isRequestingLink     = false;
    linkRequestProcessed = false;
    linkRequestMessage   = '';
    urlTokenContext      = '';
    showUnsavedModal     = false;
    hasUnsavedChanges    = false;
    showLeftPanel        = true;

    // ── Internal state (not reactive, no template binding) ───────────────────
    _recordId           = null;
    _originalFormData   = {};
    _pendingTargetStep  = null;
    _countryLabelToCode = {};

    logoUrl = MAINSPRING_LOGO;

    // ════════════════════════════════════════════════════════════════════════
    // LIFECYCLE
    // ════════════════════════════════════════════════════════════════════════

    async connectedCallback() {
        try {
            await this._loadSchema();
            const token = this._extractToken();
            if (!token) {
                this.isTokenValid = false;
                return;
            }
            await this._validateToken(token);
            await this._loadCountryMapping();
        } catch (error) {
            this._logError('connectedCallback', error);
            this._showToast('Initialization Error', 'Could not load the form configuration. Please try refreshing.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // PRIVATE INITIALISATION HELPERS
    // ════════════════════════════════════════════════════════════════════════

    async _loadSchema() {
        const response = await fetch(schemaResource);
        if (!response.ok) {
            throw new Error(`Schema fetch failed with status ${response.status}`);
        }
        const rawSchema = await response.json();
        this.schema = rawSchema.steps;
    }

    _extractToken() {
        const params = new URLSearchParams(window.location.search);
        const token  = params.get('token')?.trim() ?? null;
        if (token) this.urlTokenContext = token;
        return token;
    }

    async _validateToken(token) {
        const result = await validateTokenAndGetRecord({ token });
        if (result?.isValid) {
            this.isTokenValid     = true;
            this._recordId        = result.record.Id;
            this.formData         = { ...result.record };
            this._originalFormData = JSON.parse(JSON.stringify(this.formData));

            // Persist the "already submitted" state across refreshes/revisits —
            // this is re-checked from the server on every load.
            // UPDATED: Hide the panel if status is NOT 'Draft'
            if (this.formData[SUBMITTED_STATUS_FIELD] !== EDITABLE_STATUS_VALUE) {
                this.showLeftPanel = false;
            }
        } else {
            this.isTokenValid = false;
        }
    }

    async _loadCountryMapping() {
        const mappings = await getOrgStateCountryMapping();
        this._countryLabelToCode = Object.fromEntries(
            Object.entries(mappings.countries ?? {})
        );
    }

    // ════════════════════════════════════════════════════════════════════════
    // PUBLIC GETTERS — Template bindings
    // ════════════════════════════════════════════════════════════════════════

    /** Inverse of isTokenValid — used by lwc:if since templates cannot negate. */
    get isTokenInvalid() {
        return !this.isTokenValid;
    }

    /** Displays the partner name in the left-panel legal text. */
    get partnerNameDisplay() {
        return this.formData.Legal_Entity_Name__c || '_________________';
    }

    /** Title of the currently active step. */
    get currentSectionTitle() {
        return this._getStepData(this.currentStep)?.title ?? '';
    }

    /** Total number of wizard steps. */
    get totalSteps() {
        return this.schema.length;
    }

    /** True when the user is on the final (review + signature) step. */
    get isReviewStep() {
        return this.currentStep === this.totalSteps;
    }

    /**
     * True once the record has been finally submitted. Backed by a field on
     * the record itself (re-fetched on every load via validateTokenAndGetRecord),
     * so this persists across page refreshes and re-visits of the same link.
     */
    get isFormLocked() {
    return this.formData?.[SUBMITTED_STATUS_FIELD] !== EDITABLE_STATUS_VALUE;
}

    /** Drives the left-panel progress tracker. */
    get progressSteps() {
        return this.schema.map(step => {
            const isActive    = this.currentStep === step.stepNumber;
            const isCompleted = this.currentStep > step.stepNumber;
            return {
                key:        step.stepNumber,
                label:      step.title,
                stepNumber: step.stepNumber,
                isCompleted,
                // aria-current="step" marks the active step for screen readers
                ariaCurrent: isActive ? 'step' : null,
                className:   `step ${isActive ? 'active' : isCompleted ? 'completed' : 'pending'}`
            };
        });
    }

    /** Maps all questions for the current step into enriched view-model objects. */
    get currentStepQuestions() {
        if (!this.schema.length) return [];
        const stepData = this._getStepData(this.currentStep);
        return (stepData?.questions ?? []).map(q => this._mapQuestion(q));
    }

    /** Controls visibility of the Back navigation button. */
    get showPreviousBtn() {
        return this.currentStep > 1;
    }

    /** Label for the primary next/submit button. */
    get nextButtonLabel() {
        return this.isReviewStep ? 'SUBMIT APPLICATION' : 'SAVE & NEXT';
    }

    /** Accessible aria-label for the primary action button. */
    get nextButtonAriaLabel() {
        return this.isReviewStep
            ? 'Submit the application'
            : `Save and proceed to step ${this.currentStep + 1}`;
    }

    // ════════════════════════════════════════════════════════════════════════
    // NAVIGATION HANDLERS
    // ════════════════════════════════════════════════════════════════════════

    handleStepClick(event) {
        const targetStep = parseInt(event.currentTarget.dataset.step, 10);
        if (targetStep === this.currentStep) return;
        this._interceptOrNavigate(targetStep);
    }

    /** Keyboard accessibility — allow Enter/Space to activate step clicks. */
    handleStepKeydown(event) {
        if (event.key === 'Enter' || event.key === ' ') {
            event.preventDefault();
            this.handleStepClick(event);
        }
    }

    handlePrevious() {
        this.hasValidationError = false;
        if (this.currentStep > 1) {
            this._interceptOrNavigate(this.currentStep - 1);
        }
    }

    async handleNext() {
        if (!this.validateCurrentStep()) {
            this.hasValidationError = true;
            this._showToast(
                'Validation Error',
                'Please complete all required entries on this screen.',
                'error'
            );
            return;
        }
        this.hasValidationError = false;
        const isFinalSubmit = this.isReviewStep;
        const saved = await this._saveDraft(isFinalSubmit);
        if (!saved) return;

        if (isFinalSubmit) {
            this.showLeftPanel = false;
            this.successTitle   = 'Application Submitted';
            this.successMessage = 'Thank you! Your Due Diligence Questionnaire has been received. You may now close this window.';
            this.showSuccessScreen = true;
        } else {
            this.currentStep++;
            this._scrollToTop();
        }
    }

    async handleSaveAndClose() {
        const saved = await this._saveDraft(false);
        if (saved) {
            this.showLeftPanel = false;
            this.successTitle   = 'Draft Saved';
            this.successMessage = 'Your progress has been safely stored. You can close this window and return later using your secure link.';
            this.showSuccessScreen = true;
        }
    }

    /**
     * Core navigation executor — validates forward movement, always allows backward.
     * Called after unsaved-changes check clears.
     */
    executeNavigation(targetStep) {
        if (targetStep < this.currentStep) {
            this.hasValidationError = false;
            this.currentStep = targetStep;
            this._scrollToTop();
            return;
        }
        if (this.validateCurrentStep()) {
            this.hasValidationError = false;
            this.currentStep = targetStep;
            this._scrollToTop();
        } else {
            this.hasValidationError = true;
            this._showToast(
                'Validation Error',
                'Please complete all required fields on this screen before moving forward.',
                'error'
            );
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // INPUT EVENT HANDLERS
    // ════════════════════════════════════════════════════════════════════════

    handleInputChange(event) {
        this.hasValidationError = false;
        this.hasUnsavedChanges  = true;

        const fieldName = event.target.dataset.id;
        if (!fieldName) return;

        const value = event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;

        // Spread to trigger reactivity on the object reference
        this.formData = { ...this.formData, [fieldName]: value };

        // Clear any validation error for this field once the user answers
        if (event.target.type === 'radio' && this.validationErrors[fieldName]) {
            const updated = { ...this.validationErrors };
            delete updated[fieldName];
            this.validationErrors = updated;
        }
    }

    handleAddressChange(event) {
        this.hasValidationError = false;
        this.hasUnsavedChanges  = true;

        const fieldApiName = event.target.dataset.id;
        if (!fieldApiName) return;

        const base = fieldApiName.replace('__c', '');
        this.formData = {
            ...this.formData,
            [`${base}__Street__s`]:      event.target.street,
            [`${base}__City__s`]:        event.target.city,
            [`${base}__StateCode__s`]:   event.target.province,
            [`${base}__CountryCode__s`]: event.target.country,
            [`${base}__PostalCode__s`]:  event.target.postalCode
        };
    }

    handleEmailInputChange(event) {
        this.verificationEmail = event.target.value;
    }

    handleRequestNewLink() {
        if (!this.verificationEmail?.includes('@')) {
            this._showToast('Invalid Input', 'Please enter a valid email address.', 'error');
            return;
        }

        this.isRequestingLink = true;
        this.showLeftPanel = false;
        requestNewAccessLink({
            expiredToken: this.urlTokenContext,
            emailInput:   this.verificationEmail
        })
        .then(result => {
            this.isRequestingLink = false;
            if (result?.success) {
                this.linkRequestProcessed = true;
                this.linkRequestMessage   = result.message;
            } else {
                this._showToast('Request Error', result?.message ?? 'Unknown error occurred.', 'error');
            }
        })
        .catch(error => {
            this.isRequestingLink = false;
            this._logError('handleRequestNewLink', error);
            this._showToast('Server Error', 'Could not complete link request. Try again later.', 'error');
        });
    }

    // ════════════════════════════════════════════════════════════════════════
    // UNSAVED CHANGES MODAL HANDLERS
    // ════════════════════════════════════════════════════════════════════════

    handleStayAndComplete() {
        this.showUnsavedModal  = false;
        this._pendingTargetStep = null;
    }

    /** Prevents overlay click from bubbling to the backdrop dismiss handler. */
    stopModalPropagation(event) {
        event.stopPropagation();
    }

    handleAbandonChanges() {
        // 1. Restore the data model to the last saved state
        this.formData         = JSON.parse(JSON.stringify(this._originalFormData));
        this.hasUnsavedChanges = false;
        this.showUnsavedModal  = false;

        // 2. Force DOM inputs to visually reflect the reverted data
        this._resetDomInputs();

        // 3. Execute the deferred navigation
        if (this._pendingTargetStep !== null) {
            this.executeNavigation(this._pendingTargetStep);
            this._pendingTargetStep = null;
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // VALIDATION
    // ════════════════════════════════════════════════════════════════════════

    validateCurrentStep() {
        let isValid = true;
        const newErrors = { ...this.validationErrors };

        // Native HTML5 validity for all standard inputs / textareas
        this.template.querySelectorAll('.validate-target').forEach(input => {
            if (!input.checkValidity()) {
                input.reportValidity();
                isValid = false;
            }
        });

        // Radio buttons are not covered by checkValidity when using custom pill UI
        this.currentStepQuestions
            .filter(q => q.isVisible && q.isRadio && q.required)
            .forEach(q => {
                if (!this.formData[q.apiName]) {
                    isValid              = false;
                    newErrors[q.apiName] = true;
                }
            });

        this.validationErrors = newErrors;
        return isValid;
    }

    // ════════════════════════════════════════════════════════════════════════
    // APEX PERSISTENCE
    // ════════════════════════════════════════════════════════════════════════

    async _saveDraft(isFinalSubmit) {
        this.isLoading = true;
        try {
            if (isFinalSubmit) {
                this.formData['Status__c'] = 'Submitted'; 
            }
            const payloadString = JSON.stringify(this.formData);
            const result = await saveRecord({
                dataPayload:  payloadString,
                isFinalSubmit,
                recordId: this._recordId
            });

            if (result?.success) {
                this._recordId        = result.recordId;
                this._originalFormData = JSON.parse(JSON.stringify(this.formData));
                this.hasUnsavedChanges = false;
                if (isFinalSubmit) {
                    this._showToast('Success', result.message, 'success');
                }
                return true;
            }

            this._showToast('Save Error', result?.message ?? 'Unknown error occurred.', 'error');
            return false;

        } catch (error) {
            this._logError('_saveDraft', error);
            const message = error?.body?.message ?? error?.message ?? 'An unknown error occurred.';
            this._showToast('Server Error', message, 'error');
            return false;
        } finally {
            this.isLoading = false;
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // PRIVATE HELPERS
    // ════════════════════════════════════════════════════════════════════════

    _getStepData(stepNumber) {
        return this.schema.find(s => s.stepNumber === stepNumber);
    }

    /**
     * Transforms a raw schema question into an enriched view-model object
     * consumed by the template. Computed once per getter invocation.
     */
    _mapQuestion(q) {
        const isVisible = q.dependsOn
            ? this.formData[q.dependsOn.apiName] === q.dependsOn.value
            : true;

        const isCheckbox = q.type === 'checkbox';
        const val        = this.formData[q.apiName];

        // Certification card questions get their own wrapper class so the
        // gray question-wrapper bg/border does NOT apply — they self-style.
        let computedClass;
        if (isCheckbox) {
            computedClass = 'cert-wrapper';
        } else {
            const classes = ['question-wrapper'];
            if (q.indentLevel === 1) classes.push('sub-question-tab');
            if (q.indentLevel === 2) classes.push('deep-nested-tab');
            computedClass = classes.join(' ');
        }

        const baseName = q.apiName?.replace('__c', '') ?? '';

        return {
            ...q,
            isVisible,
            computedClass,
            // A heading question can opt into the "disclaimer box" styling
            // (gray box, orange left accent) by setting "variant": "disclaimer"
            // in the schema. All other headings keep the orange uppercase
            // section-divider styling.
            isDisclaimer:     q.isHeading === true && q.variant === 'disclaimer',
            isSectionHeading: q.isHeading === true && q.variant !== 'disclaimer',
            // Cert cards integrate the question text inside the card —
            // suppress the separate question-text <p> rendered above the control.
            hideLabel:        isCheckbox,
            currentValue:     val !== undefined ? val : (isCheckbox ? false : ''),
            isStandardInput:  STANDARD_INPUT_TYPES.has(q.type),
            inputType:        STANDARD_INPUT_TYPES.has(q.type) ? q.type : 'text',
            isTextArea:       q.type === 'textarea',
            isRadio:          q.type === 'radio',
            isCheckbox,
            isAddress:        q.type === 'address',
            isRadioYes:       val === 'Yes',
            isRadioNo:        val === 'No',
            showError:        !!this.validationErrors[q.apiName],
            // On the final review step, the Legal Entity Name was already
            // captured in step 1 — show it as read-only confirmation text
            // rather than a second editable input.
            isReadOnlyDisplay: this.isReviewStep && q.apiName === 'Signatory_Legal_Entity__c',
            // Reactive class for the cert card — teal highlight when checked.
            // Recomputed every time formData changes (getter re-runs on @track mutation).
            certCardClass:    isCheckbox
                ? `cert-card${val === true ? ' cert-card_checked' : ''}`
                : '',
            streetValue:      this.formData[`${baseName}__Street__s`]      ?? '',
            cityValue:        this.formData[`${baseName}__City__s`]        ?? '',
            provinceValue:    this.formData[`${baseName}__StateCode__s`]   ?? '',
            countryValue:     this.formData[`${baseName}__CountryCode__s`] ?? '',
            postalCodeValue:  this.formData[`${baseName}__PostalCode__s`]  ?? ''
        };
    }

    /** Gate: if unsaved changes exist, show modal before navigating. */
    _interceptOrNavigate(targetStep) {
        if (this.hasUnsavedChanges) {
            this._pendingTargetStep = targetStep;
            this.showUnsavedModal   = true;
            return;
        }
        this.executeNavigation(targetStep);
    }

    /**
     * After reverting formData to _originalFormData, forces DOM inputs
     * to visually reflect the reverted values. Required because LWC does
     * not always re-render when only the property value reference changes.
     */
    _resetDomInputs() {
        this.template.querySelectorAll('.validate-target').forEach(input => {
            const fieldName = input.dataset.id;
            if (!fieldName) return;

            if (input.type === 'checkbox') {
                input.checked = this.formData[fieldName] ?? false;
            } else if (input.tagName === 'LIGHTNING-INPUT-ADDRESS') {
                const base       = fieldName.replace('__c', '');
                input.street     = this.formData[`${base}__Street__s`]      ?? '';
                input.city       = this.formData[`${base}__City__s`]        ?? '';
                input.province   = this.formData[`${base}__StateCode__s`]   ?? '';
                input.country    = this.formData[`${base}__CountryCode__s`] ?? '';
                input.postalCode = this.formData[`${base}__PostalCode__s`]  ?? '';
            } else {
                input.value = this.formData[fieldName] ?? '';
            }
        });

        this.template.querySelectorAll('input[type="radio"]').forEach(radio => {
            const fieldName = radio.dataset.id;
            if (fieldName) {
                radio.checked = radio.value === this.formData[fieldName];
            }
        });
    }

    _scrollToTop() {
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /**
     * Structured error logger.
     */
    _logError(context, error) {
        console.error(`[PartnerReferralFormLWC:${context}]`, error?.message ?? error);
    }
}