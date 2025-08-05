import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import startLeadConversion from '@salesforce/apex/LeadConversionController.startLeadConversion';
import checkForDuplicates from '@salesforce/apex/LeadConversionController.checkForDuplicates';

export default class LeadConversionAction extends NavigationMixin(LightningElement) {
    @api recordId;
    @track currentStep = 1;
    @track isConverting = false;
    @track isSuccess = false;
    @track leadData;
    @track wiredLeadResult;
    @track duplicateInfo = null;
    @track showDuplicateWarning = false;
    @track conversionResult = null;
    @track suppressToasts = false;

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
            'Lead.RecordTypeId',
            'Lead.FirstName',
            'Lead.LastName'
        ] 
    })
    wiredLead(result) {
        this.wiredLeadResult = result;
        if (result.data) {
            this.leadData = result.data;
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
        this.currentStep = 1;
        this.isSuccess = false;
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