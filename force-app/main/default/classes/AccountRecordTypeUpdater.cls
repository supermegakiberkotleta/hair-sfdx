public class AccountRecordTypeUpdater implements Database.Batchable<SObject> {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, RecordTypeId FROM Account WHERE RecordTypeIdFilter__c = null'
        );
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        for (Account account : scope) {
            account.RecordTypeIdFilter__c = account.RecordTypeId;
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch completed successfully.');
    }
}
