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
            // sort by orderNumber then name for stable display
            const sorted = [...data].sort((a, b) => {
                const ao = a.orderNumber ?? Number.MAX_SAFE_INTEGER;
                const bo = b.orderNumber ?? Number.MAX_SAFE_INTEGER;
                if (ao !== bo) return ao - bo;
                return (a.name || '').localeCompare(b.name || '');
            });

            this.iterations = sorted.map((it) => ({
                ...it,
                startDate: it.startDate ? new Date(it.startDate).toLocaleString() : '',
                endDate: it.endDate ? new Date(it.endDate).toLocaleString() : ''
            }));
            // Keep sections collapsed by default for a cleaner initial view
            this.activeSectionNames = [];
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


