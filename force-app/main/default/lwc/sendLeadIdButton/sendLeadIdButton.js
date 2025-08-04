import { LightningElement, api } from 'lwc';
import sendLeadIdToEndpoint from '@salesforce/apex/LeadIdSender.sendLeadIdToEndpoint';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SendLeadIdButton extends LightningElement {
    @api recordId;
    isLoading = false;

    handleClick() {
        if (!this.recordId) {
            this.showToast('Ошибка', 'ID лида не найден', 'error');
            return;
        }

        this.isLoading = true;

        sendLeadIdToEndpoint({ leadId: this.recordId })
            .then(result => {
                console.log('Успешный ответ:', result);
                this.showToast('Успех', result, 'success');
            })
            .catch(error => {
                console.error('Ошибка:', error);
                const message = error?.body?.message || error?.message || 'Не удалось отправить ID лида на эндпоинт';
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