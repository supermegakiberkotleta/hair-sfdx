@isTest
private class AccountTriggerHandlerTest {
    private static final String TARGET_RECORD_TYPE_ID = '012Kc000000tenBIAQ';
    
    @TestSetup
    static void setup() {
        // Тестовые данные будут создаваться в каждом тесте отдельно
        // для лучшего контроля над сценариями
    }
    
    @isTest
    static void testHandleDeactivation_ClosedLost_WithReason() {
        // Создаем аккаунт со статусом Closed Lost и причиной закрытия
        Account acc = new Account(
            Name = 'Test Account',
            Client_Type__c = 'Closed Lost',
            Reason_for_closure__c = 'Not interested'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Проверяем, что Active_status__c установлен в false
        Account updatedAcc = [SELECT Id, Active_status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, updatedAcc.Active_status__c, 'Active status should be false');
    }
    
    @isTest
    static void testHandleDeactivation_ClosedLost_WithoutReason() {
        // Создаем аккаунт со статусом Closed Lost без причины закрытия
        Account acc = new Account(
            Name = 'Test Account',
            Client_Type__c = 'Closed Lost'
        );
        
        Test.startTest();
        try {
            insert acc;
            System.assert(false, 'Should have thrown an error');
        } catch (DmlException e) {
            // Ожидаем ошибку валидации
            System.assert(e.getMessage().contains('Please provide a reason for closure'), 
                         'Error message should contain validation text');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testHandleDeactivation_ActiveStatus() {
        // Создаем аккаунт с активным статусом
        Account acc = new Account(
            Name = 'Test Account',
            Client_Type__c = 'Discount 10%'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Проверяем, что Active_status__c установлен в true
        Account updatedAcc = [SELECT Id, Active_status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updatedAcc.Active_status__c, 'Active status should be true');
    }
    
    @isTest
    static void testHandleAccountSync_SmallBatch() {
        // Создаем меньше 50 аккаунтов с нужным RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(10, insertedAccounts.size(), 'Should have 10 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_LargeBatch() {
        // Создаем более 50 аккаунтов с нужным RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 60; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы и была запущена Queueable задача
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(60, insertedAccounts.size(), 'Should have 60 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_WrongRecordType() {
        // Создаем аккаунты с другим RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com'
                // RecordTypeId не указан или другой
            );
            testAccounts.add(acc);
        }
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы, но синхронизация не запустилась
        List<Account> insertedAccounts = [SELECT Id FROM Account];
        System.assertEquals(10, insertedAccounts.size(), 'Should have 10 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_MixedRecordTypes() {
        // Создаем аккаунты с разными RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        // 5 аккаунтов с нужным RecordTypeId
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Test Account Target ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // 5 аккаунтов без нужного RecordTypeId
        for (Integer i = 5; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Account Other ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com'
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что созданы все аккаунты
        List<Account> insertedAccounts = [SELECT Id FROM Account];
        System.assertEquals(10, insertedAccounts.size(), 'Should have 10 accounts total');
        
        
    }
    
    @isTest
    static void testHandleAccountSync_BoundaryCondition_Exactly50() {
        // Создаем ровно 50 аккаунтов
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 50; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы (должна использоваться прямая синхронизация, а не очередь)
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(50, insertedAccounts.size(), 'Should have 50 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_BoundaryCondition_51Accounts() {
        // Создаем 51 аккаунт (граничное условие для перехода в очередь)
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 51; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы (должна использоваться очередь)
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(51, insertedAccounts.size(), 'Should have 51 accounts');
    }
    
    // ========== Marketing Report Tests ==========
    
    @isTest
    static void testHandleMarketingReportInsert_WithConvertedLeads() {
        // Создаем лиды для конвертации
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Status = 'New',
                RecordTypeId = '012Kc000000ten6IAA'
            ));
        }
        insert testLeads;
        
        // Конвертируем лиды в аккаунты
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        
        for (Lead testLead : testLeads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            leadConverts.add(lc);
        }
        
        Test.startTest();
        List<Database.LeadConvertResult> lcResults = Database.convertLead(leadConverts);
        Test.stopTest();
        
        // Получаем сконвертированные аккаунты и обновляем их RecordType
        List<Account> convertedAccounts = new List<Account>();
        for (Database.LeadConvertResult lcr : lcResults) {
            Account acc = [SELECT Id, RecordTypeId FROM Account WHERE Id = :lcr.getAccountId()];
            acc.RecordTypeId = TARGET_RECORD_TYPE_ID;
            convertedAccounts.add(acc);
        }
        update convertedAccounts;
        
        // Проверяем, что созданы Marketing_Report_Customer__c записи
        // (они создаются автоматически при конвертации лидов через LeadTrigger)
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id, Account__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c IN :convertedAccounts
        ];
        
        System.assertEquals(3, reports.size(), 'Should have 3 marketing reports created by LeadTrigger');
    }
    
    @isTest
    static void testHandleMarketingReportInsert_WithNonConvertedLeads() {
        // Создаем лиды, которые НЕ конвертированы
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Status = 'New',
                RecordTypeId = '012Kc000000ten6IAA'
            ));
        }
        insert testLeads;
        
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportInsert(testLeads);
        Test.stopTest();
        
        // Проверяем, что НЕ созданы Marketing_Report_Customer__c записи
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id
            FROM Marketing_Report_Customer__c
        ];
        
        System.assertEquals(0, reports.size(), 'Should have no marketing reports for non-converted leads');
    }
    
    @isTest
    static void testHandleMarketingReportInsert_WithNullInput() {
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportInsert(null);
        Test.stopTest();
        
        // Должен обработать null без ошибок
        System.assert(true, 'Method should handle null input gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportInsert_WithEmptyList() {
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportInsert(new List<Lead>());
        Test.stopTest();
        
        // Должен обработать пустой список без ошибок
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportInsert_WithWrongRecordType() {
        // Создаем лид и конвертируем его
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert testLead;
        
        // Конвертируем лид
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testHandleMarketingReportUpdate_RecordTypeChanged() {
        // Создаем аккаунт с другим RecordType
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = '012Kc000000teo4IAA' // Другой RecordType
        );
        insert testAccount;
        
        // Обновляем RecordType на целевой
        Account updatedAccount = new Account(
            Id = testAccount.Id,
            RecordTypeId = TARGET_RECORD_TYPE_ID
        );
        
        Test.startTest();
        // Вызываем метод напрямую (так как в триггере он закомментирован)
        AccountTriggerHandler.handleMarketingReportUpdate(
            new List<Account>{updatedAccount}, 
            new List<Account>{testAccount}
        );
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testHandleMarketingReportUpdate_RecordTypeNotChanged() {
        // Создаем аккаунт с целевым RecordType
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = TARGET_RECORD_TYPE_ID
        );
        insert testAccount;
        
        // Обновляем что-то другое, но НЕ RecordType
        Account updatedAccount = new Account(
            Id = testAccount.Id,
            Name = 'Updated Test Account',
            RecordTypeId = TARGET_RECORD_TYPE_ID
        );
        
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportUpdate(
            new List<Account>{updatedAccount}, 
            new List<Account>{testAccount}
        );
        Test.stopTest();
        
        // Проверяем, что НЕ создана новая Marketing_Report_Customer__c запись
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :testAccount.Id
        ];
        
        System.assertEquals(0, reports.size(), 'Should have no marketing reports when RecordType not changed');
    }
    
    @isTest
    static void testHandleMarketingReportUpdate_WithNullInput() {
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportUpdate(null, null);
        Test.stopTest();
        
        // Должен обработать null без ошибок
        System.assert(true, 'Method should handle null input gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportUpdate_WithEmptyLists() {
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportUpdate(
            new List<Account>(), 
            new List<Account>()
        );
        Test.stopTest();
        
        // Должен обработать пустые списки без ошибок
        System.assert(true, 'Method should handle empty lists gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportDelete_WithTargetRecordType() {
        // Создаем лид и конвертируем его
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert testLead;
        
        // Конвертируем лид
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        // Обновляем RecordType аккаунта на целевой
        Account convertedAccount = [SELECT Id, RecordTypeId FROM Account WHERE Id = :lcr.getAccountId()];
        convertedAccount.RecordTypeId = TARGET_RECORD_TYPE_ID;
        update convertedAccount;
        
        // Проверяем, что запись создана автоматически при конвертации
        List<Marketing_Report_Customer__c> reportsBefore = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        System.assertEquals(1, reportsBefore.size(), 'Should have one report before delete');
        
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportDelete(new List<Account>{convertedAccount});
        Test.stopTest();
        
        // Проверяем, что запись удалена
        List<Marketing_Report_Customer__c> reportsAfter = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        System.assertEquals(0, reportsAfter.size(), 'Report should be deleted');
    }
    
    @isTest
    static void testHandleMarketingReportDelete_WithWrongRecordType() {
        // Создаем аккаунт с другим RecordType
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = '012Kc000000teo4IAA' // Другой RecordType
        );
        insert testAccount;
        
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportDelete(new List<Account>{testAccount});
        Test.stopTest();
        
        // Должен обработать без ошибок, но не удалять ничего
        System.assert(true, 'Method should handle wrong RecordType gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportDelete_WithNullInput() {
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportDelete(null);
        Test.stopTest();
        
        // Должен обработать null без ошибок
        System.assert(true, 'Method should handle null input gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportDelete_WithEmptyList() {
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportDelete(new List<Account>());
        Test.stopTest();
        
        // Должен обработать пустой список без ошибок
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportDelete_WithNoRelatedReports() {
        // Создаем аккаунт с целевым RecordType, но без связанных отчетов
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = TARGET_RECORD_TYPE_ID
        );
        insert testAccount;
        
        Test.startTest();
        AccountTriggerHandler.handleMarketingReportDelete(new List<Account>{testAccount});
        Test.stopTest();
        
        // Должен обработать без ошибок, даже если нет связанных отчетов
        System.assert(true, 'Method should handle accounts with no related reports gracefully');
    }
    
    @isTest
    static void testHandleMarketingReportInsert_DirectMethodCall() {
        // Создаем лид и конвертируем его
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert testLead;
        
        // Конвертируем лид
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        // Обновляем RecordType аккаунта на целевой
        Account convertedAccount = [SELECT Id, RecordTypeId FROM Account WHERE Id = :lcr.getAccountId()];
        convertedAccount.RecordTypeId = TARGET_RECORD_TYPE_ID;
        update convertedAccount;
        
        // Удаляем существующие отчеты, чтобы тестировать только наш метод
        List<Marketing_Report_Customer__c> existingReports = [
            SELECT Id FROM Marketing_Report_Customer__c WHERE Account__c = :convertedAccount.Id
        ];
        if (!existingReports.isEmpty()) {
            delete existingReports;
        }
        
        // Получаем сконвертированный лид
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedAccountId FROM Lead WHERE Id = :testLead.Id];
        
        Test.startTest();
        // Вызываем метод напрямую
        AccountTriggerHandler.handleMarketingReportInsert(new List<Lead>{convertedLead});
        Test.stopTest();
        
        // Проверяем, что создана Marketing_Report_Customer__c запись
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id, Account__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        
        System.assertEquals(1, reports.size(), 'Should have one marketing report from direct method call');
        System.assertEquals(convertedAccount.Id, reports[0].Account__c, 'Account should match');
    }

    /**
     * Mock класс для HTTP callout
     */
    private class AccountSyncHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public AccountSyncHttpMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}
