public with sharing class ChatNotificationService {
    public static SObject findMatchingRecord(Chat_Message__e evt) {
        String psid = evt.PSID__c;
        String channel = evt.Channel__c;
        String fieldName;

        if (channel == 'whatsapp') {
            fieldName = 'WhatsApp_ID__c';
        } else if (channel == 'facebook') {
            fieldName = 'Facebook_PSID__c';
        } else if (channel == 'instagram') {
            fieldName = 'Instagram_PSID__c';
        } else {
            return null;
        }

        List<SObject> leads = Database.query('SELECT Id, OwnerId, Name FROM Lead WHERE ' + fieldName + ' = :psid LIMIT 1');
        if (!leads.isEmpty()) return leads[0];

        List<SObject> contacts = Database.query('SELECT Id, OwnerId, Name FROM Contact WHERE ' + fieldName + ' = :psid LIMIT 1');
        if (!contacts.isEmpty()) return contacts[0];

        List<SObject> accounts = Database.query('SELECT Id, OwnerId, Name FROM Account WHERE ' + fieldName + ' = :psid LIMIT 1');
        if (!accounts.isEmpty()) return accounts[0];

        return null;
    }

    // Добавляем возможность переопределить в тесте
    public static Id notificationTypeIdOverride;

    public static void sendCustomNotification(Chat_Message__e evt, SObject record) {
        try {
            String sender = evt.Sender__c;
            Datetime msgDate = evt.Date__c;

            if (sender == 'user') {
                record.put('Last_Message_Date__c', msgDate);
            } else if (sender == 'agent') {
                record.put('Date_of_last_outgoing_message__c', msgDate);
            }

            update record; // <-- может выбрасывать ошибку

            if (sender == 'agent') return;

            Id notificationTypeId = notificationTypeIdOverride != null ?
                notificationTypeIdOverride : getNotificationTypeId('Chat_Notification');

            if (notificationTypeId != null) {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('New message in chat');
                notification.setBody(evt.Message__c);
                notification.setNotificationTypeId(notificationTypeId);
                notification.setTargetId((Id) record.get('Id'));
                Set<String> recipientIds = new Set<String>{ String.valueOf(record.get('OwnerId')) };
                notification.send(recipientIds); // <-- тоже может выбросить ошибку
            }

            Chat_Message__e newEvent = new Chat_Message__e(
                PSID__c       = evt.PSID__c,
                Channel__c    = evt.Channel__c,
                Message__c    = evt.Message__c,
                Sender__c     = sender,
                Date__c       = msgDate,
                OwnerId__c    = (Id) record.get('OwnerId'),
                RecordId__c   = (Id) record.get('Id'),
                Processed_By_Server__c = true
            );
            EventBus.publish(newEvent);

        } catch (Exception e) {
            System.debug('Ошибка в sendCustomNotification: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw e; // можно убрать на проде, но полезно при отладке
        }
    }


    private static Id getNotificationTypeId(String developerName) {
        List<CustomNotificationType> types = [
            SELECT Id FROM CustomNotificationType WHERE DeveloperName = :developerName LIMIT 1
        ];
        return types.isEmpty() ? null : types[0].Id;
    }
}
