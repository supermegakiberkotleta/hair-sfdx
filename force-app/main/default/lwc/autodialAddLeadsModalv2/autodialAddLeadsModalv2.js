import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class AutodialAddLeadsmodalv2 extends LightningElement {
    @api recordId;
    @wire(CurrentPageReference)
    pageRef;

    connectedCallback() {
        // Получаем recordId из параметров страницы
        if (this.pageRef && this.pageRef.state && this.pageRef.state.c__recordId) {
            this.recordId = this.pageRef.state.c__recordId;
        }
    }

    handleClose() {
        // Закрываем модальное окно
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSuccess() {
        // При успешном добавлении лидов закрываем модальное окно
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}