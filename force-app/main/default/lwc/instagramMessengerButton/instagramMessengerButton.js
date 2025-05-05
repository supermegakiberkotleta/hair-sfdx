import { LightningElement, api, track, wire } from 'lwc';
import instagramIcon from '@salesforce/resourceUrl/instagramIcon';
import getLeadName from '@salesforce/apex/InstagramChatController.getLeadName';

export default class InstagramMessengerButton extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track isModalOpen = false;
    @track leadName = '';

    instagramIconUrl = instagramIcon;

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
