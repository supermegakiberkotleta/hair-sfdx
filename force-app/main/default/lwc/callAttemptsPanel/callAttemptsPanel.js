import { LightningElement, wire, track } from 'lwc';
import getCampaigns from '@salesforce/apex/CallAttemptsPanelController.getCampaigns';
import getTelephonyBaseUrl from '@salesforce/apex/CallAttemptsPanelController.getTelephonyBaseUrl';

export default class CallAttemptsPanel extends LightningElement {
    @track selectedCampaignId;
    @track campaigns = [];
    @track iframeUrl = '';
    @track isLoading = true;
    @track error;

    connectedCallback() {
        // Загружаем сохраненную кампанию из localStorage
        this.loadSelectedCampaign();
    }

    @wire(getCampaigns)
    wiredCampaigns({ error, data }) {
        if (data) {
            this.campaigns = data;
            this.isLoading = false;
            
            // If no saved campaign, select the most recent one
            if (!this.selectedCampaignId && this.campaigns.length > 0) {
                this.selectedCampaignId = this.campaigns[0].Id;
                this.saveSelectedCampaign();
                this.buildIframeUrl();
            } else if (this.selectedCampaignId) {
                // If we have a saved campaign, build URL immediately
                this.buildIframeUrl();
            }
        } else if (error) {
            this.error = 'Error loading campaigns: ' + error.body.message;
            this.isLoading = false;
        }
    }

    loadSelectedCampaign() {
        const savedCampaignId = localStorage.getItem('selectedAutodialCampaignId');
        if (savedCampaignId) {
            this.selectedCampaignId = savedCampaignId;
        }
    }

    saveSelectedCampaign() {
        if (this.selectedCampaignId) {
            localStorage.setItem('selectedAutodialCampaignId', this.selectedCampaignId);
        }
    }

    handleCampaignChange(event) {
        this.selectedCampaignId = event.detail.value;
        this.saveSelectedCampaign();
        this.buildIframeUrl();
    }

    async buildIframeUrl() {
        if (!this.selectedCampaignId) return;
        
        try {
            const baseUrl = await getTelephonyBaseUrl();
            this.iframeUrl = `${baseUrl}/autodial/mobile-attempts?id=${this.selectedCampaignId}`;
        } catch (error) {
            this.error = 'Error getting URL: ' + error.body.message;
        }
    }

    get showIframe() {
        return !this.isLoading && !this.error && this.iframeUrl;
    }

    handleIframeLoad() {
        this.isLoading = false;
    }

    handleIframeError() {
        this.error = 'Failed to load call attempts data. Please check if the URL is accessible.';
        this.isLoading = false;
    }
}
