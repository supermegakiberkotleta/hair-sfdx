public with sharing class LeadConversionController {
    
    @AuraEnabled
    public static ConversionResult startLeadConversion(Id leadId) {
        ConversionResult result = new ConversionResult();
        
        try {
            // Получаем данные лида
            Lead lead = [
                SELECT Id, Status, RecordTypeId, Final_Daily_payment__c, 
                       Final_purchased_Amount_of_Future_New__c, Payment_Frequency__c,
                       Loan_Start_Date__c, Final_Term__c, Client_email__c, Lender_type__c,
                       FirstName, LastName, OwnerId, Broker_bonus__c, Payment_ICo_broker__c, 
                       Payment_ICo_external__c, Other__c
                FROM Lead 
                WHERE Id = :leadId
            ];
            
            // Проверяем, что все обязательные поля заполнены
            List<String> missingFields = new List<String>();
            
            if (lead.Final_Daily_payment__c == null)
                missingFields.add('Final Daily Payment');
            if (lead.Final_purchased_Amount_of_Future_New__c == null)
                missingFields.add('Final Purchased Amount of Future');
            if (String.isBlank(lead.Payment_Frequency__c))
                missingFields.add('Payment Frequency');
            if (lead.Loan_Start_Date__c == null)
                missingFields.add('Loan Start Date');
            if (String.isBlank(lead.Final_Term__c))
                missingFields.add('Final Term');
            if (String.isBlank(lead.Client_email__c))
                missingFields.add('Client Email');
            if (String.isBlank(lead.Lender_type__c))
                missingFields.add('Lender Type');
            if (lead.Broker_bonus__c == null)
                missingFields.add('Broker Bonus');
            if (lead.Payment_ICo_broker__c == null)
                missingFields.add('Payment for ICo within the broker');
            if (lead.Payment_ICo_external__c == null)
                missingFields.add('Payment for ICo external broker');   
            if (lead.Other__c == null)
                missingFields.add('Other');

            if (!missingFields.isEmpty()) {
                result.success = false;
                result.message = 'Please fill in all required fields: ' + String.join(missingFields, ', ');
                return result;
            }
            
            // Проверяем существующие Account и Contact
            Id existingAccountId = null;
            Id existingContactId = null;
            
            // Ищем существующий Account по фамилии (LastName)
            String accountName = lead.LastName;
            List<Account> existingAccounts = [
                SELECT Id, Name 
                FROM Account 
                WHERE Name = :accountName 
                LIMIT 1
            ];
            
            if (!existingAccounts.isEmpty()) {
                existingAccountId = existingAccounts[0].Id;
            }
            
            // Ищем существующий Contact по email
            if (String.isNotBlank(lead.Client_email__c)) {
                List<Contact> existingContacts = [
                    SELECT Id, Email, AccountId 
                    FROM Contact 
                    WHERE Email = :lead.Client_email__c 
                    LIMIT 1
                ];
                
                if (!existingContacts.isEmpty()) {
                    existingContactId = existingContacts[0].Id;
                    // Если нашли Contact, но не нашли Account, используем Account из Contact
                    if (existingAccountId == null && existingContacts[0].AccountId != null) {
                        existingAccountId = existingContacts[0].AccountId;
                    }
                    // Если нашли и Account и Contact, но они не связаны, используем Account из Contact
                    else if (existingAccountId != null && existingContacts[0].AccountId != null && 
                             existingAccountId != existingContacts[0].AccountId) {
                        existingAccountId = existingContacts[0].AccountId;
                    }
                }
            }
            
            // Создаем Account только если не найден существующий
            Account acc;
            if (existingAccountId == null) {
                acc = new Account(
                    Name = lead.LastName,
                    OwnerId = lead.OwnerId
                );
                if (!Test.isRunningTest()) {
                    try {
                        acc.RecordTypeId = '012Kc000000teo4IAA';
                    } catch (Exception e) {
                        // RecordType не существует, продолжаем без него
                    }
                }
                insert acc;
            } else {
                acc = new Account(Id = existingAccountId);
            }
            
            // Создаем Contact только если не найден существующий
            Contact con;
            if (existingContactId == null) {
                con = new Contact(
                    FirstName = lead.FirstName != null ? lead.FirstName : '',
                    LastName = lead.LastName,
                    Email = lead.Client_email__c,
                    AccountId = acc.Id,
                    OwnerId = lead.OwnerId
                );
                if (!Test.isRunningTest()) {
                    try {
                        con.RecordTypeId = '012Kc000000teoJIAQ';
                    } catch (Exception e) {
                        // RecordType не существует, продолжаем без него
                    }
                }
                insert con;
            } else {
                con = new Contact(Id = existingContactId);
            }
            
            // Создаем Opportunity
            Opportunity opp = new Opportunity(
                Name = lead.LastName,
                StageName = '0 days',
                CloseDate = Date.today().addDays(365),
                AccountId = acc.Id,
                OwnerId = lead.OwnerId
            );
            if (!Test.isRunningTest()) {
                try {
                    opp.RecordTypeId = '012Kc000000tenzIAA';
                } catch (Exception e) {
                    // RecordType не существует, продолжаем без него
                }
            }
            insert opp;
            
            // Конвертируем лид
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus('Convrted Loan');
            lc.setDoNotCreateOpportunity(false);
            lc.setAccountId(acc.Id);
            lc.setContactId(con.Id);
            lc.setOpportunityId(opp.Id);
            
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            if (lcr.isSuccess()) {
                result.success = true;
                result.message = 'Lead converted successfully';
                result.accountId = acc.Id;
                result.contactId = con.Id;
                result.opportunityId = opp.Id;
            } else {
                result.success = false;
                result.message = 'Conversion failed: ' + lcr.getErrors()[0].getMessage();
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error during conversion: ' + e.getMessage();
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Boolean validateLeadFields(Id leadId) {
        try {
            Lead lead = [
                SELECT Final_Daily_payment__c, Final_purchased_Amount_of_Future_New__c,
                       Payment_Frequency__c, Loan_Start_Date__c, Final_Term__c,
                       Client_email__c, Lender_type__c, FirstName, LastName, Broker_bonus__c,
                       Payment_ICo_broker__c, Payment_ICo_external__c, Other__c
                FROM Lead 
                WHERE Id = :leadId
            ];
            
            return lead.Final_Daily_payment__c != null &&
                   lead.Final_purchased_Amount_of_Future_New__c != null &&
                   String.isNotBlank(lead.Payment_Frequency__c) &&
                   lead.Loan_Start_Date__c != null &&
                   String.isNotBlank(lead.Final_Term__c) &&
                   String.isNotBlank(lead.Client_email__c) &&
                   String.isNotBlank(lead.Lender_type__c) &&
                   lead.Broker_bonus__c != null &&
                   lead.Payment_ICo_broker__c != null &&
                   lead.Payment_ICo_external__c != null &&
                   lead.Other__c != null;
                   
        } catch (Exception e) {
            return false;
        }
    }
    
    @AuraEnabled
    public static DuplicateCheckResult checkForDuplicates(Id leadId) {
        DuplicateCheckResult result = new DuplicateCheckResult();
        
        try {
            Lead lead = [
                SELECT FirstName, LastName, Client_email__c
                FROM Lead 
                WHERE Id = :leadId
            ];
            
            String accountName = lead.LastName;
            
            // Проверяем существующий Account
            List<Account> existingAccounts = [
                SELECT Id, Name 
                FROM Account 
                WHERE Name = :accountName 
                LIMIT 1
            ];
            
            if (!existingAccounts.isEmpty()) {
                result.hasExistingAccount = true;
                result.existingAccountId = existingAccounts[0].Id;
                result.existingAccountName = existingAccounts[0].Name;
            }
            
            // Проверяем существующий Contact
            if (String.isNotBlank(lead.Client_email__c)) {
                List<Contact> existingContacts = [
                    SELECT Id, Email, AccountId, Account.Name
                    FROM Contact 
                    WHERE Email = :lead.Client_email__c 
                    LIMIT 1
                ];
                
                if (!existingContacts.isEmpty()) {
                    result.hasExistingContact = true;
                    result.existingContactId = existingContacts[0].Id;
                    result.existingContactEmail = existingContacts[0].Email;
                    result.existingContactAccountId = existingContacts[0].AccountId;
                    result.existingContactAccountName = existingContacts[0].Account.Name;
                }
            }
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error checking for duplicates: ' + e.getMessage();
        }
        
        return result;
    }
    
    public class ConversionResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id accountId;
        @AuraEnabled public Id contactId;
        @AuraEnabled public Id opportunityId;
        
        public ConversionResult() {
            this.success = false;
            this.message = '';
        }
    }
    
    public class DuplicateCheckResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean hasExistingAccount;
        @AuraEnabled public Id existingAccountId;
        @AuraEnabled public String existingAccountName;
        @AuraEnabled public Boolean hasExistingContact;
        @AuraEnabled public Id existingContactId;
        @AuraEnabled public String existingContactEmail;
        @AuraEnabled public Id existingContactAccountId;
        @AuraEnabled public String existingContactAccountName;
        
        public DuplicateCheckResult() {
            this.success = false;
            this.message = '';
            this.hasExistingAccount = false;
            this.hasExistingContact = false;
        }
    }
}