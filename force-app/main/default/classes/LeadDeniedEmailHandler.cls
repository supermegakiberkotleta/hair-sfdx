public class LeadDeniedEmailHandler {
    
    /**
     * Отправляет email уведомление брокеру при изменении статуса лида на Final Denied
     * @param leadId - ID лида
     * @param brokerEmail - email брокера
     * @param closingReason - причина закрытия
     */
    @future
    public static void sendDeniedEmail(Id leadId, String brokerEmail, String closingReason) {
        // Добавляем логирование в начало метода
        System.debug('=== FUTURE METHOD START ===');
        System.debug('Method called with parameters:');
        System.debug('leadId: ' + leadId);
        System.debug('brokerEmail: ' + brokerEmail);
        System.debug('closingReason: ' + closingReason);
        System.debug('=== LEAD DENIED EMAIL HANDLER START ===');
        System.debug('Lead ID: ' + leadId);
        System.debug('Broker Email: ' + brokerEmail);
        System.debug('Closing Reason: ' + closingReason);
        
        try {
            // Создаем email сообщение
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            System.debug('Email message created');
            
            // Устанавливаем OrgWideEmailAddress
            Id orgWideEmailId = getOrgWideEmailId('underwriting@loan23.com');
            if (orgWideEmailId != null) {
                mail.setOrgWideEmailAddressId(orgWideEmailId);
                System.debug('OrgWideEmailAddress set: ' + orgWideEmailId);
            } else {
                // Fallback если OrgWideEmailAddress не найден
                mail.setSenderDisplayName('Underwriting Team');
                mail.setReplyTo('underwriting@loan23.com');
                System.debug('Fallback sender info set');
            }
            
            // Устанавливаем получателя
            List<String> toAddresses = new List<String>();
            if (String.isNotBlank(brokerEmail)) {
                toAddresses.add(brokerEmail);
                System.debug('Added broker email to recipients: ' + brokerEmail);
            } else {
                System.debug('Broker email is blank or null');
            }
            
            if (toAddresses.isEmpty()) {
                System.debug('No valid broker email found for lead: ' + leadId);
                return;
            }
            
            mail.setToAddresses(toAddresses);
            System.debug('Recipients set: ' + toAddresses);
            
            // Устанавливаем тему и тело письма
            mail.setSubject('Denied');
            mail.setPlainTextBody('Denied, ' + closingReason);
            System.debug('Subject and body set');
            System.debug('Email body: Denied, ' + closingReason);
            
            // Отправляем email
            System.debug('About to send email...');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email sent successfully!');
            
            System.debug('Denied email sent successfully to: ' + brokerEmail + ' for lead: ' + leadId);
            
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
        
        for (Lead lead : leads) {
            System.debug('Processing lead: ' + lead.Id);
            System.debug('Lead Broker_email__c: ' + lead.Broker_email__c);
            System.debug('Lead ClosingReasonNew__c: ' + lead.ClosingReasonNew__c);
            
            if (String.isNotBlank(lead.Broker_email__c) && String.isNotBlank(lead.ClosingReasonNew__c)) {
                leadIds.add(lead.Id);
                brokerEmails.add(lead.Broker_email__c);
                closingReasons.add(lead.ClosingReasonNew__c);
                System.debug('Added lead to email list: ' + lead.Id);
            } else {
                System.debug('Lead skipped - missing email or closing reason: ' + lead.Id);
            }
        }
        
        System.debug('Total leads to send email: ' + leadIds.size());
        
        // Отправляем email для каждого лида
        for (Integer i = 0; i < leadIds.size(); i++) {
            System.debug('Calling sendDeniedEmail for lead: ' + leadIds[i]);
            sendDeniedEmail(leadIds[i], brokerEmails[i], closingReasons[i]);
        }
        
        System.debug('=== PROCESS LEADS FOR EMAIL END ===');
    }
    
    /**
     * Получает ID OrgWideEmailAddress по email адресу
     * @param address - email адрес для поиска
     * @return ID OrgWideEmailAddress или null, если не найден
     */
    public static Id getOrgWideEmailId(String address) {
        try {
            for (OrgWideEmailAddress owea : [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address = :address]) {
                System.debug('Found OrgWideEmailAddress: ' + owea.Id + ' for address: ' + owea.Address);
                return owea.Id;
            }
            System.debug('No OrgWideEmailAddress found for address: ' + address);
            return null;
        } catch (Exception e) {
            System.debug('Error getting OrgWideEmailAddress: ' + e.getMessage());
            return null;
        }
    }
} 