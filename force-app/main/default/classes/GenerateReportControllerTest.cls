@isTest
private class GenerateReportControllerTest {

    @isTest
    static void testSendLeadId_WithFiles() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Lead testLead = new Lead(
            FirstName = 'Тест',
            LastName = 'Лид',
            Company = 'Тестовая компания',
            Status = 'Новый'
        );
        insert testLead;

        // Создаём тестовый файл
        ContentVersion cv = new ContentVersion(
            Title = 'Test PDF',
            PathOnClient = 'test.pdf',
            VersionData = Blob.valueOf('%PDF-1.4 test pdf content%'),
            IsMajorVersion = true
        );
        insert cv;

        // Получаем реальный Id версии (после insert)
        Id contentVersionId = [
            SELECT Id
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ].Id;

        // Привязываем файл к лиду
        insert new Clear_files__c(
            Lead__c = testLead.Id,
            File_Id__c = contentVersionId
        );

        Test.startTest();
        String result = GenerateReportController.sendLeadId(testLead.Id);
        Test.stopTest();

        System.assert(result.startsWith('Успех:'), 'Ответ должен начинаться с "Успех"');
    }

    @isTest
    static void testSendLeadId_NoFiles() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Lead testLead = new Lead(
            FirstName = 'Без',
            LastName = 'Файлов',
            Company = 'Test Company',
            Status = 'Новый'
        );
        insert testLead;

        Test.startTest();
        String result = GenerateReportController.sendLeadId(testLead.Id);
        Test.stopTest();

        System.assert(result.startsWith('Успех:'), 'Метод должен отработать даже без файлов');
    }
}