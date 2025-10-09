import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

export default class CallAttemptsViewer extends LightningElement {
    @api recordId;
    baseUrl = 'https://telephony.lenderpro.ai';
    iframeUrl = '';
    isLoading = true;
    error;

    connectedCallback() {
        if (this.recordId) {
            this.buildIframeUrl();
        }
    }

    buildIframeUrl() {
        try {
            // Формируем URL для iframe с параметром id кампании
            this.iframeUrl = `${this.baseUrl}/autodial/call-attempts?id=${this.recordId}`;
            this.isLoading = false;
        } catch (error) {
            this.error = error.message;
            this.isLoading = false;
        }
    }

    get showIframe() {
        return !this.isLoading && !this.error && this.iframeUrl;
    }

    handleIframeLoad() {
        this.isLoading = false;
    }

    handleIframeError() {
        this.error = 'Не удалось загрузить данные о попытках звонков';
        this.isLoading = false;
    }
}


