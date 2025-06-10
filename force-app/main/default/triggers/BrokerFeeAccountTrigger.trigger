trigger BrokerFeeAccountTrigger on Account (after insert, after update) {
    Boolean shouldRun = false;

    for (Account a : Trigger.new) {
        Account old = Trigger.isUpdate ? Trigger.oldMap.get(a.Id) : null;
        if (a.OfferAmount__c != null && (old == null || old.OfferAmount__c != a.OfferAmount__c)) {
            shouldRun = true;
            break;
        }
    }

    if (shouldRun) {
        Database.executeBatch(new BrokerFeeBatch('Account'), 200);
    }
}
