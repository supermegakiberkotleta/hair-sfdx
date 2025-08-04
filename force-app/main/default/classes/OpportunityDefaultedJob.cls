public class OpportunityDefaultedJob {
    public static void run() {
        Date today = Date.today();
        List<Opportunity> toUpdate = new List<Opportunity>();

        List<Opportunity> opps = [
            SELECT Id, CreatedDate
            FROM Opportunity
            WHERE RecordTypeId = '012Kc000000tenzIAA'
            AND Defaulted__c = false
        ];

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        for (Opportunity o : opps) {
            oppMap.put(o.Id, o);
        }

        List<OpportunityHistory> histories = [
            SELECT OpportunityId, StageName, CreatedDate
            FROM OpportunityHistory
            WHERE OpportunityId IN :oppMap.keySet()
        ];

        Set<Id> oppsToFlag = new Set<Id>();
        for (OpportunityHistory h : histories) {
            Opportunity opp = oppMap.get(h.OpportunityId);
            if (
                h.CreatedDate.date() <= opp.CreatedDate.addDays(30) &&
                (
                    h.StageName == '10-15 days' ||
                    h.StageName == '15-30 days' ||
                    h.StageName == 'Collectors' ||
                    h.StageName == 'Lawyers'
                )
            ) {
                oppsToFlag.add(h.OpportunityId);
            }
        }

        for (Id oppId : oppsToFlag) {
            Opportunity o = oppMap.get(oppId);
            o.Defaulted__c = true;
            toUpdate.add(o);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}