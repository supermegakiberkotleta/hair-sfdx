import { LightningElement, api, wire } from 'lwc';
import getRecordPsid from '@salesforce/apex/InstagramChatController.getRecordPsid';

export default class InstagramWidgetChat extends LightningElement {
    @api recordId;
    @api objectApiName;
    chatUrl;

    @wire(getRecordPsid, { objectApiName: '$objectApiName', recordId: '$recordId' })
    wiredPsid({ data, error }) {
        if (data) {
            this.chatUrl = `https://hair.lenderpro.ai/chat-widget/instagram?user=${data}&token=lxhWgAsa0Y2zqpHD5pwVAXDOT`;
        } else if (error) {
            console.error('Ошибка получения PSID:', error);
        }
    }
}