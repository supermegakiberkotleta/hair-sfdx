import { LightningElement, api, wire, track } from 'lwc';
import getIterations from '@salesforce/apex/AutodialCampaignIterationController.getIterations';

export default class AutodialCampaignIterations extends LightningElement {
    @api recordId;
    @track iterations = [];
    isLoading = true;
    activeSectionNames = [];

    @wire(getIterations, { campaignId: '$recordId' })
    wiredIterations({ error, data }) {
        if (data) {
            this.iterations = data.map((it) => ({
                ...it,
                startDate: it.startDate ? new Date(it.startDate).toLocaleString() : '',
                endDate: it.endDate ? new Date(it.endDate).toLocaleString() : ''
            }));
            this.activeSectionNames = this.iterations.map(i => i.id);
            this.isLoading = false;
        } else if (error) {
            // eslint-disable-next-line no-console
            console.error(error);
            this.iterations = [];
            this.isLoading = false;
        }
    }

    get hasData() {
        return !this.isLoading && this.iterations && this.iterations.length > 0;
    }

    get hasNoData() {
        return !this.isLoading && (!this.iterations || this.iterations.length === 0);
    }
}


