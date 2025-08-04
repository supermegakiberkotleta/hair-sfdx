import { LightningElement, api } from 'lwc';
import sendOpportunityId from '@salesforce/apex/GenerateReportController.sendOpportunityId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SendOpportunityIdButton extends LightningElement {
    @api recordId;
    isLoading = false;

    handleClick() {
        if (!this.recordId) {
            this.showToast('Ошибка', 'ID Opportunity не найден', 'error');
            return;
        }

        this.isLoading = true;

        sendOpportunityId({ opportunityId: this.recordId })
            .then(result => {
                console.log('Ответ:', result);
                this.showToast('Успех', result, 'success');
            })
            .catch(error => {
                console.error('Ошибка:', error);
                const message = error?.body?.message || error?.message || 'Не удалось отправить Opportunity ID';
                this.showToast('Ошибка', message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}