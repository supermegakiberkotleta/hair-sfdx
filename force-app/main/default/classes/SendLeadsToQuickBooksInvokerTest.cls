@isTest
private class SendLeadsToQuickBooksInvokerTest {
    
    @isTest 
    static void testRunBatch() {
        // Подготавливаем тестовые данные
        List<String> dummyInput = new List<String>{'test'};
        
        Test.startTest();
        
        // Вызываем метод invocable
        SendLeadsToQuickBooksInvoker.runBatch(dummyInput);
        
        Test.stopTest();
        
        // Проверяем, что батч был запущен
        // В данном случае просто проверяем, что метод выполнился без ошибок
    }
    
    @isTest 
    static void testRunBatchWithEmptyList() {
        // Тестируем с пустым списком
        List<String> emptyInput = new List<String>();
        
        Test.startTest();
        
        // Вызываем метод invocable с пустым списком
        SendLeadsToQuickBooksInvoker.runBatch(emptyInput);
        
        Test.stopTest();
        
        // Проверяем, что метод выполнился без ошибок
    }
    
    @isTest 
    static void testRunBatchWithNullInput() {
        // Тестируем с null значением
        List<String> nullInput = null;
        
        Test.startTest();
        
        try {
            // Вызываем метод invocable с null
            SendLeadsToQuickBooksInvoker.runBatch(nullInput);
        } catch (Exception e) {
            // Ожидаем исключение при передаче null
        }
        
        Test.stopTest();
    }
}