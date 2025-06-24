@isTest
public class LeadConvertHandlerTest {

    @isTest
    static void testAfterLeadConvert() {
        // Создаем тестового лида
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@gvahair.com',
            Phone = '1234567890',
            RecordTypeId = '012Kc000000tenuIAA',
            Final_Daily_payment__c = 100,
            Final_purchased_Amount_of_Future_New__c = 100,
            Payment_Frequency__c = '100',
            Loan_Start_Date__c = Date.newInstance(2025, 6, 12),
            Final_Term__c = '100',
            Client_email__c = 'test@test.test'
        );
        insert testLead;

        // Получаем лида до конвертации
        Lead oldLead = [SELECT Id, IsConverted, RecordTypeId,
                Final_Daily_payment__c,
                Final_purchased_Amount_of_Future_New__c,
                Payment_Frequency__c,
                Loan_Start_Date__c,
                Final_Term__c,
                Client_email__c FROM Lead WHERE Id = :testLead.Id];

        // Подготавливаем данные для конвертации
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Convrted Loan');

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        // Получаем лида после конвертации
        Lead newLead = [
            SELECT Id,
                IsConverted,
                ConvertedAccountId,
                ConvertedContactId,
                ConvertedOpportunityId,
                RecordTypeId,
                Final_Daily_payment__c,
                Final_purchased_Amount_of_Future_New__c,
                Payment_Frequency__c,
                Loan_Start_Date__c,
                Final_Term__c,
                Client_email__c
            FROM Lead
            WHERE Id = :testLead.Id
        ];

        // Создаем map с "до" состоянием
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ oldLead.Id => oldLead };

        // Вызываем обработчик
        LeadConvertHandler.afterLeadConvert(new List<Lead>{ newLead }, oldMap);
    }
}