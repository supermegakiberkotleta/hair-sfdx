import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SyncLoanButton extends LightningElement {
    @api recordId;
    @track lastSyncTime = '';
    @track isProcessing = false;

    connectedCallback() {
        // Загружаем время последней синхронизации из localStorage
        this.loadLastSyncTime();
    }

    loadLastSyncTime() {
        const stored = localStorage.getItem('lastSyncTime');
        if (stored) {
            this.lastSyncTime = stored;
        }
    }

    saveLastSyncTime() {
        const now = new Date().toLocaleString('en-US', {
            timeZone: 'America/New_York',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });
        this.lastSyncTime = now;
        localStorage.setItem('lastSyncTime', now);
    }

    async handleClick() {
        if (this.isProcessing) {
            return;
        }

        this.isProcessing = true;

        try {
            const response = await fetch('https://lenderpro.itprofit.net/api/v1/parse-sheet', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const result = await response.json();
            
            // Сохраняем время синхронизации
            this.saveLastSyncTime();

            // Показываем уведомление об успехе
            this.showToast(
                'Sync Started', 
                `Data processing started in background mode. Records to process: ${result.total_rows_to_process || 0}`, 
                'success'
            );

            console.log('Ответ от API:', result);

        } catch (error) {
            console.error('Ошибка при синхронизации:', error);
            this.showToast(
                'Sync Error', 
                'Failed to start synchronization. Please try again later.', 
                'error'
            );
        } finally {
            this.isProcessing = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }

    openSpreadsheet() {
        window.open('https://docs.google.com/spreadsheets/d/1l1OTJskRYTGpKBNAchoPixOtE2SbMJMdilIUoAiEFsg', '_blank');
    }
} 