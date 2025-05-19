@isTest
private class LeadConverterApiTest {
    @isTest
    static void testLeadConversion() {
        // Создаем тестового лида
        Lead lead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'Open - Not Contacted'
        );
        insert lead;

        // Устанавливаем статус конверсии
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
        lead.Status = convertStatus.MasterLabel;
        update lead;

        // Формируем JSON
        String jsonInput = JSON.serialize(new Map<String, Object>{
            'leadId' => lead.Id,
            'convertedStatus' => convertStatus.MasterLabel,
            'doNotCreateOpportunity' => true
        });

        // Устанавливаем mock запрос
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestUri = '/services/apexrest/LeadConverter';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonInput);
        RestContext.request = req;
        RestContext.response = res;

        // Выполняем вызов
        LeadConverterApi.ResponseWrapper result = LeadConverterApi.convertLead();

        System.assert(result.success, 'Conversion should succeed');
        System.assertNotEquals(null, result.accountId);
        System.assertNotEquals(null, result.contactId);
    }
}
