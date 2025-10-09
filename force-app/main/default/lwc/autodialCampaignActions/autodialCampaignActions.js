import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import startCampaign from '@salesforce/apex/AutodialCampaignApiController.startCampaign';
import pauseCampaign from '@salesforce/apex/AutodialCampaignApiController.pauseCampaign';
import cancelCampaign from '@salesforce/apex/AutodialCampaignApiController.cancelCampaign';
import completeCampaign from '@salesforce/apex/AutodialCampaignApiController.completeCampaign';

const FIELDS = [
    'Autodial_Campaign__c.Status__c',
    'Autodial_Campaign__c.Start_Date__c',
    'Autodial_Campaign__c.End_Date__c'
];

export default class AutodialCampaignActions extends LightningElement {
    @api recordId;
    campaign = {};
    isLoading = false;
    wiredCampaignResult;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredCampaign(result) {
        this.wiredCampaignResult = result;
        const { error, data } = result;
        
        if (data) {
            this.campaign = {
                Status__c: data.fields.Status__c?.value || '',
                Start_Date__c: data.fields.Start_Date__c?.value || null,
                End_Date__c: data.fields.End_Date__c?.value || null
            };
        } else if (error) {
            console.error('Error loading campaign data:', error);
            this.showToast('Error', 'Failed to load campaign data', 'error');
        }
    }

    get isStartDisabled() {
        const status = this.campaign?.Status__c || '';
        return this.isLoading || 
               status === 'In Progress' ||
               status === 'Canceled' ||
               status === 'Completed';
    }

    get isPauseDisabled() {
        const status = this.campaign?.Status__c || '';
        return this.isLoading || 
               status !== 'In Progress' ||
               status === 'Canceled' ||
               status === 'Completed';
    }

    get isCancelDisabled() {
        const status = this.campaign?.Status__c || '';
        return this.isLoading || 
               status === 'Canceled' ||
               status === 'Completed' ||
               status === 'Not Started';
    }

    get isCompleteDisabled() {
        const status = this.campaign?.Status__c || '';
        return this.isLoading || 
               status === 'Canceled' ||
               status === 'Completed' ||
               status === 'Not Started';
    }

    handleStart() {
        this.executeAction(startCampaign, 'starting');
    }

    handlePause() {
        this.executeAction(pauseCampaign, 'pausing');
    }

    handleCancel() {
        this.executeAction(cancelCampaign, 'cancelling');
    }

    handleComplete() {
        this.executeAction(completeCampaign, 'completing');
    }

    async executeAction(actionMethod, actionName) {
        this.isLoading = true;
        
        try {
            const result = await actionMethod({ campaignId: this.recordId });
            
            if (result.success) {
                this.showToast('Success', result.message, 'success');
                // Refresh the record to show updated values after a short delay
                setTimeout(() => {
                    this.refreshRecord();
                }, 1000);
            } else {
                // Use warning toast for validation errors (422), error for others
                const toastVariant = result.statusCode === 422 ? 'warning' : 'error';
                this.showToast(
                    `Error ${actionName} campaign (${result.statusCode})`, 
                    result.message, 
                    toastVariant
                );
            }
        } catch (error) {
            console.error('Action execution error:', error);
            let errorMessage = 'Unknown error occurred';
            
            if (error && error.body && error.body.message) {
                errorMessage = error.body.message;
            } else if (error && error.message) {
                errorMessage = error.message;
            } else if (typeof error === 'string') {
                errorMessage = error;
            }
            
            this.showToast(
                'Error', 
                `Failed to execute action: ${errorMessage}`, 
                'error'
            );
        } finally {
            this.isLoading = false;
        }
    }

    refreshRecord() {
        // Refresh the wired data using refreshApex
        if (this.wiredCampaignResult) {
            refreshApex(this.wiredCampaignResult);
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}

