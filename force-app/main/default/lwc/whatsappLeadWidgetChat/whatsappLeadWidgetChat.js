import { LightningElement, api, wire } from 'lwc';
// import getRecordPsid from '@salesforce/apex/WhatsappLeadChatController.getRecordPsid';

export default class WhatsappWidgetChat extends LightningElement {
    @api recordId;
    @api objectApiName;
    chatUrl;

    // @wire(getRecordPsid, { objectApiName: '$objectApiName', recordId: '$recordId' })
    // wiredPsid({ data, error }) {
    //     if (data) {
    //         this.chatUrl = `https://lenderpro.itprofit.net/api/v1/whatsapp/chat-widget/whatsapp?user=${data}&token=3b1e96f9152045fda4555cd3dbdc2377`;
    //     } else if (error) {
    //         console.error('Ошибка получения PSID:', error);
    //     }
    // }
}