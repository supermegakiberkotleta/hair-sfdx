import { LightningElement, api } from 'lwc';

export default class AutodialAddLeadsModalWrapper extends LightningElement {
	@api recordId;

	handleClose() {
		// Закрываем модальное окно
		this.dispatchEvent(new CustomEvent('close'));
	}

	handleSuccess(event) {
		// Закрываем модальное окно с результатом успеха
		this.dispatchEvent(new CustomEvent('close', { 
			detail: { success: true, message: event.detail.message } 
		}));
	}
}