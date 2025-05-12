global class LeadStatusBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(
            'SELECT Id, Status FROM Lead WHERE IsConverted = false'
        );
    }

    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        for (Lead l : scope) {
            if (l.Status == 'Closed Lost') {
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
