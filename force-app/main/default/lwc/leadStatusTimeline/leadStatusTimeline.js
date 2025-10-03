import { LightningElement, api, wire } from 'lwc';
import getLeadStatusDurations from '@salesforce/apex/LeadStatusService.getLeadStatusDurations';

export default class LeadStatusTimeline extends LightningElement {
    @api recordId; // Id лида
    statusData = [];
    error;

    @wire(getLeadStatusDurations, { leadId: '$recordId' })
    wiredStatuses({ error, data }) {
        if (data) {
            this.statusData = data.map((item, index) => {
                // Форматируем даты
                const entered = new Date(item.EnteredDate).toLocaleString();
                const exited = new Date(item.ExitedDate).toLocaleString();

                // Генерируем уникальный, безопасный key
                const key = `${item.Status}_${entered}_${index}`
                    .replace(/\s+/g, '_')
                    .replace(/[^a-zA-Z0-9_]/g, '');

                // Форматируем длительность как "X ч Y мин"
                const totalMinutes = item.DurationMinutes;
                const hours = Math.floor(totalMinutes / 60);
                const minutes = totalMinutes % 60;
                const formattedDuration = `${hours} ч ${minutes} мин`;

                return {
                    Status: item.Status,
                    EnteredDate: entered,
                    ExitedDate: exited,
                    DurationDays: item.DurationDays.toFixed(1),
                    DurationHours: item.DurationHours,
                    DurationMinutes: item.DurationMinutes,
                    FormattedDuration: formattedDuration, // ← новое поле для отображения
                    key
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.statusData = [];
        }
    }
}