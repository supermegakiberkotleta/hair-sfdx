public class CampaignMessageUtils {

    public static String getChatId(SObject record, String channel) {
        System.debug('getChatId called with channel: ' + channel + ', record: ' + record);

        if (channel == 'Facebook' && record.getSObjectType().getDescribe().fields.getMap().containsKey('Facebook_PSID__c')) {
            String chatId = (String)record.get('Facebook_PSID__c');
            System.debug('Facebook chat ID: ' + chatId);
            return chatId;
        }

        if (channel == 'Instagram' && record.getSObjectType().getDescribe().fields.getMap().containsKey('Instagram_PSID__c')) {
            String chatId = (String)record.get('Instagram_PSID__c');
            System.debug('Instagram chat ID: ' + chatId);
            return chatId;
        }

        if (channel == 'WhatsApp' && record.getSObjectType().getDescribe().fields.getMap().containsKey('WhatsApp_ID__c')) {
            String chatId = (String)record.get('WhatsApp_ID__c');
            System.debug('WhatsApp chat ID: ' + chatId);
            return chatId;
        }

        if (channel == 'SMS' && record.getSObjectType().getDescribe().fields.getMap().containsKey('Phone')) {
            String chatId = (String)record.get('Phone');
            System.debug('SMS Phone: ' + chatId);
            return chatId;
        }

        System.debug('No chat ID found for channel: ' + channel);
        return null;
    }

    public static Boolean sendMessage(String chatId, String message, String channel) {
        System.debug('sendMessage called with chatId: ' + chatId + ', message: ' + message + ', channel: ' + channel);

        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://hair.lenderpro.ai/chat/send-message?token=lxhWgAsa0Y2zqpHD5pwVAXDOT');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> body = new Map<String, Object>{
            'chat_id' => chatId,
            'message' => message,
            'channel' => channel
        };
        String jsonBody = JSON.serialize(body);
        System.debug('Request body: ' + jsonBody);

        req.setBody(jsonBody);

        try {
            HttpResponse res = http.send(req);
            System.debug('Response status: ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
            return res.getStatusCode() == 200;
        } catch (Exception e) {
            System.debug('Exception during sendMessage: ' + e.getMessage());
            return false;
        }
    }
}
