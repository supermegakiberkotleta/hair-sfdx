import { LightningElement, wire } from 'lwc';
import getMessages from '@salesforce/apex/SmsMessagesController.getMessages';

export default class SmsMessages extends LightningElement {
    messages;
    error;

    @wire(getMessages)
    wiredMessages({ error, data }) {
        console.log('СМС'  + data);
        if (data) {
            this.messages = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.messages = undefined;
        }
    }
}