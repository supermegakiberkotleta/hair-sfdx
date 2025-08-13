import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import sendNotification from '@salesforce/apex/NotificationController.sendNotification';
import USER_ID from '@salesforce/user/Id';

export default class LeadButtons extends LightningElement {
    @api recordId;
    currentUserId = USER_ID;

    async handleClick() {
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
}