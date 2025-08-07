@isTest
private class LeadConversionModalControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Получаем любой доступный RecordType для Lead
        List<RecordType> recordTypes = [
            SELECT Id, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = 'Lead' 
            AND IsActive = true
            LIMIT 1
        ];
        
        if (recordTypes.isEmpty()) {
            // Если нет RecordType, используем стандартный
            Lead testLead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                Status = 'New',
                Final_Daily_payment__c = 100,
                Final_purchased_Amount_of_Future_New__c = 10000,
                Payment_Frequency__c = 'Monthly',
                Loan_Start_Date__c = Date.today(),
                Final_Term__c = '12 months',
                Client_email__c = 'test@example.com',
                Lender_type__c = 'Boostra'
            );
            insert testLead;
        } else {
            // Используем найденный RecordType
            Lead testLead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Company = 'Test Company',
                Status = 'New',
                RecordTypeId = recordTypes[0].Id,
                Final_Daily_payment__c = 100,
                Final_purchased_Amount_of_Future_New__c = 10000,
                Payment_Frequency__c = 'Monthly',
                Loan_Start_Date__c = Date.today(),
                Final_Term__c = '12 months',
                Client_email__c = 'test@example.com',
                Lender_type__c = 'Boostra'
            );
            insert testLead;
        }
    }
    
    @isTest
    static void testGetLeadData_Success() {
        // Получаем тестовый лид
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        
        Test.startTest();
        LeadConversionModalController.LeadModalData result = 
            LeadConversionModalController.getLeadData(testLead.Id);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testGetLeadData_InvalidId() {
        Test.startTest();
        try {
            LeadConversionModalController.getLeadData('001000000000000');
        } catch (AuraHandledException e) {
           
        }
        Test.stopTest();
    }
    
    @isTest
    static void testShowConversionModal_Success() {
        // Получаем тестовый лид и меняем статус на "Call after"
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        testLead.Status = 'Call after';
        update testLead;
        
        Test.startTest();
        LeadConversionModalController.showConversionModal(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что метод выполнился без ошибок
        // Если бы была ошибка, она была бы выброшена
    }
    
    @isTest
    static void testShowConversionModal_WrongStatus() {
        // Получаем тестовый лид (статус "New")
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        
        Test.startTest();
        try {
            LeadConversionModalController.showConversionModal(testLead.Id);
        } catch (AuraHandledException e) {
          
        }
        Test.stopTest();
    }
    
    @isTest
    static void testShowConversionModal_ValidRecordType() {
        // Создаем лид с любым доступным RecordType
        List<RecordType> recordTypes = [
            SELECT Id 
            FROM RecordType 
            WHERE SObjectType = 'Lead' 
            AND IsActive = true
            LIMIT 1
        ];
        
        Lead otherLead;
        if (recordTypes.isEmpty()) {
            otherLead = new Lead(
                FirstName = 'Other',
                LastName = 'Lead',
                Company = 'Other Company',
                Status = 'Call after'
            );
        } else {
            otherLead = new Lead(
                FirstName = 'Other',
                LastName = 'Lead',
                Company = 'Other Company',
                Status = 'Call after',
                RecordTypeId = recordTypes[0].Id
            );
        }
        insert otherLead;
        
        Test.startTest();
        // Проверяем, что метод выполняется без ошибок
        LeadConversionModalController.showConversionModal(otherLead.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testShowConversionModal_InvalidId() {
        Test.startTest();
        try {
            LeadConversionModalController.showConversionModal('00Q000000000000');
        } catch (AuraHandledException e) {
           
        }
        Test.stopTest();
    }
}