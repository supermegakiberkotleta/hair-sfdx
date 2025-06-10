trigger BrokerFeeLeadTrigger on Lead (after insert, after update) {
    Boolean shouldRun = false;

    for (Lead l : Trigger.new) {
        Lead old = Trigger.isUpdate ? Trigger.oldMap.get(l.Id) : null;
        if (l.OfferAmount__c != null && (old == null || old.OfferAmount__c != l.OfferAmount__c)) {
            shouldRun = true;
            break;
        }
        if (l.Tag__c != null && (old == null || old.Tag__c != l.Tag__c)) {
            shouldRun = true;
            break;
        }
    }

    if (shouldRun) {
        Database.executeBatch(new BrokerFeeBatch('Lead'), 200);
    }
}
