public class LoanLeadsConvertedBatch implements Database.Batchable<SObject> {
    private List<Id> leadIds;

    public LoanLeadsConvertedBatch(List<Id> leadIds) {
        this.leadIds = leadIds;
        System.debug('Batch initialized with lead IDs: ' + leadIds);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Start method called');
        return Database.getQueryLocator([
            SELECT Id, LastName, Company, OwnerId FROM Lead WHERE Id IN :leadIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('Execute method called with scope size: ' + scope.size());
        for (Lead l : (List<Lead>)scope) {
            System.debug('Processing Lead: ' + l.Id);

            // Create and insert Account
            Account acc = new Account(
                Name = l.LastName,
                OwnerId = l.OwnerId
            );
            if (!Test.isRunningTest()) {
                acc.RecordTypeId = '012Kc000000teo4IAA';
            }
            insert acc;
            System.debug('Inserted Account with Id: ' + acc.Id);

            // Create and insert Contact
            Contact con = new Contact(
                LastName = l.LastName,
                AccountId = acc.Id,
                OwnerId = l.OwnerId
            );
            if (!Test.isRunningTest()) {
                con.RecordTypeId = '012Kc000000teoJIAQ';
            }
            insert con;
            System.debug('Inserted Contact with Id: ' + con.Id);

            // Create and insert Opportunity
            Opportunity opp = new Opportunity(
                Name = l.LastName,
                StageName = '0 days',
                CloseDate = Date.today().addDays(365),
                AccountId = acc.Id,
                OwnerId = l.OwnerId
            );
            if (!Test.isRunningTest()) {
                opp.RecordTypeId = '012Kc000000tenzIAA';
            }
            insert opp;
            System.debug('Inserted Opportunity with Id: ' + opp.Id);

            // Lead conversion
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus('Convrted Loan');
            lc.setDoNotCreateOpportunity(false);
            lc.setAccountId(acc.Id);
            lc.setContactId(con.Id);
            lc.setOpportunityId(opp.Id);

            Database.LeadConvertResult res = Database.convertLead(lc);
            if (!res.isSuccess()) {
                System.debug('Lead conversion failed for Lead Id: ' + l.Id + ', Errors: ' + res.getErrors());
            } else {
                System.debug('Lead successfully converted: ' + l.Id);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Finish method called');
    }
}
