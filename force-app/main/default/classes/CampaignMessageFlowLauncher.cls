public with sharing class CampaignMessageFlowLauncher {
    @InvocableMethod(label='Запустить отправку сообщений')
    public static void launch(List<Id> campaignIds) {
        for (Id campaignId : campaignIds) {
            try {
                System.debug('### Launching batch for: ' + campaignId);
                Database.executeBatch(new CampaignMessageBatch(campaignId), 50);
                System.debug('### Batch submitted for: ' + campaignId);
            } catch (Exception ex) {
                System.debug('### ERROR launching batch: ' + ex.getMessage());
            }
            
        }
    }
}