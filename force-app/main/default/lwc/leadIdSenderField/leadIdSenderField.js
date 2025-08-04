import { LightningElement, api } from 'lwc';
import sendLeadIdToEndpoint from '@salesforce/apex/LeadIdSender.sendLeadIdToEndpoint';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadIdSenderField extends LightningElement {
    @api recordId;
    isLoading = false;

    get buttonLabel() {
        return this.isLoading ? 'Генерация...' : 'Сгенерировать ссылку';
    }

    get buttonVariant() {
        return this.isLoading ? 'neutral' : 'brand';
    }

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
                const message = error?.body?.message || error?.message || 'Не удалось сгенерировать ссылку';
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