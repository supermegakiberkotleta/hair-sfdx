public with sharing class SendMessageToAPI {

    public class Input {
        @InvocableVariable(required=true)
        public String chatId;

        @InvocableVariable(required=true)
        public String message;

        @InvocableVariable(required=true)
        public String channel;

        @InvocableVariable(required=false)
        public Boolean shouldDelete; // ✅ Новое имя переменной
    }

    @InvocableMethod(label='Send Message to External API' description='Send chatId, message, channel and delete to your API')
    public static void send(List<Input> inputs) {
        for (Input input : inputs) {
            System.enqueueJob(new SendMessageJob(input.chatId, input.message, input.channel, input.shouldDelete));
        }
    }

    public class SendMessageJob implements Queueable, Database.AllowsCallouts {
        private String chatId;
        private String message;
        private String channel;
        private Boolean shouldDelete;

        public SendMessageJob(String chatId, String message, String channel, Boolean shouldDelete) {
            this.chatId = chatId;
            this.message = message;
            this.channel = channel;
            this.shouldDelete = shouldDelete;
        }

        public void execute(QueueableContext context) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://hair.lenderpro.ai/chat/send-message?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>{
                'chat_id' => chatId,
                'message' => message,
                'channel' => channel
            };

            // Добавляем поле shouldDelete как "delete" в JSON, если оно задано
            if (shouldDelete != null) {
                payload.put('delete', shouldDelete); // здесь "delete" — это просто ключ JSON, это допустимо
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
}
