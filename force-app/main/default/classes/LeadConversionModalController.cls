public with sharing class LeadConversionModalController {
    
    @AuraEnabled(cacheable=true)
    public static LeadModalData getLeadData(Id leadId) {
        try {
            Lead lead = [
                SELECT Id, FirstName, LastName, Status, RecordTypeId, RecordType.DeveloperName,
                       Final_Daily_payment__c, Final_purchased_Amount_of_Future_New__c,
                       Payment_Frequency__c, Loan_Start_Date__c, Final_Term__c,
                       Client_email__c, Lender_type__c
                FROM Lead 
                WHERE Id = :leadId
                LIMIT 1
            ];
            
            LeadModalData data = new LeadModalData();
            data.leadId = lead.Id;
            data.firstName = lead.FirstName;
            data.lastName = lead.LastName;
            data.status = lead.Status;
            data.recordTypeId = lead.RecordTypeId;
            data.recordTypeName = lead.RecordType.DeveloperName;
            data.finalDailyPayment = lead.Final_Daily_payment__c;
            data.finalPurchasedAmount = lead.Final_purchased_Amount_of_Future_New__c;
            data.paymentFrequency = lead.Payment_Frequency__c;
            data.loanStartDate = lead.Loan_Start_Date__c;
            data.finalTerm = lead.Final_Term__c;
            data.clientEmail = lead.Client_email__c;
            data.lenderType = lead.Lender_type__c;
            
            return data;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to load lead data: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void showConversionModal(Id leadId) {
        try {
            // Проверяем, что лид существует и имеет правильный статус
            Lead lead = [SELECT Id, Status, RecordType.DeveloperName FROM Lead WHERE Id = :leadId LIMIT 1];
            
            if (lead.Status != 'Call after') {
                throw new AuraHandledException('Lead status must be "Call after" to show conversion modal');
            }
            
            // Проверяем, что RecordType существует (не null)
            if (lead.RecordType == null) {
                throw new AuraHandledException('Lead must have a valid RecordType');
            }
            
            // Здесь можно добавить дополнительную логику, если нужно
            // Например, отправку уведомлений или логирование
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to show conversion modal: ' + e.getMessage());
        }
    }
    
    // Вспомогательный класс для передачи данных
    public class LeadModalData {
        @AuraEnabled public Id leadId;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String status;
        @AuraEnabled public Id recordTypeId;
        @AuraEnabled public String recordTypeName;
        @AuraEnabled public Decimal finalDailyPayment;
        @AuraEnabled public Decimal finalPurchasedAmount;
        @AuraEnabled public String paymentFrequency;
        @AuraEnabled public Date loanStartDate;
        @AuraEnabled public String finalTerm;
        @AuraEnabled public String clientEmail;
        @AuraEnabled public String lenderType;
    }
}