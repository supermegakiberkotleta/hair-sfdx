public with sharing class SendMessageToAPI {

    public class Input {
        @InvocableVariable(required=true)
        public String chatId;

        @InvocableVariable(required=true)
        public String message;

        @InvocableVariable(required=true)
        public String channel;

        @InvocableVariable(required=false)
        public Boolean shouldDelete;

        @InvocableVariable(required=false)
        public String contentUri; // ✅ Новое поле
    }

    @InvocableMethod(label='Send Message to External API' description='Send chatId, message, channel, contentUri and delete to your API')
    public static void send(List<Input> inputs) {
        for (Input input : inputs) {
            sendMessage(input.chatId, input.message, input.channel, input.shouldDelete, input.contentUri);
        }
    }

    @future(callout=true)
    private static void sendMessage(String chatId, String message, String channel, Boolean shouldDelete, String contentUri) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://hair.lenderpro.ai/chat/send-message?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'chat_id' => chatId,
            'message' => message,
            'channel' => channel
        };

        if (shouldDelete != null) {
            payload.put('delete', shouldDelete);
        }

        if (String.isNotBlank(contentUri)) {
            payload.put('content_uri', contentUri); // ➕ Добавляем ссылку если указана
        }

        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        try {
            HTTPResponse res = http.send(req);
            System.debug('Callout Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Callout Error: ' + e.getMessage());
        }
    }
}