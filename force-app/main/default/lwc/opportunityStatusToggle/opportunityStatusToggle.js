import { LightningElement, api, wire } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ID_FIELD from '@salesforce/schema/Opportunity.Id';
import STATUS_FIELD from '@salesforce/schema/Opportunity.Opportunity_Status__c';
import callUpdateStatus from '@salesforce/apex/OpportunityStatusController.callUpdateStatus';

const FIELDS = [ID_FIELD, STATUS_FIELD];
const STATUS_PERFORMING = 'Performing';
const STATUS_COLLECTION = 'Collection';

export default class OpportunityStatusToggle extends LightningElement {
    @api recordId;
    @api label = 'Opportunity status';
    checked = true;
    isSaving = false;
    isLoaded = false;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    loadRecord({ data, error }) {
        if (data) {
            const statusValue = data.fields.Opportunity_Status__c.value;
            if (!statusValue || statusValue === STATUS_PERFORMING) {
                this.checked = true;
            } else {
                this.checked = false;
            }
            this.isLoaded = true;
        } else if (error) {
            this.isLoaded = true;
            this.dispatchEvent(new ShowToastEvent({ title: 'Ошибка', message: 'Не удалось загрузить запись', variant: 'error' }));
        }
    }

    get isDisabled() {
        return this.isSaving || !this.isLoaded;
    }

    get helpText() {
        return this.checked ? STATUS_PERFORMING : STATUS_COLLECTION;
    }

    async handleChange(event) {
        const previousChecked = this.checked;
        this.checked = event.target.checked;
        const newStatus = this.checked ? STATUS_PERFORMING : STATUS_COLLECTION;

        this.isSaving = true;
        try {
            // 1) Жмём внешний GET
            await callUpdateStatus({ opportunityId: this.recordId, selectedStatus: newStatus });

            // 2) Обновляем поле в Opportunity
            const fields = {};
            fields[ID_FIELD.fieldApiName] = this.recordId;
            fields[STATUS_FIELD.fieldApiName] = newStatus;

            await updateRecord({ fields });

            this.dispatchEvent(new ShowToastEvent({ title: 'Сохранено', message: `Статус: ${newStatus}`, variant: 'success' }));
            this.dispatchEvent(new CustomEvent('change', { detail: { value: newStatus } }));
        } catch (e) {
            // Откатываем визуальное состояние, если что-то пошло не так
            this.checked = previousChecked;
            const message = e && e.body && e.body.message ? e.body.message : 'Ошибка обновления статуса';
            this.dispatchEvent(new ShowToastEvent({ title: 'Ошибка', message, variant: 'error' }));
        } finally {
            this.isSaving = false;
        }
    }
}