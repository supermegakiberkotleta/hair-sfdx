import { LightningElement, api } from 'lwc';

export default class MessagesList extends LightningElement {
    @api recordId;

    messages = [];
    error = '';
    isLoading = false;
    noMessages = false;

    connectedCallback() {
        if (this.recordId) {
            this.fetchMessages();
        }
    }

    async fetchMessages() {
        this.isLoading = true;
        this.error = '';
        this.noMessages = false;
        this.messages = [];
        try {
            const url = `https://lenderpro.ai/api/v1/leads/${this.recordId}/messages?email=portal@loan23.com`;
            const response = await fetch(url);

            if (!response.ok) {
                throw new Error('Ошибка запроса: ' + response.status);
            }

            const data = await response.json();

            this.messages = data.messages.map((message) => ({
                ...message,
                expanded: false,
                expandedLabel: 'Show',
                formattedDate: this.formatDate(message.date)
            }));

            this.noMessages = this.messages.length === 0;

            setTimeout(() => this.renderHtmlBodies(), 0);
        } catch (err) {
            this.error = err.message;
        } finally {
            this.isLoading = false;
        }
    }

    toggleMessage(event) {
        const idx = event.currentTarget.dataset.index;
        this.messages = this.messages.map((message, i) => {
            if (String(i) === String(idx)) {
                const expanded = !message.expanded;
                return {
                    ...message,
                    expanded,
                    expandedLabel: expanded ? 'Hide' : 'Show'
                };
            }

            return message;
        });
        this.renderHtmlBodies();
    }

    renderHtmlBodies() {
        const blocks = this.template.querySelectorAll('.message-body');
        this.messages.forEach((message, index) => {
            if (blocks[index]) {
                blocks[index].innerHTML = message.text || message.html || '';
            }
        });
    }

    /**
     * Форматирует дату в UTC в формате 'F j, Y, g:i a'
     * Пример: September 27, 2025, 9:03 am
     */
    formatDate(isoString) {
        if (!isoString) return '';

        const date = new Date(isoString);

        const monthNames = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
        ];

        const year = date.getUTCFullYear();
        const month = monthNames[date.getUTCMonth()];
        const day = date.getUTCDate();
        let hour = date.getUTCHours();
        const minute = date.getUTCMinutes().toString().padStart(2, '0');
        const ampm = hour >= 12 ? 'pm' : 'am';
        hour = hour % 12;
        if (hour === 0) hour = 12;
        return `${month} ${day}, ${year}, ${hour}:${minute} ${ampm}`;
    }
}