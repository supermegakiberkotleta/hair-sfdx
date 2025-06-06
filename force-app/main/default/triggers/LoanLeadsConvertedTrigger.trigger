trigger LoanLeadsConvertedTrigger on Lead (after update) {
    List<Id> leadsToConvert = new List<Id>();

    for (Lead l : Trigger.new) {
        Lead old = Trigger.oldMap.get(l.Id);
        if (
            l.Status == 'Call after' &&
            old.Status != 'Call after' && // чтобы реагировать только на изменение
            l.RecordTypeId == '012Kc000000tenuIAA'
        ) {
            leadsToConvert.add(l.Id);
        }
    }

    if (!leadsToConvert.isEmpty()) {
        Database.executeBatch(new LoanLeadsConvertedBatch(leadsToConvert));
    }
}
