public with sharing class WhatsappOpportunityChatController {

    // Получение сообщений для Opportunity
    @AuraEnabled
    public static List<WhatsApp_Message__c> getMessages(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is null.');
        }

        return [
            SELECT Id, New_message__c, Direction_new__c, Created_At_New__c, Phone_new__c
            FROM WhatsApp_Message__c
            WHERE Opportunity_new__c = :opportunityId
            ORDER BY Created_At_New__c ASC
        ];
    }

    // Отправка сообщения и логирование
    @AuraEnabled
    public static void sendMessage(Id opportunityId, String message, String phone) {
        if (opportunityId == null) {
            throw new AuraHandledException('Opportunity ID is null.');
        }
        if (String.isBlank(message) || String.isBlank(phone)) {
            throw new AuraHandledException('Message or phone number cannot be empty.');
        }

        List<Opportunity> oppList = [SELECT Id, Phone_number__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        if (oppList.isEmpty()) {
            throw new AuraHandledException('Opportunity not found for ID: ' + opportunityId);
        }

        Opportunity opp = oppList[0];
        String phoneToSend = !String.isBlank(opp.Phone_number__c) ? opp.Phone_number__c : phone;

        if (String.isBlank(phoneToSend)) {
            throw new AuraHandledException('Phone number is required.');
        }

        // Оставляем только цифры
        String digitsOnly = phoneToSend.replaceAll('[^0-9]', '');
        if (digitsOnly.startsWith('8') && digitsOnly.length() == 11) digitsOnly = '7' + digitsOnly.substring(1);
        if (digitsOnly.length() == 10) digitsOnly = '7' + digitsOnly;
        if (digitsOnly.length() < 11) throw new AuraHandledException('Invalid phone number.');

        phoneToSend = '+' + digitsOnly;

        // Отправка на Laravel Wazzup
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://lenderpro.itprofit.net/api/v1/whatsapp/chat-whatsapp/send');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(new Map<String, Object>{
                'user' => phoneToSend,
                'message' => message
            }));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 400) {
                throw new AuraHandledException('Wazzup API error: ' + res.getBody());
            }
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to send WhatsApp message: ' + ex.getMessage());
        }

        // Логирование в Salesforce
        try {
            WhatsApp_Message__c msg = new WhatsApp_Message__c(
                Opportunity_new__c = opportunityId,
                New_message__c = message,
                Direction_new__c = 'Outgoing',
                Created_At_New__c = System.now(),
                Phone_new__c = phoneToSend
            );
            insert msg;
        } catch (Exception e) {
            System.debug('Error logging message: ' + e.getMessage());
        }
    }

    // Получение телефона Opportunity
    @AuraEnabled(cacheable=true)
    public static String getOpportunityPhone(Id opportunityId) {
        if (opportunityId == null) return null;
        Opportunity opp = [SELECT Phone_number__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        return opp.Phone_number__c;
    }
}