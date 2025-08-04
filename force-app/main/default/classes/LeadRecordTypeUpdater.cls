public class LeadRecordTypeUpdater implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, RecordTypeId FROM Lead WHERE RecordTypeIdFilter__c = null'
        );
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        for (Lead lead : scope) {
            lead.RecordTypeIdFilter__c = lead.RecordTypeId;
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed successfully.');
    }
}