@isTest
private class CampaignMessageUtilsTest {
    @isTest static void testUtils() {
        SObject record = new Lead();
        String id = CampaignMessageUtils.getChatId(record, 'WhatsApp');
        Boolean sent = CampaignMessageUtils.sendMessage('123', 'test', 'WhatsApp');
        //System.assertEquals(true, sent);
    }
}