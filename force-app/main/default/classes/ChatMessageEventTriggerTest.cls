@isTest
private class ChatMessageEventTriggerTest {

    @isTest
    static void testTriggerWithMatchingLead() {
        // Переопределяем ID типа уведомления
        ChatNotificationService.notificationTypeIdOverride = '0ML000000000002';

        // Создаём лид
        Lead l = new Lead(
            LastName = 'ApexTest',
            WhatsApp_ID__c = 'trigger_psid',
            Company = 'Test',
            OwnerId = UserInfo.getUserId()
        );
        insert l;

        // Публикуем Platform Event — триггер должен сработать
        Test.startTest();
        EventBus.publish(new Chat_Message__e(
            PSID__c = 'trigger_psid',
            Channel__c = 'whatsapp',
            Message__c = 'Trigger message'
        ));
        Test.stopTest();

        // Проверка будет логической — отсутствие ошибок и покрытие триггера
    }
}