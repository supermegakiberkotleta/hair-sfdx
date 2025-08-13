import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendNotification from '@salesforce/apex/NotificationController.sendNotification';
import USER_ID from '@salesforce/user/Id';

export default class BacklogScoringButton extends LightningElement {
    @api recordId;
    @track lastSyncTime = '';
    @track isProcessing = false;
    currentUserId = USER_ID;

    connectedCallback() {
        // Загружаем время последней синхронизации из localStorage
        this.loadLastSyncTime();
    }

    loadLastSyncTime() {
        const stored = localStorage.getItem('lastBacklogScoringTime');
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
        localStorage.setItem('lastBacklogScoringTime', now);
    }

    async handleClick() {
        if (this.isProcessing) {
            return;
        }

        this.isProcessing = true;

        try {
            const response = await fetch('https://lenderpro.itprofit.net/api/v1/scoring-parser', {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json'
                }
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            // Проверяем, есть ли содержимое в ответе
            const responseText = await response.text();
            
            let result = {};
            if (responseText && responseText.trim()) {
                try {
                    result = JSON.parse(responseText);
                } catch (parseError) {
                    console.warn('Failed to parse JSON response:', parseError);
                    // Если JSON невалидный, используем пустой объект
                }
            }
            
            // Сохраняем время синхронизации
            this.saveLastSyncTime();

            // Показываем уведомление об успехе
            this.showToast(
                'Scoring Completed', 
                `Backlog scoring is completed.`, 
                'success'
            );

            // Отправляем уведомление пользователю
            this.sendNotification('Scoring Completed', 'Backlog scoring is completed.', 'success');

        } catch (error) {
            console.error('Ошибка при запуске скоринга:', error);
            this.showToast(
                'Scoring Error', 
                'Failed to backlog scoring. Please try again later.', 
                'error'
            );
            
            // Отправляем уведомление об ошибке
            this.sendNotification('Scoring Error', 'Failed to backlog scoring. Please try again later.', 'error');
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
        window.open('https://docs.google.com/spreadsheets/d/1hL7vyNEomSaAoCiNq5Jto_NZSGl5VcVfrbWRg4TZ8gU/edit?gid=0#gid=0', '_blank');
    }

    async sendNotification(title, message, type) {
        try {
            // Отправляем уведомление через Apex контроллер с текущим ID пользователя
            await sendNotification({ 
                title: title, 
                message: message, 
                type: type,
                userId: this.currentUserId,
                targetId: this.recordId
            });
                        
        } catch (error) {
            console.error('Ошибка отправки уведомления:', error);
        }
    }
}