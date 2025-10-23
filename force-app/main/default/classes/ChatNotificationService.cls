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

        // Ищем в порядке приоритета: Lead -> Contact -> Account
        List<SObject> leads = Database.query('SELECT Id, OwnerId, Name, LastName, LeadSource FROM Lead WHERE ' + fieldName + ' = :psid AND IsConverted = false LIMIT 1');
        if (!leads.isEmpty()) return leads[0];

        List<SObject> contacts = Database.query('SELECT Id, OwnerId, Name, LastName, LeadSource FROM Contact WHERE ' + fieldName + ' = :psid LIMIT 1');
        if (!contacts.isEmpty()) return contacts[0];

        List<SObject> accounts = Database.query('SELECT Id, OwnerId, Name, AccountSource FROM Account WHERE ' + fieldName + ' = :psid LIMIT 1');
        if (!accounts.isEmpty()) return accounts[0];

        return null;
    }

    /**
     * Проверяет, существует ли запись с указанным ID
     */
    public static Boolean isRecordExists(Id recordId) {
        try {
            String sObjectType = recordId.getSObjectType().getDescribe().getName();
            String query = 'SELECT Id FROM ' + sObjectType + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query);
            return !records.isEmpty();
        } catch (Exception e) {
            System.debug('Ошибка при проверке существования записи: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Находит альтернативную запись для PSID, если основная запись была удалена
     * Ищет по всем каналам для данного PSID
     */
    public static SObject findAlternativeRecord(String psid) {
        // Список всех полей для поиска по всем каналам
        List<String> fieldsToSearch = new List<String>{
            'WhatsApp_ID__c', 'Facebook_PSID__c', 'Instagram_PSID__c'
        };
        
        // Строим динамический запрос для поиска по всем полям
        String whereClause = '';
        for (Integer i = 0; i < fieldsToSearch.size(); i++) {
            if (i > 0) whereClause += ' OR ';
            whereClause += fieldsToSearch[i] + ' = :psid';
        }
        
        // Ищем в порядке приоритета: Lead -> Contact -> Account
        List<SObject> leads = Database.query('SELECT Id, OwnerId, Name, LastName, LeadSource FROM Lead WHERE ' + whereClause + ' LIMIT 1');
        if (!leads.isEmpty()) return leads[0];

        List<SObject> contacts = Database.query('SELECT Id, OwnerId, Name, LastName, LeadSource FROM Contact WHERE ' + whereClause + ' LIMIT 1');
        if (!contacts.isEmpty()) return contacts[0];

        List<SObject> accounts = Database.query('SELECT Id, OwnerId, Name, AccountSource FROM Account WHERE ' + whereClause + ' LIMIT 1');
        if (!accounts.isEmpty()) return accounts[0];

        return null;
    }

    // Добавляем возможность переопределить в тесте
    public static Id notificationTypeIdOverride;

    private static String getRecordInfo(SObject record) {
        String sObjectType = record.getSObjectType().getDescribe().getName();
        String name = '';
        String source = '';
        
        if (sObjectType == 'Lead') {
            name = (String) record.get('LastName');
            source = (String) record.get('LeadSource');
        } else if (sObjectType == 'Contact') {
            name = (String) record.get('LastName');
            source = (String) record.get('LeadSource');
        } else if (sObjectType == 'Account') {
            name = (String) record.get('Name');
            source = (String) record.get('AccountSource');
        }
        
        if (String.isBlank(name)) name = 'Unknown';
        if (String.isBlank(source)) source = 'Unknown';
        
        return name + ' | ' + source;
    }

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
                String recordInfo = getRecordInfo(record);
                notification.setTitle('New message in chat - ' + recordInfo);
                notification.setBody(evt.Message__c);
                notification.setNotificationTypeId(notificationTypeId);
                notification.setTargetId((Id) record.get('Id'));
                Set<String> recipientIds = new Set<String>{ String.valueOf(record.get('OwnerId')) };
                notification.send(recipientIds); // <-- тоже может выбросить ошибку
            }

            // Всегда пересчитываем запись для нового события, чтобы избежать ссылок на удаленные записи
            SObject currentRecord = findMatchingRecord(evt);
            
            // Если запись не найдена по основному каналу, пробуем найти альтернативную
            if (currentRecord == null) {
                currentRecord = findAlternativeRecord(evt.PSID__c);
            }
            
            if (currentRecord != null) {
                Chat_Message__e newEvent = new Chat_Message__e(
                    PSID__c       = evt.PSID__c,
                    Channel__c    = evt.Channel__c,
                    Message__c    = evt.Message__c,
                    Sender__c     = sender,
                    Date__c       = msgDate,
                    OwnerId__c    = (Id) currentRecord.get('OwnerId'),
                    RecordId__c   = (Id) currentRecord.get('Id'),
                    Processed_By_Server__c = true
                );
                EventBus.publish(newEvent);
            } else {
                System.debug('Не удалось найти запись для PSID: ' + evt.PSID__c + ' в канале: ' + evt.Channel__c);
            }

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