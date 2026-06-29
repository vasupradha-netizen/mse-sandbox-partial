import { LightningElement, api } from 'lwc';

/**
 * ReferralPartnerFinalreviewSection
 * Read-only child component that renders a formatted summary of all answers
 * collected across every step except the final (signature) step.
 *
 * Usage:
 *   <c-partner-referral-review
 *       schema={schema}
 *       form-data={formData}>
 *   </c-partner-referral-review>
 *
 * The parent (referralPartnerFormScreens) mounts this at the top of the final
 * wizard step. It only reads props — it never mutates them.
 */
export default class ReferralPartnerFinalreviewSection extends LightningElement {

    /** Full schema array from the JSON Static Resource (all steps). */
    @api schema = [];

    /** Accumulated form data object from the parent wizard. */
    @api formData = {};

    // ════════════════════════════════════════════════════════════════════════
    // PUBLIC GETTERS — Template bindings
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Builds an array of { title, key, rows[] } section objects — one per
     * schema step, excluding the final step (which is the signature page
     * rendered by the parent as editable form fields directly below this).
     */
    get reviewSections() {
        if (!this.schema?.length) return [];

        // All steps except the last one (signature/certification step)
        const stepsToReview = this.schema.slice(0, this.schema.length - 1);

        return stepsToReview.map(step => ({
            key:   step.stepNumber,
            title: step.title,
            rows:  this._buildRows(step.questions ?? [])
        })).filter(section => section.rows.length > 0);
    }

    // ════════════════════════════════════════════════════════════════════════
    // PRIVATE HELPERS
    // ════════════════════════════════════════════════════════════════════════

    /**
     * Converts an array of raw schema questions into enriched row view-models.
     * - Skips heading-type questions (they are rendered as section titles).
     * - Respects `dependsOn` visibility rules so hidden answers are not shown.
     * - Formats address fields into a single readable string.
     * - Derives badge class for Yes/No radio questions.
     */
    _buildRows(questions) {
        const rows = [];

        questions.forEach(q => {
            // Skip decorative section headings
            if (q.isHeading || q.type === 'heading') return;

            // Respect conditional visibility
            if (q.dependsOn) {
                const parentValue = this.formData[q.dependsOn.apiName];
                if (parentValue !== q.dependsOn.value) return;
            }

            const type    = q.type ?? 'text';
            const rawVal  = this.formData[q.apiName];

            let displayValue = '';
            let isAddress    = false;

            if (type === 'radio') {
                displayValue = rawVal ?? '';
            } else if (type === 'checkbox') {
                displayValue = rawVal === true ? 'Agreed' : '';
            } else if (type === 'address') {
                isAddress    = true;
                displayValue = this._formatAddress(q.apiName);
            } else {
                displayValue = rawVal !== undefined && rawVal !== null ? String(rawVal) : '';
            }

            const isYesNo    = type === 'radio';
            const isCheckbox = type === 'checkbox';
            const isLongText = type === 'textarea';
            const isYes      = displayValue === 'Yes';
            const isChecked  = isCheckbox && rawVal === true;
            const isEmpty    = !displayValue;

            rows.push({
                key:          q.apiName ?? q.displayText,
                label:        q.displayText,
                displayValue: displayValue || '—',
                isYesNo,
                isCheckbox,
                isChecked,
                isLongText,
                isPlainText:  !isYesNo && !isCheckbox && !isLongText,
                isEmpty,
                rowClass:     this._computeRowClass(q),
                badgeClass:   isYesNo
                    ? `review-badge ${isYes ? 'review-badge_yes' : 'review-badge_no'}`
                    : ''
            });
        });

        return rows;
    }

    /**
     * Assembles a compound address string from the five sub-fields stored
     * under the Salesforce compound-address field naming convention.
     */
    _formatAddress(apiName) {
        const base  = apiName?.replace('__c', '') ?? '';
        const parts = [
            this.formData[`${base}__Street__s`],
            this.formData[`${base}__City__s`],
            this.formData[`${base}__StateCode__s`],
            this.formData[`${base}__PostalCode__s`],
            this.formData[`${base}__CountryCode__s`]
        ].filter(Boolean);
        return parts.join(', ');
    }

    /**
     * Builds the CSS class string for a review row based on the question's
     * indent level. Indented rows correspond to conditional sub-questions that
     * were triggered by a "Yes" answer on their parent.
     */
    _computeRowClass(q) {
        const base    = 'review-row';
        const indent  = q.indentLevel ?? 0;
        if (indent === 1) return `${base} review-row_indented`;
        if (indent >= 2)  return `${base} review-row_deep-indented`;
        return base;
    }
}