import { LightningElement, api, wire } from 'lwc';
import getRecordPsid from '@salesforce/apex/WhatsappChatController.getRecordPsid';

export default class WhatsappChat extends LightningElement {
    @api recordId;
    @api objectApiName;
    chatUrl;

    @wire(getRecordPsid, { objectApiName: '$objectApiName', recordId: '$recordId' })
    wiredPsid({ data, error }) {
        if (data) {
            this.chatUrl = `https://hair.lenderpro.ai/chat-whatsapp?user=${data}&token=lxhWgAsa0Y2zqpHD5pwVAXDOT`;
        } else if (error) {
            console.error('Ошибка получения PSID:', error);
        }
    }
}