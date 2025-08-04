@isTest
private class SendLeadsToQuickBooksTest {

    // Поддельный HTTP-ответ
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(JSON.serialize(new Map<String, Object>{
                'Last_Sale_Date' => '2024-12-31',
                'Outstanding_Balance' => 1500.75,
                'Customer_Category' => 'Premium',
                'Sales_2023' => 10000,
                'Sales_2024' => 12000
            }));
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest static void testSendLeadsToQuickBooks() {
        // Вставка тестового лида
        Lead l = new Lead(FirstName='Test', LastName='User', Company='Test Inc.', Phone='1234567890');
        insert l;

        // Установка поддельного HTTP-класса
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new SendLeadsToQuickBooks());
        Test.stopTest();

        // Проверка, что поля обновлены
        Lead updatedLead = [SELECT Last_date_of_sale__c, Outstanding_balance__c, Customer_category_quickbooks__c FROM Lead WHERE Id = :l.Id];

        System.assertEquals(Date.newInstance(2024, 12, 31), updatedLead.Last_date_of_sale__c);
        System.assertEquals(1500.75, updatedLead.Outstanding_balance__c);
        System.assertEquals('Premium', updatedLead.Customer_category_quickbooks__c);

        // Проверка, что были созданы записи QuickBooks__c
        List<QuickBooks__c> qbs = [SELECT Lead__c, Name, Total_sales__c FROM QuickBooks__c WHERE Lead__c = :l.Id];
        System.assertEquals(2, qbs.size());

        Set<String> expectedYears = new Set<String>{'2023', '2024'};
        for (QuickBooks__c qb : qbs) {
            System.assert(expectedYears.contains(qb.Name));
        }
    }
}