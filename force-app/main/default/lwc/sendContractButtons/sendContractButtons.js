import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SendContractButtons extends LightningElement {
    @api recordId; // This will be the Lead ID

    sendRequest(endpoint) {
        fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ lead_id: this.recordId })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Ошибка при отправке запроса');
            }
            return response.json();
        })
        .then(() => {
            this.showToast('Success', 'Contract sent successfully', 'success');
        })
        .catch(error => {
            this.showToast('Error', error.message, 'error');
        });
    }

    handleSendEdu() {
        this.sendRequest('https://lenderpro.stoliarov.itprofit.net/api/v1/docusign/sendmail-docusign-edulevator');
    }

    handleSendBoostra() {
        this.sendRequest('https://lenderpro.stoliarov.itprofit.net/api/v1/docusign/sendmail-docusign-bootstra');
    }

    handleSendLiberty() {
        this.sendRequest('https://lenderpro.stoliarov.itprofit.net/api/v1/docusign/sendmail-docusign-liberty');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
