import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecordsData from '@salesforce/apex/AutodialCampaignMemberController.getRecordsData';

export default class AddToAutodialAction extends LightningElement {
    @api recordId;
    @api selectedRecordIds;
    @track showModal = false;
    @track selectedRecords = [];
    @track recordType = '';

    connectedCallback() {
        console.log('AddToAutodialAction connected with recordId:', this.recordId);
        console.log('Selected record IDs:', this.selectedRecordIds);
        
        // Для list view action selectedRecordIds будет содержать выбранные записи
        // Для single record action recordId будет содержать одну запись
        let recordIds = this.selectedRecordIds || (this.recordId ? [this.recordId] : []);
        
        if (recordIds.length > 0) {
            this.recordType = this.getRecordType(recordIds[0]);
            this.loadSelectedRecords(recordIds);
        }
        
        this.showModal = true;
        // Добавляем обработчик клавиши Escape
        document.addEventListener('keydown', this.handleKeyDown.bind(this));
    }

    disconnectedCallback() {
        // Убираем обработчик при уничтожении компонента
        document.removeEventListener('keydown', this.handleKeyDown.bind(this));
    }

    getRecordType(recordId) {
        // Определяем тип записи по префиксу ID
        const prefix = recordId.substring(0, 3);
        switch (prefix) {
            case '00Q': // Lead
                return 'Lead';
            case '003': // Contact
                return 'Contact';
            case '001': // Account
                return 'Account';
            case '006': // Opportunity
                return 'Opportunity';
            default:
                return 'Unknown';
        }
    }

    async loadSelectedRecords(recordIds) {
        if (!recordIds || recordIds.length === 0) {
            return;
        }

        try {
            // Загружаем данные выбранных записей
            const records = await this.getRecordsData(recordIds, this.recordType);
            this.selectedRecords = records;
        } catch (error) {
            console.error('Error loading selected records:', error);
            this.showToast('Error', 'Failed to load selected records', 'error');
        }
    }

    async getRecordsData(recordIds, recordType) {
        try {
            const records = await getRecordsData({
                recordIds: recordIds,
                recordType: recordType
            });
            return records;
        } catch (error) {
            console.error('Error loading records data:', error);
            this.showToast('Error', 'Failed to load records data', 'error');
            return [];
        }
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
        // Закрываем action
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleSuccess(event) {
        console.log('Modal success, closing...', event.detail);
        this.showModal = false;
        this.showToast('Success', 'Records added to campaign successfully', 'success');
        // Закрываем action
        this.dispatchEvent(new CustomEvent('close'));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}