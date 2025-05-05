public with sharing class SendMessageToAPI {
    
    public class Input {
        @InvocableVariable(required=true)
        public String chatId;

        @InvocableVariable(required=true)
        public String message;

        @InvocableVariable(required=true)
        public String channel; // Новое поле
    }

    public class Output {
        @InvocableVariable
        public String response;
    }

    @InvocableMethod(label='Send Message to External API' description='Send chatId, message, and channel to your API')
    public static List<Output> send(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input input : inputs) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://hair.lenderpro.ai/chat/send-message?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            String body = JSON.serialize(new Map<String, Object>{
                'chat_id' => input.chatId,
                'message' => input.message,
                'channel' => input.channel
            });
            req.setBody(body);

            Http http = new Http();
            Output output = new Output();

            try {
                HTTPResponse res = http.send(req);
                output.response = res.getBody();
            } catch (Exception e) {
                output.response = 'Error: ' + e.getMessage();
            }

            results.add(output);
        }

        return results;
    }
}
