public class CampaignMessageUtilsDebug {

    public static String getChatId(SObject record, String channel) {
        System.debug('⚙️ getChatId called. Channel = ' + channel + ', Record = ' + record);

        if (channel == 'Facebook') {
            String chatId = (String)record.get('Facebook_PSID__c');
            System.debug('✅ Facebook PSID: ' + chatId);
            return chatId;
        }

        if (channel == 'Instagram') {
            String chatId = (String)record.get('Instagram_PSID__c');
            System.debug('✅ Instagram PSID: ' + chatId);
            return chatId;
        }

        if (channel == 'WhatsApp') {
            String chatId = (String)record.get('WhatsApp_ID__c');
            System.debug('✅ WhatsApp ID: ' + chatId);
            return chatId;
        }

        if (channel == 'SMS') {
            String chatId = (String)record.get('Phone');
            System.debug('✅ Phone: ' + chatId);
            return chatId;
        }

        System.debug('❌ No chatId found for channel: ' + channel);
        return null;
    }

    public static Boolean sendMessage(String chatId, String message, String channel) {
        System.debug('🚀 sendMessage() MOCK called. ChatId = ' + chatId + ', Message = "' + message + '", Channel = ' + channel);
        return true; // <--- отключили настоящий callout
    }
}