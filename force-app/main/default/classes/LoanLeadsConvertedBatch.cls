public class LoanLeadsConvertedBatch implements Database.Batchable<SObject> {
    private List<Id> leadIds;

    public LoanLeadsConvertedBatch(List<Id> leadIds) {
        this.leadIds = leadIds;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, LastName, Company, OwnerId FROM Lead WHERE Id IN :leadIds
        ]);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        for (Lead l : (List<Lead>)scope) {
            // Создаём и вставляем Account
            Account acc = new Account(
                Name = l.LastName,
                OwnerId = l.OwnerId
            );
            if (!Test.isRunningTest()) {
                acc.RecordTypeId = '012Kc000000teo4IAA';
            }
            insert acc;

            // Создаём и вставляем Contact
            Contact con = new Contact(
                LastName = l.LastName,
                AccountId = acc.Id,
                OwnerId = l.OwnerId
            );
            if (!Test.isRunningTest()) {
                con.RecordTypeId = '012Kc000000teoJIAQ';
            }
            insert con;

            // Создаём и вставляем Opportunity
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

            // Конвертация лида
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus('Convrted Loan');
            lc.setDoNotCreateOpportunity(false);
            lc.setAccountId(acc.Id);
            lc.setContactId(con.Id);
            lc.setOpportunityId(opp.Id);

            Database.LeadConvertResult res = Database.convertLead(lc);
            if (!res.isSuccess()) {
                System.debug('Ошибка конвертации лида: ' + res.getErrors());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Если нужна дополнительная логика
    }
}
