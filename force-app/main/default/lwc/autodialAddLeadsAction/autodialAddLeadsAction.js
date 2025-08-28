import { LightningElement, api, track } from 'lwc';

export default class AutodialAddLeadsAction extends LightningElement {
	@api recordId;
	@track showModal = false;

	connectedCallback() {
		console.log('AutodialAddLeadsAction connected with recordId:', this.recordId);
		this.showModal = true;
		// Добавляем обработчик клавиши Escape
		document.addEventListener('keydown', this.handleKeyDown.bind(this));
	}

	disconnectedCallback() {
		// Убираем обработчик при уничтожении компонента
		document.removeEventListener('keydown', this.handleKeyDown.bind(this));
	}

	handleKeyDown(event) {
		if (event.key === 'Escape') {
			this.handleClose();
		}
	}

	handleBackdropClick(event) {
		// Закрываем только при клике на backdrop, не на модальное окно
		if (event.target.classList.contains('custom-modal-overlay')) {
			this.handleClose();
		}
	}

	handleModalClick(event) {
		// Предотвращаем закрытие при клике на само модальное окно
		event.stopPropagation();
	}

	handleClose() {
		console.log('Closing modal...');
		this.showModal = false;
	}

	handleSuccess(event) {
		console.log('Modal success, closing...', event.detail);
		this.showModal = false;
		// Можно добавить дополнительную логику после успешного закрытия
	}

	// Метод для принудительного открытия модального окна (если нужно)
	openModal() {
		this.showModal = true;
	}
}