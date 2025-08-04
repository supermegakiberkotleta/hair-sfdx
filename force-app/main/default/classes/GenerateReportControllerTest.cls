@isTest
private class GenerateReportControllerTest {
    
    @isTest
    static void testSendLeadIdSuccess() {
        // Подменяем ответ внешнего сервиса
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Создаём тестового лида
        Lead testLead = new Lead(
            FirstName = 'Тест',
            LastName = 'Лид',
            Company = 'Тестовая компания',
            Status = 'Новый'
        );
        insert testLead;
        
        // Вызов метода
        Test.startTest();
        String result = GenerateReportController.sendLeadId(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что результат начинается с "Успех"
        System.assert(result.startsWith('Успех:'), 'Ответ должен начинаться с "Успех"');
    }
    
}