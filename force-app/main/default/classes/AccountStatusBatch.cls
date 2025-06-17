global class AccountStatusBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id, Client_Type__c FROM Account'
        );
    }

    global void execute(Database.BatchableContext BC, List<Account> scope) {
        for (Account l : scope) {
            if (l.Client_Type__c == 'Closed Lost') {
                l.Active_status__c = false;
                l.Reason_for_closure__c = 'Undefined reason';
            } else {
                l.Active_status__c = true;
            }
        }
        update scope;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('Batch processing finished.');
    }
}