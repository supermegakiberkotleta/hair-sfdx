import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import startLeadConversion from '@salesforce/apex/LeadConversionController.startLeadConversion';
import checkForDuplicates from '@salesforce/apex/LeadConversionController.checkForDuplicates';

export default class LeadConversionModal extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isAutoOpen = false; // Новый параметр для автоматического открытия
    @api previousStatus; // Предыдущий статус для возврата
    @track currentStep = 1;
    @track isConverting = false;
    @track isSuccess = false;
    @track leadData;
    @track wiredLeadResult;
    @track showModal = false; // Управление видимостью модального окна
    @track duplicateInfo = null; // Информация о дубликатах
    @track showDuplicateWarning = false; // Показывать ли предупреждение о дубликатах

    // Computed properties for step visibility
    get isValidationStep() {
        return this.currentStep === 1;
    }

    get isConversionStep() {
        return this.currentStep === 2;
    }

    // Wire the lead record
    @wire(getRecord, { 
        recordId: '$recordId', 
        fields: [
            'Lead.Final_Daily_payment__c',
            'Lead.Final_purchased_Amount_of_Future_New__c',
            'Lead.Payment_Frequency__c',
            'Lead.Loan_Start_Date__c',
            'Lead.Final_Term__c',
            'Lead.Client_email__c',
            'Lead.Lender_type__c',
            'Lead.Status',
            'Lead.RecordTypeId'
        ] 
    })
    wiredLead(result) {
        this.wiredLeadResult = result;
        if (result.data) {
            this.leadData = result.data;
            // Если это автоматическое открытие и статус "Call after", показываем модальное окно
            if (this.isAutoOpen && this.leadData.fields.Status.value === 'Call after') {
                this.showModal = true;
                // Проверяем, заполнены ли все поля
                this.checkRequiredFields();
            }
        } else if (result.error) {
            this.showToast('Error', 'Failed to load lead data', 'error');
        }
    }

    // Проверка обязательных полей
    checkRequiredFields() {
        if (!this.leadData) return;
        
        const fields = this.leadData.fields;
        const missingFields = [];
        
        if (!fields.Final_Daily_payment__c.value) missingFields.push('Final Daily Payment');
        if (!fields.Final_purchased_Amount_of_Future_New__c.value) missingFields.push('Final Purchased Amount of Future');
        if (!fields.Payment_Frequency__c.value) missingFields.push('Payment Frequency');
        if (!fields.Loan_Start_Date__c.value) missingFields.push('Loan Start Date');
        if (!fields.Final_Term__c.value) missingFields.push('Final Term');
        if (!fields.Client_email__c.value) missingFields.push('Client Email');
        if (!fields.Lender_type__c.value) missingFields.push('Lender Type');
        
        if (missingFields.length > 0) {
            this.showToast('Warning', 'Please fill in all required fields: ' + missingFields.join(', '), 'warning');
        }
    }

    // Handle validation form submit
    handleValidationSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        
        // Validate required fields
        const requiredFields = [
            'Final_Daily_payment__c',
            'Final_purchased_Amount_of_Future_New__c',
            'Payment_Frequency__c',
            'Loan_Start_Date__c',
            'Final_Term__c',
            'Client_email__c',
            'Lender_type__c'
        ];

        const missingFields = [];
        requiredFields.forEach(field => {
            if (!fields[field]) {
                missingFields.push(field);
            }
        });

        if (missingFields.length > 0) {
            this.showToast('Validation Error', 'Please fill in all required fields', 'error');
            return;
        }

        // Update the record
        const recordInput = { fields: { Id: this.recordId, ...fields } };
        
        updateRecord(recordInput)
            .then(() => {
                this.showToast('Success', 'Lead updated successfully', 'success');
                this.currentStep = 2;
                return refreshApex(this.wiredLeadResult);
            })
            .catch(error => {
                this.showToast('Error', 'Failed to update lead: ' + error.body.message, 'error');
            });
    }

    // Handle validation success
    handleValidationSuccess() {
        this.showToast('Success', 'Lead updated successfully', 'success');
        this.currentStep = 2;
    }

    // Handle validation error
    handleError(event) {
        this.showToast('Error', 'Failed to update lead: ' + event.detail.message, 'error');
    }

    // Handle conversion start
    handleConversionStart() {
        this.isConverting = true;
        
        // Сначала проверяем дубликаты
        checkForDuplicates({ leadId: this.recordId })
            .then(duplicateResult => {
                if (duplicateResult.success) {
                    this.duplicateInfo = duplicateResult;
                    
                    // Если найдены дубликаты, показываем предупреждение
                    if (duplicateResult.hasExistingAccount || duplicateResult.hasExistingContact) {
                        this.showDuplicateWarning = true;
                        this.isConverting = false;
                        return;
                    }
                }
                
                // Если дубликатов нет, продолжаем конвертацию
                return this.performConversion();
            })
            .catch(error => {
                this.isConverting = false;
                this.showToast('Error', 'Failed to check for duplicates: ' + error.body.message, 'error');
            });
    }
    
    // Выполнение конвертации
    performConversion() {
        return startLeadConversion({ leadId: this.recordId })
            .then(result => {
                this.isConverting = false;
                if (result.success) {
                    this.isSuccess = true;
                    this.showToast('Success', 'Lead converted successfully!', 'success');
                } else {
                    // Показываем более подробную информацию об ошибке
                    let errorMessage = result.message || 'Conversion failed';
                    if (errorMessage.includes('DUPLICATES_DETECTED')) {
                        errorMessage = 'Duplicate records detected. The system found existing Account or Contact with the same information. Please check for existing records with the same email or company name.';
                    }
                    this.showToast('Error', errorMessage, 'error');
                }
            })
            .catch(error => {
                this.isConverting = false;
                let errorMessage = 'Conversion failed: ' + error.body.message;
                if (error.body.message && error.body.message.includes('DUPLICATES_DETECTED')) {
                    errorMessage = 'Duplicate records detected. The system found existing Account or Contact with the same information. Please check for existing records with the same email or company name.';
                }
                this.showToast('Error', errorMessage, 'error');
            });
    }
    
    // Обработка подтверждения конвертации с дубликатами
    handleConfirmConversionWithDuplicates() {
        this.showDuplicateWarning = false;
        this.performConversion();
    }
    
    // Обработка отмены конвертации с дубликатами
    handleCancelConversionWithDuplicates() {
        this.showDuplicateWarning = false;
        this.isConverting = false;
    }
    
    // Просмотр существующего Account
    handleViewAccount(event) {
        const accountId = event.currentTarget.dataset.id;
        this.navigateToRecord(accountId);
    }
    
    // Просмотр существующего Contact
    handleViewContact(event) {
        const contactId = event.currentTarget.dataset.id;
        this.navigateToRecord(contactId);
    }
    
    // Навигация к записи
    navigateToRecord(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        });
    }

    // Handle back button
    handleBack() {
        this.currentStep = 1;
    }

    // Handle cancel button
    handleCancel() {
        if (this.isAutoOpen && this.previousStatus) {
            // Если это автоматическое открытие, возвращаем к предыдущему статусу
            this.returnToPreviousStatus();
        } else {
            this.closeModal();
        }
    }

    // Handle close button
    handleClose() {
        if (this.isAutoOpen && this.previousStatus) {
            // Если это автоматическое открытие, возвращаем к предыдущему статусу
            this.returnToPreviousStatus();
        } else {
            this.closeModal();
        }
    }

    // Return to previous status
    returnToPreviousStatus() {
        const recordInput = { 
            fields: { 
                Id: this.recordId, 
                Status: this.previousStatus 
            } 
        };
        
        updateRecord(recordInput)
            .then(() => {
                this.showToast('Info', 'Lead returned to previous status', 'info');
                this.closeModal();
                return refreshApex(this.wiredLeadResult);
            })
            .catch(error => {
                this.showToast('Error', 'Failed to return to previous status: ' + error.body.message, 'error');
            });
    }

    // Handle modal click to prevent closing when clicking inside
    handleModalClick(event) {
        event.stopPropagation();
    }

    // Close modal
    closeModal() {
        this.showModal = false;
        this.currentStep = 1;
        this.isSuccess = false;
        this.dispatchEvent(new CustomEvent('close'));
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