public with sharing class SystemNotificationsEventHandler {
    
    /**
     * Обработчик события after insert для платформы событий System_Notifications__e
     * Вызывает метод sendNotification из NotificationController для каждого события
     */
    public static void handleAfterInsert(List<System_Notifications__e> events) {
        try {
            // Обрабатываем каждое событие
            for (System_Notifications__e event : events) {
                // Вызываем метод sendNotification из NotificationController
                NotificationController.sendNotification(
                    event.Title__c,
                    event.Message__c,
                    event.Type__c,
                    event.User__c,
                    event.Target__c
                );
                
                System.debug('System notification processed for user: ' + event.User__c + 
                           ', title: ' + event.Title__c);
            }
            
        } catch (Exception e) {
            System.debug('Error processing system notifications: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            // В случае ошибки логируем, но не прерываем выполнение
            // чтобы не блокировать обработку других событий
        }
    }
}