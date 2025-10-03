import { LightningElement, api, track, wire } from 'lwc';
import whatsappIcon from '@salesforce/resourceUrl/whatsappIcon';
// import getLeadName from '@salesforce/apex/WhatsappLeadChatController.getLeadName';
// import getRecordPsid from '@salesforce/apex/WhatsappLeadChatController.getRecordPsid';

export default class WhatsappMessengerButton extends LightningElement {
    @api recordId;
    @api objectApiName;

    @track isModalOpen = false;
    @track leadName = '';
    @track whatsappId = '';

    whatsappIconUrl = whatsappIcon;

    // @wire(getLeadName, { objectApiName: '$objectApiName', recordId: '$recordId' })
    // wiredName({ error, data }) {
    //     if (data) {
    //         this.leadName = data;
    //     } else if (error) {
    //         console.error('Error fetching lead name:', error);
    //     }
    // }

    // @wire(getRecordPsid, { objectApiName: '$objectApiName', recordId: '$recordId' })
    // wiredWhatsappId({ error, data }) {
    //     if (data) {
    //         this.whatsappId = data;
    //     } else if (error) {
    //         console.error('Error fetching Whatsapp ID:', error);
    //     }
    // }

    get whatsappLink() {
        return this.whatsappId ? `https://wa.me/${this.whatsappId.replace(/\D/g, '')}` : '#';
    }

    openChat() {
        this.isModalOpen = true;
    }

    closeChat() {
        this.isModalOpen = false;
    }
}