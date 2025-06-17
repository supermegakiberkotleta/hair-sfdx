trigger BrokerFeeContactTrigger on Contact (after insert, after update) {
    Boolean shouldRun = false;

    for (Contact c : Trigger.new) {
        Contact old = Trigger.isUpdate ? Trigger.oldMap.get(c.Id) : null;
        if (c.OfferAmount__c != null && (old == null || old.OfferAmount__c != c.OfferAmount__c)) {
            shouldRun = true;
            break;
        }
    }

    if (
        shouldRun &&
        !Test.isRunningTest() &&
        !System.isFuture() &&
        !System.isBatch() &&
        !System.isQueueable()
    ) {
        BrokerFeeBatchInvoker.runBatch('Contact');
    }
}
