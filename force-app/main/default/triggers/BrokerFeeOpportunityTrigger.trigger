trigger BrokerFeeOpportunityTrigger on Opportunity (after insert, after update) {
    Boolean shouldRun = false;

    for (Opportunity o : Trigger.new) {
        Opportunity old = Trigger.isUpdate ? Trigger.oldMap.get(o.Id) : null;
        if (o.OfferAmount__c != null && (old == null || old.OfferAmount__c != o.OfferAmount__c)) {
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
        BrokerFeeBatchInvoker.runBatch('Opportunity');
    }
}
