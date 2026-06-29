import { LightningElement, track } from 'lwc';
import MAINSPRING_LOGO from '@salesforce/resourceUrl/MainspringLogo';

export default class partnerReferralParentLWC extends LightningElement {
    // Expose the static resource URL to the template
    logoUrl = MAINSPRING_LOGO;
}