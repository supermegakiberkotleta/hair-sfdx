import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { Modal } from 'lightning/modal';
import startLeadConversion from '@salesforce/apex/LeadConversionController.startLeadConversion';
import checkForDuplicates from '@salesforce/apex/LeadConversionController.checkForDuplicates';

export default class LeadConversionModalLauncher extends NavigationMixin(LightningElement) {
    @api recordId;
    @track previousStatus = null;
    @track isInitialized = false;
    @track wiredLeadResult;

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Lead.Status', 'Lead.RecordTypeId'] 
    })
    wiredLead(result) {
        this.wiredLeadResult = result;
        if (result.data) {
            const currentStatus = result.data.fields.Status.value;
            
            // Если статус изменился на "Call after" и это не первая загрузка
            if (this.isInitialized && 
                currentStatus === 'Call after' && 
                this.previousStatus && 
                this.previousStatus !== 'Call after') {
                
                // Проверяем, что RecordType существует
                const recordTypeId = result.data.fields.RecordTypeId.value;
                if (recordTypeId) {
                    this.showConversionModal();
                }
            }
            
            this.previousStatus = currentStatus;
            this.isInitialized = true;
        }
    }

    async showConversionModal() {
        try {
            const result = await Modal.open({
                size: 'large',
                content: 'c:lead-conversion-system-modal',
                contentParams: {
                    recordId: this.recordId
                }
            });
            
            // Обработка результата модального диалога
            if (result) {
                // Обновляем данные лида после закрытия модального окна
                return refreshApex(this.wiredLeadResult);
            }
        } catch (error) {
            this.showToast('Error', 'Failed to show conversion modal: ' + error.message, 'error');
        }
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