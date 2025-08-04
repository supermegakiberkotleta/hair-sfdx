@isTest
public class LeadConversionControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'Call after',
            Final_Daily_payment__c = 100,
            Final_purchased_Amount_of_Future_New__c = 10000,
            Payment_Frequency__c = '100',
            Loan_Start_Date__c = Date.today(),
            Final_Term__c = '100',
            Client_email__c = 'test@example.com',
            Lender_type__c = 'Boostra'
        );
        
        // Устанавливаем RecordType если он существует
        try {
            Id recordTypeId = Schema.SObjectType.Lead
                .getRecordTypeInfosByDeveloperName()
                .get('Loan_Leads')
                .getRecordTypeId();
            if (recordTypeId != null) {
                testLead.RecordTypeId = recordTypeId;
            }
        } catch (Exception e) {
            // RecordType не существует, продолжаем без него
        }
        
        insert testLead;
    }
    
    @isTest
    static void testValidateLeadFields() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        Test.startTest();
        Boolean isValid = LeadConversionController.validateLeadFields(testLead.Id);
        Test.stopTest();
        
        System.assert(isValid, 'Lead should be valid with all required fields');
    }
    
    @isTest
    static void testValidateLeadFieldsMissing() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        // Удаляем обязательное поле
        testLead.Final_Daily_payment__c = null;
        update testLead;
        
        Test.startTest();
        Boolean isValid = LeadConversionController.validateLeadFields(testLead.Id);
        Test.stopTest();
        
        System.assert(!isValid, 'Lead should be invalid with missing required field');
    }
    
    @isTest
    static void testCheckForDuplicates() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        Test.startTest();
        LeadConversionController.DuplicateCheckResult result = LeadConversionController.checkForDuplicates(testLead.Id);
        Test.stopTest();
        
        System.assert(result.success, 'Duplicate check should succeed');
        System.assert(!result.hasExistingAccount, 'Should not find existing account');
        System.assert(!result.hasExistingContact, 'Should not find existing contact');
    }
    
    @isTest
    static void testCheckForDuplicatesWithExisting() {
        Lead testLead = [SELECT Id, Company, Client_email__c FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        // Создаем существующий Account
        Account existingAccount = new Account(Name = testLead.Company);
        insert existingAccount;
        
        // Создаем существующий Contact
        Contact existingContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = testLead.Client_email__c,
            AccountId = existingAccount.Id
        );
        insert existingContact;
        
        Test.startTest();
        LeadConversionController.DuplicateCheckResult result = LeadConversionController.checkForDuplicates(testLead.Id);
        Test.stopTest();
        
        System.assert(result.success, 'Duplicate check should succeed');
        System.assert(result.hasExistingAccount, 'Should find existing account');
        System.assert(result.hasExistingContact, 'Should find existing contact');
        System.assertEquals(existingAccount.Id, result.existingAccountId, 'Should return correct account ID');
        System.assertEquals(existingContact.Id, result.existingContactId, 'Should return correct contact ID');
    }
    
    @isTest
    static void testStartLeadConversion() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        Test.startTest();
        LeadConversionController.ConversionResult result = LeadConversionController.startLeadConversion(testLead.Id);
        Test.stopTest();
        
        System.assert(result.success, 'Conversion should succeed');
        System.assertNotEquals(null, result.accountId, 'Should create account');
        System.assertNotEquals(null, result.contactId, 'Should create contact');
        System.assertNotEquals(null, result.opportunityId, 'Should create opportunity');
        
        // Проверяем, что лид был конвертирован
        Lead convertedLead = [SELECT IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId 
                             FROM Lead WHERE Id = :testLead.Id];
        System.assert(convertedLead.IsConverted, 'Lead should be converted');
        System.assertEquals(result.accountId, convertedLead.ConvertedAccountId, 'Should link to correct account');
        System.assertEquals(result.contactId, convertedLead.ConvertedContactId, 'Should link to correct contact');
        System.assertEquals(result.opportunityId, convertedLead.ConvertedOpportunityId, 'Should link to correct opportunity');
    }
    
    @isTest
    static void testStartLeadConversionWithExistingRecords() {
        Lead testLead = [SELECT Id, Company, Client_email__c FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        // Создаем существующий Account
        Account existingAccount = new Account(Name = testLead.Company);
        insert existingAccount;
        
        // Создаем существующий Contact
        Contact existingContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = testLead.Client_email__c,
            AccountId = existingAccount.Id
        );
        insert existingContact;
        
        Test.startTest();
        LeadConversionController.ConversionResult result = LeadConversionController.startLeadConversion(testLead.Id);
        Test.stopTest();
        
        System.assert(result.success, 'Conversion should succeed with existing records');
        System.assertEquals(existingAccount.Id, result.accountId, 'Should use existing account');
        System.assertEquals(existingContact.Id, result.contactId, 'Should use existing contact');
        System.assertNotEquals(null, result.opportunityId, 'Should create new opportunity');
    }
    
    @isTest
    static void testStartLeadConversionMissingFields() {
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Test Lead' LIMIT 1];
        
        // Удаляем обязательное поле
        testLead.Final_Daily_payment__c = null;
        update testLead;
        
        Test.startTest();
        LeadConversionController.ConversionResult result = LeadConversionController.startLeadConversion(testLead.Id);
        Test.stopTest();
        
        System.assert(!result.success, 'Conversion should fail with missing fields');
        System.assert(result.message.contains('Final Daily Payment'), 'Should mention missing field');
    }
}