import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import getPreviousStatus from '@salesforce/apex/LeadStatusHistoryController.getPreviousStatus';

export default class LeadStatusWatcher extends LightningElement {
    @api recordId;
    @track showConversionModal = false;
    @track previousStatus = '';
    @track wiredLeadResult;
    @track isLoadingPreviousStatus = false;
    @track isLeadConverted = false;

    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: ['Lead.Status', 'Lead.RecordTypeId', 'Lead.IsConverted'] 
    })
    wiredLead(result) {
        this.wiredLeadResult = result;
        if (result.data) {
            const currentStatus = result.data.fields.Status.value;
            const recordTypeId = result.data.fields.RecordTypeId.value;
            const isConverted = result.data.fields.IsConverted.value;
            
            // Обновляем статус конвертации
            this.isLeadConverted = isConverted;
            
            // Если лид уже сконвертирован, очищаем предыдущий статус
            if (isConverted) {
                this.previousStatus = '';
                console.log('Lead is already converted, clearing previous status');
                return;
            }
            
            // Проверяем, изменился ли статус на "Call after"
            if (currentStatus === 'Call after' && this.previousStatus !== 'Call after') {
                // Проверяем, что это правильный RecordType (Loan_Leads)
                if (recordTypeId === '012Kc000000tenuIAA') {
                    // Если у нас нет предыдущего статуса, получаем его из истории
                    if (!this.previousStatus || this.previousStatus === 'New') {
                        this.getPreviousStatusFromHistory();
                    } else {
                        this.showConversionModal = true;
                    }
                }
            } else if (currentStatus !== 'Call after') {
                // Если статус изменился с "Call after" на другой, сохраняем предыдущий
                this.previousStatus = currentStatus;
            }
        }
    }

    // Получение предыдущего статуса из Lead History
    async getPreviousStatusFromHistory() {
        if (this.isLoadingPreviousStatus) return;
        
        // Проверяем, не сконвертирован ли уже лид
        if (this.isLeadConverted) {
            console.log('Lead is already converted, skipping previous status retrieval');
            return;
        }
        
        this.isLoadingPreviousStatus = true;
        
        try {
            const previousStatus = await getPreviousStatus({ leadId: this.recordId });
            
            if (previousStatus && previousStatus !== 'New') {
                this.previousStatus = previousStatus;
                this.showConversionModal = true;
            } else {
                // Если не удалось получить предыдущий статус, используем 'New' как fallback
                this.previousStatus = 'New';
                this.showConversionModal = true;
                console.warn('Could not determine previous status from history, using "New" as fallback');
            }
        } catch (error) {
            console.error('Error getting previous status from history:', error);
            // В случае ошибки используем 'New' как fallback
            this.previousStatus = 'New';
            this.showConversionModal = true;
        } finally {
            this.isLoadingPreviousStatus = false;
        }
    }

    handleCloseModal() {
        this.showConversionModal = false;
        
        // Проверяем, не сконвертирован ли уже лид
        if (this.isLeadConverted) {
            console.log('Lead is already converted, not reverting status');
            // Очищаем предыдущий статус, чтобы предотвратить возврат
            this.previousStatus = '';
        } else {
            console.log('Lead is not converted, status reversion may occur');
        }
        
        // Обновляем данные лида после закрытия модального окна
        return refreshApex(this.wiredLeadResult);
    }

    handleModalClick(event) {
        // Предотвращаем закрытие модального окна при клике внутри
        event.stopPropagation();
    }
}