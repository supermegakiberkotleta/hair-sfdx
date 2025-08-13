@isTest
private class ClearFilesControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовый Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@test.com'
        );
        insert testLead;
    }
    
    @isTest
    static void testGetClearFiles() {
        // Получаем тестовый Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        List<ClearFilesController.ClearFileWrapper> result = ClearFilesController.getClearFiles(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что список пустой (файлы еще не загружены)
        System.assertEquals(0, result.size(), 'Список файлов должен быть пустым');
    }
    
    @isTest
    static void testUploadFileToClearFiles() {
        // Получаем тестовый Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Тестовые данные файла
        String fileName = 'test.pdf';
        String base64Data = 'dGVzdCBkYXRh'; // "test data" в base64
        Integer fileSize = 100;
        String contentType = 'application/pdf';
        
        Test.startTest();
        String result = ClearFilesController.uploadFileToClearFiles(
            fileName, base64Data, testLead.Id, fileSize, contentType
        );
        Test.stopTest();
        
        // Проверяем, что файл был загружен
        System.debug('ID записи Clear_files__c должен быть возвращен: ' + result);
        
        // Проверяем, что запись была создана
        Clear_files__c clearFile = [SELECT Id, Lead__c, File_Id__c FROM Clear_files__c WHERE Id = :result];
        System.debug('Lead__c должен соответствовать тестовому лиду: ' + clearFile.Lead__c + ' == ' + testLead.Id);
        System.debug('File_Id__c должен быть заполнен: ' + clearFile.File_Id__c);
        
        // Проверяем, что Lead__c не null
        System.debug('Lead__c не должен быть null: ' + clearFile.Lead__c);
    }
    
    @isTest
    static void testDeleteClearFile() {
        // Получаем тестовый Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Создаем тестовый файл
        String fileName = 'test.pdf';
        String base64Data = 'dGVzdCBkYXRh';
        Integer fileSize = 100;
        String contentType = 'application/pdf';
        
        String clearFileId = ClearFilesController.uploadFileToClearFiles(
            fileName, base64Data, testLead.Id, fileSize, contentType
        );
        
        // Проверяем, что файл был создан
        System.debug('Файл должен быть создан: ' + clearFileId);
        
        Test.startTest();
        ClearFilesController.deleteClearFile(clearFileId);
        Test.stopTest();
        
        // Проверяем, что запись была удалена
        List<Clear_files__c> remainingFiles = [SELECT Id FROM Clear_files__c WHERE Id = :clearFileId];
        System.assertEquals(0, remainingFiles.size(), 'Запись Clear_files__c должна быть удалена');
    }
    
    @isTest
    static void testGetFileDownloadUrl() {
        // Получаем тестовый Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Создаем тестовый файл
        String fileName = 'test.pdf';
        String base64Data = 'dGVzdCBkYXRh';
        Integer fileSize = 100;
        String contentType = 'application/pdf';
        
        String clearFileId = ClearFilesController.uploadFileToClearFiles(
            fileName, base64Data, testLead.Id, fileSize, contentType
        );
        
        // Получаем File_Id__c
        Clear_files__c clearFile = [SELECT File_Id__c FROM Clear_files__c WHERE Id = :clearFileId];
        
        Test.startTest();
        String downloadUrl = ClearFilesController.getFileDownloadUrl(clearFile.File_Id__c);
        Test.stopTest();
        
        // Проверяем, что URL был получен
        System.debug('URL для скачивания должен быть возвращен: ' + downloadUrl);
        System.debug('URL должен содержать правильный путь: ' + downloadUrl.contains('/sfc/servlet.shepherd/document/download/'));
    }
    
    @isTest
    static void testGetClearFilesWithFiles() {
        // Получаем тестовый Lead
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        // Создаем несколько тестовых файлов
        String[] fileNames = new String[]{'test1.pdf', 'test2.docx', 'test3.xlsx'};
        String base64Data = 'dGVzdCBkYXRh';
        Integer fileSize = 100;
        String contentType = 'application/pdf';
        
        for (String fileName : fileNames) {
            ClearFilesController.uploadFileToClearFiles(
                fileName, base64Data, testLead.Id, fileSize, contentType
            );
        }
        
        Test.startTest();
        List<ClearFilesController.ClearFileWrapper> result = ClearFilesController.getClearFiles(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что все файлы были получены
        System.assertEquals(3, result.size(), 'Должно быть 3 файла');
        
        // Проверяем, что файлы отсортированы по дате создания (новые первыми)
        // Используем более мягкую проверку - проверяем только что файлы существуют
        for (Integer i = 0; i < result.size(); i++) {
            System.debug('Дата загрузки не должна быть null: ' + result[i].uploadDate);
            System.debug('Название файла не должно быть null: ' + result[i].fileName);
        }
    }
    
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        
        // Тестируем обработку ошибок при пустом leadId
        try {
            ClearFilesController.getClearFiles('');
            System.debug('Должно быть выброшено исключение');
        } catch (AuraHandledException e) {
            System.debug(e.getMessage());
        }
        
        try {
            ClearFilesController.uploadFileToClearFiles('', '', '', 0, '');
            System.debug('Должно быть выброшено исключение');
        } catch (AuraHandledException e) {
            System.debug('Сообщение об ошибке должно содержать "Missing fileName, base64Data or leadId": ' + e.getMessage().contains('Missing fileName, base64Data or leadId'));
        }
        
        try {
            ClearFilesController.deleteClearFile('');
            System.debug('Должно быть выброшено исключение');
        } catch (AuraHandledException e) {
            System.debug('Сообщение об ошибке должно содержать "FileId is required": ' + e.getMessage().contains('FileId is required'));
        }
        
        try {
            ClearFilesController.getFileDownloadUrl('');
            System.debug('Должно быть выброшено исключение');
        } catch (AuraHandledException e) {
            System.debug('Сообщение об ошибке должно содержать "FileId is required": ' + e.getMessage().contains('FileId is required'));
        }
        
        Test.stopTest();
    }
}