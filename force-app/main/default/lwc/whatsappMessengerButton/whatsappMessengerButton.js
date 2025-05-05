import { LightningElement, api, track, wire } from 'lwc';
import whatsappIcon from '@salesforce/resourceUrl/whatsappIcon';
import getLeadName from '@salesforce/apex/WhatsappChatController.getLeadName';

export default class WhatsappMessengerButton extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track isModalOpen = false;
    @track leadName = '';

    whatsappIconUrl = whatsappIcon;

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
