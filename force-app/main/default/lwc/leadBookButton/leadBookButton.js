import { LightningElement, api } from 'lwc';
import sendLeadToEndpoint from '@salesforce/apex/LeadBookSender.sendLeadToEndpoint';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class LeadBookButton extends LightningElement {
    @api recordId;

    handleClick() {
        sendLeadToEndpoint({ leadId: this.recordId })
            .then(result => {
                console.log(result, ' result');
    
                let messageToShow = result.message; // "Успешно отправлено" или "Ошибка запроса: ..."
    
                if (result.responseBody) {
                    try {
                        const responseObj = JSON.parse(result.responseBody);
    
                        if (result.success) {
                            // Успешный сценарий — достаём book_uuid
                            if (responseObj.book_uuid) {
                                messageToShow += ' — Book ID: ' + responseObj.book_uuid;
                            } else if (responseObj.status) {
                                messageToShow += ' — Статус: ' + responseObj.status;
                            } else {
                                messageToShow += ' — ' + result.responseBody;
                            }
                        } else {
                            // Ошибка — достаём сообщение об ошибке
                            if (responseObj.error) {
                                messageToShow += ' — ' + responseObj.error;
                            } else if (responseObj.message) {
                                messageToShow += ' — ' + responseObj.message;
                            } else {
                                messageToShow += ' — ' + result.responseBody;
                            }
                        }
                    } catch (parseError) {
                        // Если JSON не распарсился — показываем как есть
                        messageToShow += ' — ' + result.responseBody;
                    }
                }
    
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: result.success ? 'Успешно' : 'Ошибка',
                        message: messageToShow,
                        variant: result.success ? 'success' : 'error',
                    })
                );
            })
            .catch(error => {
                console.error('APEX error:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Ошибка',
                        message: 'Ошибка вызова Apex: ' + (error.body?.message || error.message),
                        variant: 'error',
                    })
                );
            });
    }
}