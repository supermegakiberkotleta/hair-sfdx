public class LeadDeniedEmailHandler {
    
    /**
     * Отправляет email уведомление брокеру при изменении статуса лида на Final Denied
     * @param leadId - ID лида
     * @param brokerEmail - email брокера
     * @param closingReason - причина закрытия
     */
    @future(callout=true)
    public static void sendDeniedEmail(Id leadId, String brokerEmail, String closingReason, String firstMailMessageId) {
        // Добавляем логирование в начало метода
        System.debug('=== FUTURE METHOD START ===');
        System.debug('Method called with parameters:');
        System.debug('leadId: ' + leadId);
        System.debug('brokerEmail: ' + brokerEmail);
        System.debug('closingReason: ' + closingReason);
        System.debug('firstMailMessageId: ' + firstMailMessageId);
        System.debug('=== LEAD DENIED EMAIL HANDLER START ===');
        System.debug('Lead ID: ' + leadId);
        System.debug('Broker Email: ' + brokerEmail);
        System.debug('Closing Reason: ' + closingReason);
        System.debug('First Mail Message ID: ' + firstMailMessageId);
        
        try {
            // Получаем данные лида для API запроса
            List<Lead> leadList = [SELECT Id, Name, Mail_Theme__c FROM Lead WHERE Id = :leadId LIMIT 1];
            if (leadList.isEmpty()) {
                System.debug('Lead not found: ' + leadId);
                return;
            }
            
            Lead lead = leadList[0];
            System.debug('Lead data retrieved: ' + lead.Name);
            
            // Формируем тело запроса для API
            Map<String, Object> requestBody = new Map<String, Object>();
            
            // leadData
            Map<String, String> leadData = new Map<String, String>();
            leadData.put('Id', lead.Id);
            leadData.put('Name', lead.Name != null ? lead.Name : '');
            requestBody.put('leadData', leadData);
            
            // Остальные параметры
            requestBody.put('isSalesforce', true);
            requestBody.put('emailContent', 'Denied, ' + closingReason);
            requestBody.put('senderName', 'Underwriting Team');
            
            System.debug('Request body prepared: ' + JSON.serialize(requestBody));
            
            // Создаем HTTP запрос
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://lenderpro.ai/api/v1/email/send-reply');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(requestBody));
            
            System.debug('HTTP request prepared, sending...');
            
            // Отправляем запрос
            HttpResponse response = http.send(request);
            
            System.debug('API response received');
            System.debug('Response status code: ' + response.getStatusCode());
            System.debug('Response body: ' + response.getBody());
            
            // Проверяем успешность запроса
            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                System.debug('Email sent successfully via API!');
                System.debug('Denied email sent successfully to: ' + brokerEmail + ' for lead: ' + leadId);
            } else {
                System.debug('API request failed with status: ' + response.getStatusCode());
                System.debug('Error response: ' + response.getBody());
            }
            
        } catch (Exception e) {
            System.debug('=== ERROR SENDING EMAIL ===');
            System.debug('Error sending denied email for lead ' + leadId + ': ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            System.debug('Error type: ' + e.getTypeName());
        }
        
        System.debug('=== LEAD DENIED EMAIL HANDLER END ===');
    }
    
    /**
     * Обрабатывает список лидов и отправляет email уведомления
     * @param leads - список лидов для обработки
     */
    public static void processLeadsForEmail(List<Lead> leads) {
        System.debug('=== PROCESS LEADS FOR EMAIL START ===');
        System.debug('Number of leads to process: ' + leads.size());
        
        List<Id> leadIds = new List<Id>();
        List<String> brokerEmails = new List<String>();
        List<String> closingReasons = new List<String>();
        List<String> firstMailMessageIds = new List<String>();
        
        for (Lead lead : leads) {
            System.debug('Processing lead: ' + lead.Id);
            System.debug('Lead Broker_email__c: ' + lead.Broker_email__c);
            System.debug('Lead ClosingReasonNew__c: ' + lead.ClosingReasonNew__c);
            System.debug('Lead First_Mail_Message_Id__c: ' + lead.First_Mail_Message_Id__c);
            
            if (String.isNotBlank(lead.Broker_email__c) && String.isNotBlank(lead.ClosingReasonNew__c)) {
                leadIds.add(lead.Id);
                brokerEmails.add(lead.Broker_email__c);
                closingReasons.add(lead.ClosingReasonNew__c);
                firstMailMessageIds.add(lead.First_Mail_Message_Id__c);
                System.debug('Added lead to email list: ' + lead.Id);
            } else {
                System.debug('Lead skipped - missing email or closing reason: ' + lead.Id);
            }
        }
        
        System.debug('Total leads to send email: ' + leadIds.size());
        
        // Отправляем email для каждого лида
        for (Integer i = 0; i < leadIds.size(); i++) {
            System.debug('Calling sendDeniedEmail for lead: ' + leadIds[i]);
            sendDeniedEmail(leadIds[i], brokerEmails[i], closingReasons[i], firstMailMessageIds[i]);
        }
        
        System.debug('=== PROCESS LEADS FOR EMAIL END ===');
    }
}