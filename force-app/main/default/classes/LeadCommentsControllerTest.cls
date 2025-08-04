@isTest
private class LeadCommentsControllerTest {
    @TestSetup
    static void setupTestData() {
        // Создаем тестового пользователя
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u = new User(
            Alias = 'standt',
            Email = 'test@eduelevator.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'standarduser@eduelevator.com'
        );
        insert u;
    }
    
    @isTest
    static void testAddAndGetComments() {
        User testUser = [SELECT Id FROM User WHERE Email = 'test@eduelevator.com' LIMIT 1];
        
        System.runAs(testUser) {
            // Создаем тестового лида
            Lead testLead = new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'customer@eduelevator.com'
            );
            insert testLead;
            
            Test.startTest();
            
            // Добавляем комментарий
            LeadCommentsController.addComment(testLead.Id, 'Test Comment');
            
            // Получаем комментарии
            List<LeadCommentsController.CommentWrapper> comments = LeadCommentsController.getComments(testLead.Id);
            
            Test.stopTest();
            
            // Проверяем результаты
            System.assertEquals(1, comments.size(), 'Should have one comment');
            System.assertEquals('Test Comment', comments[0].body, 'Comment text should match');
        }
    }
    
    @isTest
    static void testGetCommentsEmpty() {
        User testUser = [SELECT Id FROM User WHERE Email = 'test@eduelevator.com' LIMIT 1];
        
        System.runAs(testUser) {
            // Создаем тестового лида
            Lead testLead = new Lead(
                LastName = 'Test Lead',
                Company = 'Test Company',
                Email = 'customer@eduelevator.com'
            );
            insert testLead;
            
            Test.startTest();
            
            // Получаем комментарии для лида без комментариев
            List<LeadCommentsController.CommentWrapper> comments = LeadCommentsController.getComments(testLead.Id);
            
            Test.stopTest();
            
            // Проверяем результаты
            System.assertEquals(0, comments.size(), 'Should have no comments');
        }
    }
    
    @isTest
    static void testAddCommentError() {
        User testUser = [SELECT Id FROM User WHERE Email = 'test@eduelevator.com' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Boolean exceptionThrown = false;
            try {
                // Тестируем добавление комментария с неверным Id
                LeadCommentsController.addComment('001000000000000', 'Test Comment');
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            
            Test.stopTest();
            
            // Проверяем, что исключение было выброшено
            System.assert(exceptionThrown, 'Exception should be thrown');
        }
    }
    
    @isTest
    static void testGetCommentsError() {
        User testUser = [SELECT Id FROM User WHERE Email = 'test@eduelevator.com' LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            
            Boolean exceptionThrown = false;
            try {
                // Тестируем получение комментариев с неверным Id
                LeadCommentsController.getComments('001000000000000');
            } catch (AuraHandledException e) {
                exceptionThrown = true;
            }
            
            Test.stopTest();
            
            // Проверяем, что исключение было выброшено
            System.assert(exceptionThrown, 'Exception should be thrown');
        }
    }
}