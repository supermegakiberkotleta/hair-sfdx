public with sharing class SmsMessagesController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getMessages(String recordId) {
        // Создаем тестовый список SMS
        List<Map<String, Object>> messages = new List<Map<String, Object>>();

        // Пример 1
        Map<String, Object> sms1 = new Map<String, Object>();
        sms1.put('Id', '1');
        sms1.put('Body', 'Привет! Это тестовое SMS 1');
        sms1.put('Direction', 'Inbound');
        sms1.put('From', '+1234567890');
        sms1.put('To', '+0987654321');
        sms1.put('RelatedRecordId', recordId);
        sms1.put('CreatedDate', Datetime.now());
        messages.add(sms1);

        // Пример 2
        Map<String, Object> sms2 = new Map<String, Object>();
        sms2.put('Id', '2');
        sms2.put('Body', 'Привет! Это тестовое SMS 2');
        sms2.put('Direction', 'Outbound');
        sms2.put('From', '+0987654321');
        sms2.put('To', '+1234567890');
        sms2.put('RelatedRecordId', recordId);
        sms2.put('CreatedDate', Datetime.now().addMinutes(-5));
        messages.add(sms2);

        // Пример 3
        Map<String, Object> sms3 = new Map<String, Object>();
        sms3.put('Id', '3');
        sms3.put('Body', 'Тестовое SMS 3 для проверки LWC');
        sms3.put('Direction', 'Inbound');
        sms3.put('From', '+1111111111');
        sms3.put('To', '+2222222222');
        sms3.put('RelatedRecordId', recordId);
        sms3.put('CreatedDate', Datetime.now().addMinutes(-10));
        messages.add(sms3);

        return messages;
    }
}