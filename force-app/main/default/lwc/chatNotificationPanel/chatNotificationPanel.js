import { LightningElement, track, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/empApi';
import USER_ID from '@salesforce/user/Id';
import chatSound from '@salesforce/resourceUrl/chat_sound';
import getRecordName from '@salesforce/apex/ChatNotificationHelper.getRecordName';

export default class ChatNotificationPanel extends LightningElement {
    @track messages = [];
    channelName = '/event/Chat_Message__e';
    subscription = null;
    soundUrl = chatSound;

    connectedCallback() {
        this.subscribeToChannel();
    }

    subscribeToChannel() {
        subscribe(this.channelName, -1, (response) => {
            const evt = response.data.payload;
            if (evt.OwnerId__c === USER_ID) {
                this.getRecordName(evt);
            }
        });
    }

    getRecordName(evt) {
        getRecordName({ recordId: evt.RecordId__c })
            .then((name) => {
                this.showMessage(evt, name);
            })
            .catch((error) => {
                // Если запись не найдена (удалена), показываем сообщение без ссылки
                console.warn('Record not found for notification:', evt.RecordId__c, error);
                this.showMessage(evt, 'Запись не найдена (возможно удалена)', true);
            });
    }

    showMessage(evt, recordName, isDeleted = false) {
        const msg = {
            id: Date.now(),
            text: evt.Message__c,
            link: isDeleted ? null : '/' + evt.RecordId__c, // Не создаем ссылку для удаленных записей
            name: evt.Sender__c,
            recordName: recordName,
            channel: evt.Channel__c,
            isDeleted: isDeleted
        };

        this.messages.unshift(msg);
        this.playSound();

        if (this.messages.length > 5) {
            this.messages.pop();
        }
        setTimeout(() => {
            this.messages = this.messages.filter(m => m.id !== msg.id);
        }, 10000);
    }

    playSound() {
        const audio = this.template.querySelector('audio');
        if (audio) {
            audio.play();
        }
    }
}