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
            Phone = '1234567890'
        );
        insert testLead;

        // Получаем лида до конвертации
        Lead oldLead = [SELECT Id, IsConverted FROM Lead WHERE Id = :testLead.Id];

        // Подготавливаем данные для конвертации
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(testLead.Id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Closed Won'); // Убедитесь, что статус "Closed Won" существует в Org

        Test.startTest();
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Test.stopTest();

        // Получаем лида после конвертации
        Lead newLead = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId
                        FROM Lead WHERE Id = :testLead.Id];

        // Создаем map с "до" состоянием
        Map<Id, Lead> oldMap = new Map<Id, Lead>{ oldLead.Id => oldLead };

        // Вызываем обработчик
        LeadConvertHandler.afterLeadConvert(new List<Lead>{ newLead }, oldMap);
    }
}