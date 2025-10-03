import { LightningElement, api } from 'lwc';
import getMessages from '@salesforce/apex/WhatsappOpportunityChatController.getMessages';
import sendMessage from '@salesforce/apex/WhatsappOpportunityChatController.sendMessage';
import getOpportunityPhone from '@salesforce/apex/WhatsappOpportunityChatController.getOpportunityPhone';

export default class WhatsappOpportunityChat extends LightningElement {
    @api recordId; // ← ID Opportunity
    phoneNumber = '';
    messages = [];
    newMessage = '';
    intervalId;

    connectedCallback() {
        this.loadOpportunityPhone();
        this.loadMessages();

        // Автообновление чата каждые 1 секунду (как в Lead)
        this.intervalId = setInterval(() => {
            this.loadMessages();
        }, 1000);
    }

    disconnectedCallback() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
    }

    loadOpportunityPhone() {
        getOpportunityPhone({ opportunityId: this.recordId })
            .then(phone => {
                if (phone) {
                    this.phoneNumber = phone;
                 
                }
            })
            .catch(error => console.error('Error loading opportunity phone', error));
    }

    loadMessages() {
        getMessages({ opportunityId: this.recordId })
            .then(result => {
                const formatted = result.map(msg => ({
                    Id: msg.Id,
                    message: msg.New_message__c,
                    direction: msg.Direction_new__c,
                    createdAt: new Date(msg.Created_At_New__c).toLocaleTimeString(),
                    cssClass: msg.Direction_new__c === 'Incoming' ? 'incoming' : 'outgoing'
                }));

                const container = this.template.querySelector('.chat-container');
                const wasAtBottom = container ?
                    (container.scrollHeight - container.scrollTop <= container.clientHeight + 10) :
                    false;

                this.messages = [...formatted];

                Promise.resolve().then(() => {
                    if (wasAtBottom && container) {
                        container.scrollTop = container.scrollHeight;
                       
                    }
                });
            })
            .catch(error => {
                console.error('Error loading messages', error);
            });
    }

    handleMessageChange(event) {
        this.newMessage = event.target.value;
    }

    handlePhoneChange(event) {
        this.phoneNumber = event.target.value;
    }

    handleSend() {
        const message = this.newMessage.trim();
        const phone = this.phoneNumber.trim();

        if (!message || !phone) {
            return;
        }

        sendMessage({
            opportunityId: this.recordId, // ← Заменили leadId → opportunityId
            message: message,
            phone: phone
        })
            .then(() => {
                this.newMessage = '';

                const inputField = this.template.querySelector('.message-input');
                if (inputField) inputField.value = '';

                this.loadMessages();
            })
            .catch(error => console.error('Error sending message', error));
    }
}