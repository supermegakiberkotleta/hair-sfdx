import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

export default class LeadStatusWatcher extends LightningElement {
    @api recordId;
    @track showConversionModal = false;
    @track previousStatus = '';
    @track wiredLeadResult;

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Lead.Status', 'Lead.RecordTypeId'] 
    })
    wiredLead(result) {
        this.wiredLeadResult = result;
        if (result.data) {
            const currentStatus = result.data.fields.Status.value;
            const recordTypeId = result.data.fields.RecordTypeId.value;
            
            // Проверяем, изменился ли статус на "Call after"
            if (currentStatus === 'Call after' && this.previousStatus !== 'Call after') {
                // Проверяем, что это правильный RecordType (Loan_Leads)
                if (recordTypeId === '012Kc000000tenuIAA') {
                    this.previousStatus = this.previousStatus || 'New'; // Если нет предыдущего статуса, используем 'New'
                    this.showConversionModal = true;
                }
            } else if (currentStatus !== 'Call after') {
                // Если статус изменился с "Call after" на другой, сохраняем предыдущий
                this.previousStatus = currentStatus;
            }
        }
    }

    handleCloseModal() {
        this.showConversionModal = false;
        // Обновляем данные лида после закрытия модального окна
        return refreshApex(this.wiredLeadResult);
    }

    handleModalClick(event) {
        // Предотвращаем закрытие модального окна при клике внутри
        event.stopPropagation();
    }
}