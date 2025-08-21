import { LightningElement, api } from 'lwc';
import sendLeadId from '@salesforce/apex/GenerateReportController.sendLeadId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SendLeadButton extends LightningElement {
    @api recordId;

    handleClick() {
        if (!this.recordId) {
            this.showToast('Ошибка', 'ID лида не найден', 'error');
            return;
        }

        this.showToast('Уведомление', 'Отчёт отправлен на формирование', 'info');

        sendLeadId({ leadId: this.recordId })
            .then(result => {
                console.log('Ответ:', result);
                this.showToast('Успех', result || 'Отчёт сформирован', 'success');
            })
            .catch(error => {
                console.error('Ошибка:', error);
                const message = error?.body?.message || error?.message || 'Не удалось отправить Lead ID';
                this.showToast('Ошибка', message, 'error');
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