import { LightningElement, api, track } from 'lwc';
import searchLeads from '@salesforce/apex/AutodialCampaignMemberController.searchLeads';
import addMembers from '@salesforce/apex/AutodialCampaignMemberController.addMembers';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AutodialAddLeads extends LightningElement {
	@api recordId; // Autodial_Campaign__c Id
	@track searchText = '';
	@track rows = [];
	@track selectedRowIds = [];
	@track message = '';
	@track loading = false;

	_debounceTimer;

	columns = [
		{ label: 'Name', fieldName: 'name', type: 'text' },
		{ label: 'Company', fieldName: 'company', type: 'text' },
		{ label: 'Phone', fieldName: 'phone', type: 'phone' },
		{ label: 'Email', fieldName: 'email', type: 'email' },
		{ label: 'Status', fieldName: 'status', type: 'text' },
		{ label: 'Owner', fieldName: 'ownerName', type: 'text' }
	];

	get disableAdd() {
		return !this.selectedRowIds || this.selectedRowIds.length === 0;
	}

	connectedCallback() {
		// initial results
		this.performSearch();
	}

	handleSearchChange(event) {
		this.searchText = event.target.value;
		// debounce
		window.clearTimeout(this._debounceTimer);
		this._debounceTimer = window.setTimeout(() => {
			this.performSearch();
		}, 350);
	}

	async performSearch() {
		this.loading = true;
		try {
			this.rows = await searchLeads({ searchText: this.searchText, limitSize: 50 });
			this.message = '';
		} catch (e) {
			this.showToast('Error', e.body && e.body.message ? e.body.message : 'Search failed', 'error');
		}
		this.loading = false;
	}

	handleRowSelection(event) {
		this.selectedRowIds = (event.detail && event.detail.selectedRows) ? event.detail.selectedRows.map(r => r.id) : [];
	}

	async handleAdd() {
		try {
			const res = await addMembers({ campaignId: this.recordId, leadIds: this.selectedRowIds });
			if (res && res.success) {
				this.message = res.message;
				this.showToast('Success', res.message, 'success');
				// Очищаем выбор после успешного добавления
				this.selectedRowIds = [];
				this.performSearch(); // Обновляем список
			} else {
				this.showToast('Error', (res && res.message) ? res.message : 'Add failed', 'error');
			}
		} catch (e) {
			this.showToast('Error', e.body && e.body.message ? e.body.message : 'Add failed', 'error');
		}
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}
}



