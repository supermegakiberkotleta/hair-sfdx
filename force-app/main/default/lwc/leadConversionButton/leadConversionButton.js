import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadConversionButton extends LightningElement {
    @api recordId;
    @api isDisabled = false;
    @track showModal = false;

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Lead.Status', 'Lead.RecordTypeId'] 
    })
    wiredLead;

    handleClick() {
        this.showModal = true;
    }

    handleClose() {
        this.showModal = false;
    }

    handleModalClick(event) {
        // Prevent event bubbling to avoid closing modal when clicking inside
        event.stopPropagation();
    }

    // Show toast message
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}