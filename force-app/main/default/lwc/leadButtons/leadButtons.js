import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadButtons extends LightningElement {
    @api recordId;

    ResendToOcrolus() {
        const url = 'https://lenderpro.ai/api/v1/webhook/re-send-ocrolus';
        const payload = { leadId: this.recordId };

        fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`Ошибка сети: ${response.status} ${response.statusText}`);
            }
            return response.json(); // или response.text(), если ответ не JSON
        })
        .then(data => {
            console.log('Успех:', data);
            this.showToast('Успех', 'Данные успешно отправлены', 'success');
        })
        .catch(error => {
            console.error('Ошибка:', error);
            this.showToast('Ошибка', 'Не удалось отправить данные', 'error');
        });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}