import { LightningElement, api, track, wire } from 'lwc';
import facebookIcon from '@salesforce/resourceUrl/facebookIcon';
import getLeadName from '@salesforce/apex/FacebookChatController.getLeadName';

export default class FacebookMessengerButton extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track isModalOpen = false;
    @track leadName = '';

    facebookIconUrl = facebookIcon;

    @wire(getLeadName, { objectApiName: '$objectApiName', recordId: '$recordId' })
    wiredName({ error, data }) {
        if (data) {
            this.leadName = data;
        } else if (error) {
            console.error('Error fetching record name:', error);
        }
    }

    openChat() {
        this.isModalOpen = true;
    }

    closeChat() {
        this.isModalOpen = false;
    }
}
