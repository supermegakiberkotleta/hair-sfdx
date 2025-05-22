@isTest
private class SendMessageToAPI_Test {

    @isTest
    static void testSendMethodWithQueueable() {
        // Arrange: создаем input
        SendMessageToAPI.Input input = new SendMessageToAPI.Input();
        input.chatId = '1234567890';
        input.message = 'Hello from test';
        input.channel = 'facebook';
        List<SendMessageToAPI.Input> inputs = new List<SendMessageToAPI.Input>{ input };

        // Set mock for the callout
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        // Act: запустить как отдельную транзакцию
        Test.startTest();
        SendMessageToAPI.send(inputs); // enqueueJob
        Test.stopTest(); // выполнение очереди и callout здесь

        // Assert: можно проверять логи или добавлять asserts, если логируешь
        System.debug('SendMessageToAPI job enqueued and executed');
    }

}
