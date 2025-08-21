import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import DISABLE_FIELD from '@salesforce/schema/Opportunity.Disable_c__c';

export default class DisableAutoTaskToggle extends LightningElement {
	@api recordId;
	@api label = 'Auto-notifications';
	@api checked;
	saving = false;

	connectedCallback() {
		// По умолчанию тумблер включен, пока не загрузится значение из записи
		if (this.checked === undefined) {
			this.checked = true;
		}
	}

	@wire(getRecord, { recordId: '$recordId', fields: [DISABLE_FIELD] })
	wireRecord({ data, error }) {
		if (data) {
			// Переключатель повторяет значение поля Disable_c__c
			this.checked = data.fields.Disable_c__c.value === true;
		} else if (error) {
			this.dispatchEvent(
				new ShowToastEvent({ title: 'Error', message: 'Failed to load field', variant: 'error' })
			);
		}
	}

	async handleChange(event) {
		this.checked = event.target.checked;
		const fields = {};
		fields[ID_FIELD.fieldApiName] = this.recordId;
		// Сохраняем напрямую значение переключателя в Disable_c__c
		fields[DISABLE_FIELD.fieldApiName] = this.checked;
		this.saving = true;
		try {
			await updateRecord({ fields });
			this.dispatchEvent(
				new ShowToastEvent({ title: 'Saved', message: 'Updated successfully', variant: 'success' })
			);
			this.dispatchEvent(new CustomEvent('change', { detail: { value: this.checked } }));
		} catch (e) {
			this.dispatchEvent(
				new ShowToastEvent({ title: 'Error', message: 'Failed to update', variant: 'error' })
			);
		} finally {
			this.saving = false;
		}
	}
}