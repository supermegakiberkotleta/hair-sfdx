@isTest
private class CampaignTriggerTest {

    @isTest
    static void testTriggerInsertUpdate() {
        Campaign c = new Campaign(
            Name = 'Trigger Test',
            Type = 'WhatsApp',
            Status = 'Scheduled',
            Message__c = 'Test',
            Scheduled_Date__c = System.now()
        );
        insert c;

        // Обновим кампанию, чтобы покрыть "after update"
        c.Name = 'Trigger Test Updated';
        update c;
    }
}
