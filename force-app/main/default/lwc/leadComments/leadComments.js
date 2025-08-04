import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import addComment from '@salesforce/apex/LeadCommentsController.addComment';
import getComments from '@salesforce/apex/LeadCommentsController.getComments';

export default class LeadComments extends LightningElement {
    @api recordId;
    @track comments = [];
    @track newComment = '';
    @track isLoading = false;

    connectedCallback() {
        this.loadComments();
    }

    loadComments() {
        this.isLoading = true;
        getComments({ parentId: this.recordId })
            .then(result => {
                this.comments = result.map(comment => ({
                    ...comment,
                    formattedDate: this.formatDate(comment.createdDate)
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
                this.isLoading = false;
            });
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return new Intl.DateTimeFormat('ru-RU', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(date);
    }

    handleCommentChange(event) {
        this.newComment = event.target.value;
    }

    handleSubmit() {
        if (!this.newComment.trim()) {
            this.showToast('Error', 'Пожалуйста, введите комментарий', 'error');
            return;
        }

        this.isLoading = true;
        addComment({ parentId: this.recordId, commentText: this.newComment })
            .then(() => {
                this.newComment = '';
                this.loadComments();
                this.showToast('Успех', 'Комментарий добавлен', 'success');
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleError(error) {
        let message = 'Неизвестная ошибка';
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (typeof error.body.message === 'string') {
            message = error.body.message;
        }
        this.showToast('Ошибка', message, 'error');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}