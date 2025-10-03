trigger OpportunityMissedPaymentTrigger on Opportunity (after insert, after update) {

    Set<Id> toEnqueue = new Set<Id>();

    if (Trigger.isInsert) {
        for (Opportunity opp : Trigger.new) {
            Decimal val = (Decimal) opp.get('Missed_Payment_Count__c');
            if (val != null && val.intValue() == 3) {
                toEnqueue.add(opp.Id);
            }
        }
    }

    if (Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
            Decimal newVal = (Decimal) opp.get('Missed_Payment_Count__c');
            Decimal oldVal = oldOpp == null ? null : (Decimal) oldOpp.get('Missed_Payment_Count__c');

            if (newVal != null && newVal.intValue() == 3
                && (oldVal == null || oldVal.intValue() < 3)) {
                toEnqueue.add(opp.Id);
            }
        }
    }

    for (Id oppId : toEnqueue) {
        System.enqueueJob(new SendMissedPaymentJob((String)oppId));
    }
}