import { LightningElement } from 'lwc';

export default class GetCreditReport extends LightningElement {
    async handleButtonClick() {
        const url = '';
        const response = await fetch(url);
        const data = await response.json();
        window.location.href = data.report_url;
    }
}