public with sharing class ChatMessageEventHandler {
    public static void handleEvents(List<Chat_Message__e> events) {
        for (Chat_Message__e event : events) {
            if (event.Processed_By_Server__c == true) {
                // Уже обработано — пропускаем
                continue;
            }
            
            // Проверяем, существует ли запись, указанная в RecordId__c (если есть)
            if (event.RecordId__c != null) {
                if (!ChatNotificationService.isRecordExists(event.RecordId__c)) {
                    System.debug('Запись с ID ' + event.RecordId__c + ' не существует, ищем альтернативную для PSID: ' + event.PSID__c);
                    // Запись не существует, ищем альтернативную
                    SObject alternativeRecord = ChatNotificationService.findAlternativeRecord(event.PSID__c);
                    if (alternativeRecord != null) {
                        ChatNotificationService.sendCustomNotification(event, alternativeRecord);
                    } else {
                        System.debug('Не удалось найти альтернативную запись для PSID: ' + event.PSID__c);
                    }
                    continue;
                }
            }
            
            // Сначала пытаемся найти запись по основному каналу
            SObject matchedRecord = ChatNotificationService.findMatchingRecord(event);
            
            // Если не найдена, пробуем найти альтернативную запись
            if (matchedRecord == null) {
                matchedRecord = ChatNotificationService.findAlternativeRecord(event.PSID__c);
            }
            
            if (matchedRecord != null) {
                ChatNotificationService.sendCustomNotification(event, matchedRecord);
            } else {
                System.debug('Не удалось найти запись для PSID: ' + event.PSID__c + ' в канале: ' + event.Channel__c);
            }
        }
    }

}