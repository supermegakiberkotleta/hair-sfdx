@isTest
private class CampaignMessageUtilsDebugTest {

    @isTest
    static void testGetChatIdForAllChannels() {
        SObject record = new Lead(
            Facebook_PSID__c = 'fb123',
            Instagram_PSID__c = 'ig123',
            WhatsApp_ID__c = 'wa123',
            Phone = '+1234567890'
        );

        System.assertEquals('fb123', CampaignMessageUtilsDebug.getChatId(record, 'Facebook'));
        System.assertEquals('ig123', CampaignMessageUtilsDebug.getChatId(record, 'Instagram'));
        System.assertEquals('wa123', CampaignMessageUtilsDebug.getChatId(record, 'WhatsApp'));
        System.assertEquals('+1234567890', CampaignMessageUtilsDebug.getChatId(record, 'SMS'));
        System.assertEquals(null, CampaignMessageUtilsDebug.getChatId(record, 'Unknown'));
    }

    @isTest
    static void testSendMessageMock() {
        Boolean result = CampaignMessageUtilsDebug.sendMessage('chat123', 'Hello', 'Facebook');
        System.assertEquals(true, result);
    }
}