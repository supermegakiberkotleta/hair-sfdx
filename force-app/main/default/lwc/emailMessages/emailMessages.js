import { LightningElement, wire } from 'lwc';
import getMessages from '@salesforce/apex/EmailMessagesController.getMessages';

export default class EmailMessages extends LightningElement {
    messages;
    error;

    get errorMessage() {
        if (this.error) {
            return Array.isArray(this.error.body) 
                ? this.error.body.map(e => e.message).join(', ') 
                : this.error.body?.message || 'Unknown error';
        }
        return '';
    }

    @wire(getMessages)
    wiredMessages({ error, data }) {
        if (data) {
            this.messages = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.messages = undefined;
        }
    }
}