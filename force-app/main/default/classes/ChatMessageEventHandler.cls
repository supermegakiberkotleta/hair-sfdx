public with sharing class ChatMessageEventHandler {
    public static void handleEvents(List<Chat_Message__e> events) {
        for (Chat_Message__e event : events) {
            if (event.Processed_By_Server__c == true) {
                // Уже обработано — пропускаем
                continue;
            }
            SObject matchedRecord = ChatNotificationService.findMatchingRecord(event);
            if (matchedRecord != null) {
                ChatNotificationService.sendCustomNotification(event, matchedRecord);
            }
        }
    }

}