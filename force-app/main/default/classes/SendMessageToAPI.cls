public with sharing class SendMessageToAPI {

    public class Input {
        @InvocableVariable(required=true)
        public String chatId;

        @InvocableVariable(required=true)
        public String message;

        @InvocableVariable(required=true)
        public String channel;
    }

    @InvocableMethod(label='Send Message to External API' description='Send chatId, message, and channel to your API')
    public static void send(List<Input> inputs) {
        for (Input input : inputs) {
            System.enqueueJob(new SendMessageJob(input.chatId, input.message, input.channel));
        }
    }

    public class SendMessageJob implements Queueable, Database.AllowsCallouts {
        private String chatId;
        private String message;
        private String channel;

        public SendMessageJob(String chatId, String message, String channel) {
            this.chatId = chatId;
            this.message = message;
            this.channel = channel;
        }

        public void execute(QueueableContext context) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://hair.lenderpro.ai/chat/send-message?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            String body = JSON.serialize(new Map<String, Object>{
                'chat_id' => chatId,
                'message' => message,
                'channel' => channel
            });
            req.setBody(body);

            Http http = new Http();

            try {
                HTTPResponse res = http.send(req);
                System.debug('Callout Response: ' + res.getBody());
                // Optionally: write to custom log object or send Platform Event
            } catch (Exception e) {
                System.debug('Callout Error: ' + e.getMessage());
            }
        }
    }
}
