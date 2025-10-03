public with sharing class WhatsappLeadChatController {
    
    @AuraEnabled
    public static List<WhatsApp_Message__c> getMessages(Id leadId) {
        return [
             SELECT Id, New_message__c, Direction_new__c, Created_At_New__c, Phone_new__c 
             FROM WhatsApp_Message__c 
             WHERE Lead_new__c = :leadId
             ORDER BY Created_At__c ASC
        ];
    }
    
    @AuraEnabled
    public static void sendMessage(Id leadId, String message, String phone) {
        if(String.isBlank(message) || String.isBlank(phone)) {
            throw new AuraHandledException('Message or phone number cannot be empty.');
        }
        
        Lead lead = [SELECT Id, Phone_number_a__c FROM Lead WHERE Id = :leadId LIMIT 1];
        
        // Если поле в лиде не заполнено, используем номер из формы
        String phoneToSend = !String.isBlank(lead.Phone_number_a__c) ? lead.Phone_number_a__c : phone;
        
        try {
            // Отправка в Laravel Wazzup
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
            
            System.debug('Wazzup response: ' + res.getBody());
            
        } catch(Exception ex) {
            System.debug('Error sending to Wazzup: ' + ex.getMessage());
            throw new AuraHandledException('Failed to send WhatsApp message.');
        }
        
        // Логируем сообщение в Salesforce
        try {
            WhatsApp_Message__c msg = new WhatsApp_Message__c(
                Lead__c = lead.Id,
            Message__c = message,
            Direction__c = 'Outgoing',
            Created_At__c = System.now(),
            Phone__c = phoneToSend
                );
            insert msg;
        } catch(Exception e) {
            System.debug('Error logging message: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getLeadPhone(Id leadId) {
        Lead l = [SELECT Phone_number_a__c FROM Lead WHERE Id = :leadId LIMIT 1];
        return l.Phone_number_a__c;
    }
}