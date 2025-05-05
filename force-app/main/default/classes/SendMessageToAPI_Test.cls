@isTest
private class SendMessageToAPI_Test {
    
    @isTest
    static void testSendMethod() {
        // Создаем фейковый input
        SendMessageToAPI.Input input = new SendMessageToAPI.Input();
        input.chatId = '1234567890';
        input.message = 'Hello from test';
        input.channel = 'facebook';

        List<SendMessageToAPI.Input> inputs = new List<SendMessageToAPI.Input>{ input };

        // Создаем mock для внешнего запроса
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());

        // Вызываем метод
        List<SendMessageToAPI.Output> outputs = SendMessageToAPI.send(inputs);

        System.assertEquals(1, outputs.size());
        System.assert(outputs[0].response != null);
    }
}
