@isTest
private class AccountMarketingReportHandlerTest {
    private static final Id TARGET_RECORD_TYPE_ID = '012Kc000000tenBIAQ';
    
    @TestSetup
    static void setupTestData() {
        // Create test leads
        List<Lead> testLeads = new List<Lead>();
        
        // Lead created this year
        Lead lead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test Company 1',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        testLeads.add(lead1);
        
        // Lead created in a different year (simulate by setting created date in test)
        Lead lead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test Company 2',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        testLeads.add(lead2);
        
        insert testLeads;
    }
    
    @isTest
    static void testCreateMarketingReportOnAccountInsert() {
        // Create lead and convert it to account
        Lead testLead = [SELECT Id, CreatedDate FROM Lead WHERE LastName = 'Lead1' LIMIT 1];
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Account convertedAccount = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
        
        Test.startTest();
        // Call the handler method directly with the converted account
        List<Account> accountsToProcess = new List<Account>{convertedAccount};
        AccountMarketingReportHandler.handleAfterInsert(accountsToProcess);
        Test.stopTest();
        
        // Verify Marketing_Report_Customer__c record was created
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id, Account__c, Date_Message__c, Active__c, Month_Message__c, Week_Message__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
                
        System.assertEquals(1, reports.size(), 'Should have one report');
        System.assertEquals(convertedAccount.Id, reports[0].Account__c, 'Account should match');
        System.assertNotEquals(null, reports[0].Date_Message__c, 'Date should be set');
        System.assertNotEquals(null, reports[0].Active__c, 'Active flag should be set');
        System.assertNotEquals(null, reports[0].Month_Message__c, 'Month should be set');
        System.assertNotEquals(null, reports[0].Week_Message__c, 'Week should be set');
    }
    
    @isTest
    static void testCreateMarketingReportBulkInsert() {
        // Get test leads
        List<Lead> testLeads = [SELECT Id, CreatedDate FROM Lead];
        
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        
        for (Lead testLead : testLeads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            leadConverts.add(lc);
        }
        
        List<Database.LeadConvertResult> lcResults = Database.convertLead(leadConverts);
        
        // Get converted accounts
        List<Account> convertedAccounts = new List<Account>();
        for (Database.LeadConvertResult lcr : lcResults) {
            Account acc = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
            convertedAccounts.add(acc);
        }
        
        Test.startTest();
        // Call the handler method directly with converted accounts
        AccountMarketingReportHandler.handleAfterInsert(convertedAccounts);
        Test.stopTest();
        
        // Verify Marketing_Report_Customer__c records were created
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id, Account__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c IN :convertedAccounts
        ];
        
        System.assertEquals(2, reports.size(), 'Should have 2 reports for 2 converted leads');
    }
    
    @isTest
    static void testDeleteMarketingReportOnAccountDelete() {
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead1' LIMIT 1];
        
        // Convert lead to account
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Account convertedAccount = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
        
        // Create report first by calling the handler
        List<Account> accountsToProcess = new List<Account>{convertedAccount};
        AccountMarketingReportHandler.handleAfterInsert(accountsToProcess);
        
        // Verify report was created
        List<Marketing_Report_Customer__c> reportsBefore = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        System.assertEquals(1, reportsBefore.size(), 'Should have one report before delete');
        
        Test.startTest();
        // Call the delete handler method directly
        AccountMarketingReportHandler.handleBeforeDelete(accountsToProcess);
        Test.stopTest();
        
        // Verify report was deleted
        List<Marketing_Report_Customer__c> reportsAfter = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        System.assertEquals(0, reportsAfter.size(), 'Report should be deleted');
    }
    
    @isTest
    static void testIgnoreAccountsWithDifferentRecordType() {
        // Get test lead
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead1' LIMIT 1];
        
        // Convert lead to account
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        
        // Don't update RecordTypeId, leave it as default
        Account convertedAccount = [SELECT Id, RecordTypeId FROM Account WHERE Id = :lcr.getAccountId()];
        
        Test.stopTest();
        
        // Verify NO Marketing_Report_Customer__c record was created
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        
        System.assertEquals(0, reports.size(), 'No report should be created for account with different RecordType');
    }
    
    @isTest
    static void testWeekNumberCalculation() {
        // Test week number for different dates
        Date jan1 = Date.newInstance(2025, 1, 1);
        Date jan8 = Date.newInstance(2025, 1, 8);
        Date may22 = Date.newInstance(2025, 5, 22);
        
        // Create a lead for testing
        Lead testLead = new Lead(
            FirstName = 'Week',
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert testLead;
        
        // Convert and create account with target RecordType
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Account convertedAccount = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
        
        Test.startTest();
        // Call the handler method directly with the converted account
        List<Account> accountsToProcess = new List<Account>{convertedAccount};
        AccountMarketingReportHandler.handleAfterInsert(accountsToProcess);
        Test.stopTest();
        
        // Verify week number is calculated
        List<Marketing_Report_Customer__c> reports = [
            SELECT Week_Message__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        
        System.assertEquals(1, reports.size(), 'Should have one report');
        System.assertNotEquals(null, reports[0].Week_Message__c, 'Week number should be calculated');
    }
    
    @isTest
    static void testHandleAfterInsertWithNullInput() {
        Test.startTest();
        AccountMarketingReportHandler.handleAfterInsert(null);
        Test.stopTest();
        
        // Should not throw any exception
        System.assert(true, 'Method should handle null input gracefully');
    }
    
    @isTest
    static void testHandleAfterInsertWithEmptyList() {
        Test.startTest();
        AccountMarketingReportHandler.handleAfterInsert(new List<Account>());
        Test.stopTest();
        
        // Should not throw any exception
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    @isTest
    static void testHandleBeforeDeleteWithNullInput() {
        Test.startTest();
        AccountMarketingReportHandler.handleBeforeDelete(null);
        Test.stopTest();
        
        // Should not throw any exception
        System.assert(true, 'Method should handle null input gracefully');
    }
    
    @isTest
    static void testHandleBeforeDeleteWithEmptyList() {
        Test.startTest();
        AccountMarketingReportHandler.handleBeforeDelete(new List<Account>());
        Test.stopTest();
        
        // Should not throw any exception
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    @isTest
    static void testAccountWithoutConvertedLead() {
        // Create account directly (not from lead conversion) with target RecordType
        // This will trigger the handler, but no report should be created since there's no converted lead
        Account testAccount = new Account(
            Name = 'Direct Account',
            RecordTypeId = TARGET_RECORD_TYPE_ID
        );
        
        Test.startTest();
        insert testAccount;
        Test.stopTest();
        
        // Verify no Marketing_Report_Customer__c record was created
        List<Marketing_Report_Customer__c> reports = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :testAccount.Id
        ];
        
        System.assertEquals(0, reports.size(), 'No report should be created for account without converted lead');
    }
    
    @isTest
    static void testActiveYearCalculation() {
        // Create lead with current year date
        Lead testLead = new Lead(
            FirstName = 'Active',
            LastName = 'Year',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert testLead;
        
        // Convert lead to account
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Account convertedAccount = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
        
        Test.startTest();
        // Call the handler method directly with the converted account
        List<Account> accountsToProcess = new List<Account>{convertedAccount};
        AccountMarketingReportHandler.handleAfterInsert(accountsToProcess);
        Test.stopTest();
        
        // Verify Active__c field is set correctly
        List<Marketing_Report_Customer__c> reports = [
            SELECT Active__c, Date_Message__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        
        System.assertEquals(1, reports.size(), 'Should have one report');
        System.assertEquals(true, reports[0].Active__c, 'Should be active for current year');
        System.assertEquals(Date.today().year(), reports[0].Date_Message__c.year(), 'Date should be current year');
    }
    
    @isTest
    static void testMonthMessageCalculation() {
        // Create lead
        Lead testLead = new Lead(
            FirstName = 'Month',
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert testLead;
        
        // Convert lead to account
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Account convertedAccount = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
        
        Test.startTest();
        // Call the handler method directly with the converted account
        List<Account> accountsToProcess = new List<Account>{convertedAccount};
        AccountMarketingReportHandler.handleAfterInsert(accountsToProcess);
        Test.stopTest();
        
        // Verify Month_Message__c field is set correctly
        List<Marketing_Report_Customer__c> reports = [
            SELECT Month_Message__c, Date_Message__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c = :convertedAccount.Id
        ];
        
        System.assertEquals(1, reports.size(), 'Should have one report');
        System.assertEquals(Date.today().month(), reports[0].Month_Message__c, 'Month should match current month');
    }
    
    @isTest
    static void testDeleteWithNoRelatedReports() {
        // Create account directly (not from lead conversion)
        Account testAccount = new Account(
            Name = 'No Report Account',
            RecordTypeId = TARGET_RECORD_TYPE_ID
        );
        insert testAccount;
        
        Test.startTest();
        delete testAccount;
        Test.stopTest();
        
        // Should not throw any exception even if no reports exist
        System.assert(true, 'Delete should handle accounts with no related reports gracefully');
    }
    
    @isTest
    static void testBulkDeleteWithReports() {
        // Create multiple leads
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            testLeads.add(new Lead(
                FirstName = 'Bulk',
                LastName = 'Test' + i,
                Company = 'Test Company ' + i,
                Status = 'New',
                RecordTypeId = '012Kc000000ten6IAA'
            ));
        }
        insert testLeads;
        
        // Convert leads to accounts
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        
        for (Lead testLead : testLeads) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(testLead.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            leadConverts.add(lc);
        }
        
        List<Database.LeadConvertResult> lcResults = Database.convertLead(leadConverts);
        
        // Get converted accounts
        List<Account> convertedAccounts = new List<Account>();
        for (Database.LeadConvertResult lcr : lcResults) {
            Account acc = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
            convertedAccounts.add(acc);
        }
        
        // Create reports by calling the handler
        AccountMarketingReportHandler.handleAfterInsert(convertedAccounts);
        
        // Verify reports were created
        List<Marketing_Report_Customer__c> reportsBefore = [
            SELECT Id, Account__c
            FROM Marketing_Report_Customer__c
            WHERE Account__c IN :convertedAccounts
        ];
        System.assertEquals(3, reportsBefore.size(), 'Should have 3 reports before delete');
        
        Test.startTest();
        // Call the delete handler method directly
        AccountMarketingReportHandler.handleBeforeDelete(convertedAccounts);
        Test.stopTest();
        
        // Verify reports were deleted
        List<Marketing_Report_Customer__c> reportsAfter = [
            SELECT Id
            FROM Marketing_Report_Customer__c
            WHERE Account__c IN :convertedAccounts
        ];
        System.assertEquals(0, reportsAfter.size(), 'All reports should be deleted');
    }
}

