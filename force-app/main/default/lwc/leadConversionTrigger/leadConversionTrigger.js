import { LightningElement, api, track, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import startLeadConversion from '@salesforce/apex/LeadConversionController.startLeadConversion';
import checkForDuplicates from '@salesforce/apex/LeadConversionController.checkForDuplicates';

export default class LeadConversionTrigger extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showModal = false;
    @track currentStep = 1;
    @track isConverting = false;
    @track leadData;
    @track wiredLeadResult;
    @track duplicateInfo = null;
    @track showDuplicateWarning = false;
    @track conversionResult = null;
    @track suppressToasts = false;
    @track previousStatus = null;
    @track isInitialized = false;

    // Computed properties for step visibility
    get isValidationStep() {
        return this.currentStep === 1;
    }

    get isConversionStep() {
        return this.currentStep === 2;
    }

    get isResultStep() {
        return this.currentStep === 3;
    }

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
            'Lead.RecordTypeId',
            'Lead.FirstName',
            'Lead.LastName'
        ] 
    })
    wiredLead(result) {
        this.wiredLeadResult = result;
        if (result.data) {
            this.leadData = result.data;
            const currentStatus = result.data.fields.Status.value;
            
            // Проверяем изменение статуса на "Call after"
            if (this.isInitialized && 
                currentStatus === 'Call after' && 
                this.previousStatus && 
                this.previousStatus !== 'Call after') {
                
                // Проверяем RecordType (должен быть Loan_Leads)
                const recordTypeId = result.data.fields.RecordTypeId.value;
                if (recordTypeId === '012Kc000000tenuIAA') {
                    this.showModal = true;
                    this.currentStep = 1;
                    this.isConverting = false;
                    this.conversionResult = null;
                    this.duplicateInfo = null;
                    this.showDuplicateWarning = false;
                }
            }
            
            this.previousStatus = currentStatus;
            this.isInitialized = true;
        } else if (result.error) {
            this.showToast('Error', 'Failed to load lead data', 'error');
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
        this.suppressToasts = true;
        
        // Сначала проверяем дубликаты
        checkForDuplicates({ leadId: this.recordId })
            .then(duplicateResult => {
                if (duplicateResult.success) {
                    this.duplicateInfo = duplicateResult;
                    
                    // Если найдены дубликаты, показываем предупреждение
                    if (duplicateResult.hasExistingAccount || duplicateResult.hasExistingContact) {
                        this.showDuplicateWarning = true;
                        this.isConverting = false;
                        this.suppressToasts = false;
                        return;
                    }
                }
                
                // Если дубликатов нет, продолжаем конвертацию
                return this.performConversion();
            })
            .catch(error => {
                this.isConverting = false;
                this.suppressToasts = false;
                this.showToast('Error', 'Failed to check for duplicates: ' + error.body.message, 'error');
            });
    }
    
    // Выполнение конвертации
    performConversion() {
        return startLeadConversion({ leadId: this.recordId })
            .then(result => {
                this.isConverting = false;
                this.suppressToasts = false;
                
                if (result.success) {
                    this.conversionResult = result;
                    this.currentStep = 3;
                    this.showToast('Success', 'Lead converted successfully!', 'success');
                } else {
                    let errorMessage = result.message || 'Conversion failed';
                    if (errorMessage.includes('DUPLICATES_DETECTED')) {
                        errorMessage = 'Duplicate records detected. The system found existing Account or Contact with the same information. Please check for existing records with the same email or company name.';
                    }
                    this.showToast('Error', errorMessage, 'error');
                }
            })
            .catch(error => {
                this.isConverting = false;
                this.suppressToasts = false;
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
        this.suppressToasts = true;
        this.performConversion();
    }
    
    // Обработка отмены конвертации с дубликатами
    handleCancelConversionWithDuplicates() {
        this.showDuplicateWarning = false;
        this.isConverting = false;
        this.suppressToasts = false;
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
    
    // Просмотр созданного Opportunity
    handleViewOpportunity(event) {
        const opportunityId = event.currentTarget.dataset.id;
        this.navigateToRecord(opportunityId);
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
        if (this.previousStatus) {
            this.returnToPreviousStatus();
        } else {
            this.closeModal();
        }
    }

    // Handle close button
    handleClose() {
        if (this.previousStatus) {
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
        this.conversionResult = null;
    }

    // Show toast message (with suppression check)
    showToast(title, message, variant) {
        if (this.suppressToasts) return;
        
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}