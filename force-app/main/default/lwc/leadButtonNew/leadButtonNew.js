import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import sendNotification from '@salesforce/apex/NotificationController.sendNotification';
import USER_ID from '@salesforce/user/Id';
import REASON_FIELD from '@salesforce/schema/Lead.Reason_for_Send_to_onloan_second__c';

export default class LeadButtons extends LightningElement {
    @api recordId;
    currentUserId = USER_ID;
    reasonFieldValue;
    hasValidationError = false;

    @wire(getRecord, { recordId: '$recordId', fields: [REASON_FIELD] })
    wiredLead({ error, data }) {
        if (data) {
            const newValue = getFieldValue(data, REASON_FIELD);
            this.reasonFieldValue = newValue;
            
            // Сбрасываем ошибку валидации, если поле заполнено
            if (newValue && newValue.trim() !== '') {
                this.hasValidationError = false;
            }
        } else if (error) {
            console.error('Error loading lead record:', error);
        }
    }

    async handleClick() {
        // Валидация поля Reason_for_Send_to_onloan_second__c
        if (!this.reasonFieldValue || this.reasonFieldValue.trim() === '') {
            this.hasValidationError = true;
            this.showToast('Validation Error', 'Field "Reason for Send to onloan second" is required. Please fill it before proceeding.', 'error');
            
            // Отправляем уведомление об ошибке валидации
            this.sendNotification('Validation Error', 'Field "Reason for Send to onloan second" is required', 'error');
            
            // Подсвечиваем поле для заполнения
            this.highlightField();
            return;
        }

        const url = 'https://lenderpro.ai/api/v1/webhook/re-send-ocrolus';
        const payload = { leadId: this.recordId };

        // Toast at start of sending
        this.showToast('Sending Data', 'Sending data to Ocrolus...', 'info');

        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(payload)
            });

            if (!response.ok) {
                throw new Error(`Network error: ${response.status} ${response.statusText}`);
            }

        
            const data = await response.json();
            console.log('API Response:', data);

            // Check processing result
            if (data.success || data.status === 'success' || (data.message && data.message.toLowerCase().includes('success'))) {
                // Toast on successful processing
                this.showToast('Ocrolus Sync', 'Ocrolus sync completed', 'success');
                
                // Send notification to user
                this.sendNotification('Ocrolus sync completed', 'Lead data has been successfully processed by Ocrolus', 'success');
            } else {
                // Toast on unsuccessful processing
                const errorMessage = data.message || data.error || 'Unknown error occurred';
                this.showToast('Ocrolus Sync', `Ocrolus sync failed: ${errorMessage}`, 'error');
                
                // Send notification to user
                this.sendNotification('Ocrolus sync failed', `Lead data processing failed: ${errorMessage}`, 'error');
            }

        } catch (error) {
            console.error('Error:', error);
            
            // Toast on sending error
            this.showToast('Sending Data', `Sending error: ${error.message}`, 'error');
            
            // Toast on processing error
            this.showToast('Ocrolus Sync', `Ocrolus sync failed: ${error.message}`, 'error');
            
            // Send notification to user
            this.sendNotification('Ocrolus sync failed', `Failed to send data: ${error.message}`, 'error');
        }
    }

    highlightField() {
        // Отправляем событие для подсветки поля в родительском компоненте
        const highlightEvent = new CustomEvent('highlightfield', {
            detail: {
                fieldName: 'Reason_for_Send_to_onloan_second__c',
                recordId: this.recordId,
                action: 'highlight_red'
            }
        });
        this.dispatchEvent(highlightEvent);
        
        // Также пытаемся подсветить поле напрямую через DOM
        this.highlightFieldDirectly();
        
        console.log('Field highlighting requested for:', this.recordId);
    }

    highlightFieldDirectly() {
        // Попытка найти и подсветить поле напрямую
        try {
            // Ищем поле по label или name
            const fieldLabels = this.template.querySelectorAll('label, .slds-form-element__label');
            let targetField = null;
            
            fieldLabels.forEach(label => {
                if (label.textContent && label.textContent.toLowerCase().includes('reason for send to onloan second')) {
                    // Находим связанное поле
                    const fieldElement = label.closest('.slds-form-element')?.querySelector('input, textarea, select, .slds-input, .slds-textarea');
                    if (fieldElement) {
                        targetField = fieldElement;
                    }
                }
            });
            
            if (targetField) {
                // Подсвечиваем поле красным
                targetField.style.border = '2px solid #c23934';
                targetField.style.backgroundColor = '#fef7f7';
                targetField.style.boxShadow = '0 0 0 1px #c23934';
                
                // Добавляем анимацию мигания
                targetField.style.animation = 'blink 1s ease-in-out 3';
                
                console.log('Field highlighted directly:', targetField);
            }
        } catch (error) {
            console.log('Direct field highlighting failed, using event-based approach:', error);
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    async sendNotification(title, message, type) {
        try {
            // Send notification via Apex controller with current user ID and lead record ID as target
            await sendNotification({ 
                title: title, 
                message: message, 
                type: type,
                userId: this.currentUserId,
                targetId: this.recordId
            });
            
            console.log('Notification sent successfully to user:', this.currentUserId, 'for lead:', this.recordId);
            
        } catch (error) {
            console.error('Error sending notification:', error);
        }
    }

    resetValidationError() {
        this.hasValidationError = false;
    }

    get buttonClass() {
        return this.hasValidationError 
            ? 'slds-button slds-button_destructive' 
            : 'slds-button slds-button_brand';
    }
}