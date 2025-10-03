import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCampaigns from '@salesforce/apex/AutodialCampaignMemberController.getCampaigns';
import addMembersGeneric from '@salesforce/apex/AutodialCampaignMemberController.addMembersGeneric';

export default class AddToAutodialModal extends LightningElement {
    @api selectedRecords = [];
    @api recordType = '';
    @track selectedCampaignId = '';
    @track campaigns = [];
    @track isLoading = false;
    @track isProcessing = false;

    @wire(getCampaigns)
    wiredCampaigns({ error, data }) {
        if (data) {
            this.campaigns = data;
        } else if (error) {
            console.error('Error loading campaigns:', error);
            this.showToast('Error', 'Failed to load campaigns', 'error');
        }
    }

    get hasSelectedRecords() {
        return this.selectedRecords && this.selectedRecords.length > 0;
    }

    get selectedRecordsCount() {
        return this.selectedRecords ? this.selectedRecords.length : 0;
    }

    get recordTypeLabel() {
        switch (this.recordType) {
            case 'Lead':
                return 'leads';
            case 'Contact':
                return 'contacts';
            case 'Account':
                return 'accounts';
            case 'Opportunity':
                return 'opportunities';
            default:
                return 'records';
        }
    }

    get campaignOptions() {
        return this.campaigns.map(campaign => ({
            label: campaign.name,
            value: campaign.id
        }));
    }

    get isAddButtonDisabled() {
        return !this.selectedCampaignId || this.isProcessing;
    }

    handleCampaignChange(event) {
        this.selectedCampaignId = event.detail.value;
    }

    async handleAddToCampaign() {
        if (!this.selectedCampaignId || !this.hasSelectedRecords) {
            this.showToast('Error', 'Please select a campaign and ensure records are selected', 'error');
            return;
        }

        this.isProcessing = true;

        try {
            const recordIds = this.selectedRecords.map(record => record.id);
            const result = await addMembersGeneric({
                campaignId: this.selectedCampaignId,
                entityType: this.recordType.toLowerCase(),
                recordIds: recordIds
            });

            if (result.success) {
                this.showToast(
                    'Success', 
                    `Successfully added ${result.createdCount} ${this.recordTypeLabel.toLowerCase()} to campaign. ${result.skippedCount} were already in the campaign.`, 
                    'success'
                );
                this.dispatchEvent(new CustomEvent('success', {
                    detail: result
                }));
            } else {
                this.showToast('Error', result.message || 'Failed to add records to campaign', 'error');
            }
        } catch (error) {
            console.error('Error adding records to campaign:', error);
            this.showToast('Error', 'An unexpected error occurred while adding records to campaign', 'error');
        } finally {
            this.isProcessing = false;
        }
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}