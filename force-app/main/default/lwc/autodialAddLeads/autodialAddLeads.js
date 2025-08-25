import { LightningElement, api, track } from 'lwc';
import searchLeads from '@salesforce/apex/AutodialCampaignMemberController.searchLeads';
import searchContacts from '@salesforce/apex/AutodialCampaignMemberController.searchContacts';
import searchAccounts from '@salesforce/apex/AutodialCampaignMemberController.searchAccounts';
import addMembersGeneric from '@salesforce/apex/AutodialCampaignMemberController.addMembersGeneric';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AutodialAddLeads extends LightningElement {
	@api recordId; // Autodial_Campaign__c Id
	@track searchText = '';
	@track rows = [];
	@track selectedRowIds = [];
	@track message = '';
	@track loading = false;
	@track adding = false;
	@track entityType = 'lead'; // lead | contact | account

	get entityOptions() {
		return [
			{ label: 'Leads', value: 'lead' },
			{ label: 'Contacts', value: 'contact' },
			{ label: 'Accounts', value: 'account' }
		];
	}

	_debounceTimer;

	get columns() {
		switch (this.entityType) {
			case 'contact':
				return [
					{ label: 'Name', fieldName: 'name', type: 'text' },
					{ label: 'Account', fieldName: 'accountName', type: 'text' },
					{ label: 'Phone', fieldName: 'phone', type: 'phone' },
					{ label: 'Email', fieldName: 'email', type: 'email' },
					{ label: 'Owner', fieldName: 'ownerName', type: 'text' }
				];
			case 'account':
				return [
					{ label: 'Name', fieldName: 'name', type: 'text' },
					{ label: 'Phone', fieldName: 'phone', type: 'phone' },
					{ label: 'Owner', fieldName: 'ownerName', type: 'text' }
				];
			case 'lead':
			default:
				return [
					{ label: 'Name', fieldName: 'name', type: 'text' },
					{ label: 'Company', fieldName: 'company', type: 'text' },
					{ label: 'Phone', fieldName: 'phone', type: 'phone' },
					{ label: 'Email', fieldName: 'email', type: 'email' },
					{ label: 'Status', fieldName: 'status', type: 'text' },
					{ label: 'Owner', fieldName: 'ownerName', type: 'text' }
				];
		}
	}

	get disableAdd() {
		return this.adding || !this.selectedRowIds || this.selectedRowIds.length === 0;
	}

	get titleText() {
		switch (this.entityType) {
			case 'contact': return 'Add Contacts to Campaign';
			case 'account': return 'Add Accounts to Campaign';
			default: return 'Add Leads to Campaign';
		}
	}

	get searchLabel() {
		switch (this.entityType) {
			case 'contact': return 'Search Contacts';
			case 'account': return 'Search Accounts';
			default: return 'Search Leads';
		}
	}

	get searchPlaceholder() {
		switch (this.entityType) {
			case 'contact': return 'Search by Name, Account, Email, Phone';
			case 'account': return 'Search by Name, Phone';
			default: return 'Search by Name, Company, Email, Phone';
		}
	}

	connectedCallback() {
		// initial results
		this.performSearch();
	}

	handleEntityTypeChange(event) {
		this.entityType = event.detail.value;
		this.selectedRowIds = [];
		// refresh results for new entity
		this.performSearch();
	}

	handleSearchChange(event) {
		this.searchText = event.target.value;
		// debounce
		window.clearTimeout(this._debounceTimer);
		this._debounceTimer = window.setTimeout(() => {
			this.performSearch();
		}, 320);
	}

	async performSearch() {
		this.loading = true;
		try {
			if (this.entityType === 'lead') {
				this.rows = await searchLeads({ searchText: this.searchText, limitSize: 20 });
			} else if (this.entityType === 'contact') {
				this.rows = await searchContacts({ searchText: this.searchText, limitSize: 20 });
			} else if (this.entityType === 'account') {
				this.rows = await searchAccounts({ searchText: this.searchText, limitSize: 20 });
			}
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
		this.adding = true;
		try {
			const res = await addMembersGeneric({ campaignId: this.recordId, entityType: this.entityType, recordIds: this.selectedRowIds });
			if (res && res.success) {
				this.message = res.message;
				this.showToast('Success', res.message, 'success');
				// Очищаем выбор после успешного добавления
				this.selectedRowIds = [];
				const dt = this.template.querySelector('lightning-datatable');
				if (dt) { dt.selectedRows = []; }
				this.performSearch(); // Обновляем список
				
				// Отправляем событие об успешном добавлении
				this.dispatchEvent(new CustomEvent('success', {
					detail: { message: res.message }
				}));
			} else {
				this.showToast('Error', (res && res.message) ? res.message : 'Add failed', 'error');
			}
		} catch (e) {
			this.showToast('Error', e.body && e.body.message ? e.body.message : 'Add failed', 'error');
		} finally {
			this.adding = false;
		}
	}

	showToast(title, message, variant) {
		this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
	}

	handleClose() {
		// Закрываем модальное окно
		this.dispatchEvent(new CloseActionScreenEvent());
	}
}