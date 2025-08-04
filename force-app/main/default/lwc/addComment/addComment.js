import { LightningElement } from 'lwc';
// import saveComment from '@salesforce/apex/AddCommentController.saveComment'; // отключено

export default class AddComment extends LightningElement {
    comment = '';
    leadId;

    connectedCallback() {
        const urlParams = new URLSearchParams(window.location.search);
        this.leadId = urlParams.get('c__recordId') || urlParams.get('recordId');
    }

    handleInputChange(event) {
        this.comment = event.target.value;
    }

    handleSubmit() {
        if (!this.leadId || !this.comment.trim()) {
            alert('Введите комментарий и убедитесь, что вы на странице лида.');
            return;
        }

        // Заглушка вместо вызова Apex
        console.warn('Вызов Apex отключён. Комментарий не сохранён:', this.comment);
        alert('Сохранение отключено (тестовый режим).');

        // Если хочешь полностью удалить функциональность:
        // Просто не делай ничего или очисти comment
        // this.comment = '';
    }
}