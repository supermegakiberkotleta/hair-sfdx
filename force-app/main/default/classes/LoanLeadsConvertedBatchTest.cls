@isTest
private class LoanLeadsConvertedBatchTest {
    @isTest
    static void testBatchConvertsLeadSuccessfully() {
        // Создаём тестового лида
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA',
            Final_Daily_payment__c = 100,
            Final_purchased_Amount_of_Future_New__c = 100,
            Payment_Frequency__c = '100',
            Loan_Start_Date__c = Date.newInstance(2025, 6, 12),
            Final_Term__c = '100',
            Client_email__c = 'test@test.test'
        );
        insert testLead;

        // Запускаем батч
        Test.startTest();
        LoanLeadsConvertedBatch batch = new LoanLeadsConvertedBatch(new List<Id>{ testLead.Id });
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Проверяем, что лид сконвертирован
        Lead converted = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
                          FROM Lead WHERE Id = :testLead.Id];
    }
}
