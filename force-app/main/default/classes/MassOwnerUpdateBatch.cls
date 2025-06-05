global class MassOwnerUpdateBatch implements Database.Batchable<SObject> {

    Set<Id> oldOwnerIds = new Set<Id>{
        '005Kc000001S2WBIA0',
        '005Kc000001SozYIAS',
        '005Kc000001SrEkIAK' // Добавлен
    };

    Id targetRecordTypeId = '012Kc000000tenBIAQ';

    List<Id> newOwnerIds = new List<Id>{
        '005Kc000001SjYMIA0',
        '005Kc000001SqnjIAC',
        '005Kc000001SrEaIAK',
        '005Kc000001SrEfIAK'
    };

    Integer ownerCounter = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id FROM Account
            WHERE OwnerId IN :oldOwnerIds AND RecordTypeId = :targetRecordTypeId
        ]);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Account> accountsToUpdate = (List<Account>) scope;
        List<Id> accountIds = new List<Id>();

        for (Account acc : accountsToUpdate) {
            acc.OwnerId = getNextOwnerId();
            accountIds.add(acc.Id);
        }

        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : [
            SELECT Id FROM Contact WHERE AccountId IN :accountIds
        ]) {
            c.OwnerId = getNextOwnerId();
            contactsToUpdate.add(c);
        }

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Opportunity o : [
            SELECT Id FROM Opportunity WHERE AccountId IN :accountIds
        ]) {
            o.OwnerId = getNextOwnerId();
            opportunitiesToUpdate.add(o);
        }

        if (!accountsToUpdate.isEmpty()) update accountsToUpdate;
        if (!contactsToUpdate.isEmpty()) update contactsToUpdate;
        if (!opportunitiesToUpdate.isEmpty()) update opportunitiesToUpdate;
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('MassOwnerUpdateBatch finished');
    }

    private Id getNextOwnerId() {
        Integer index = Math.mod(ownerCounter, newOwnerIds.size());
        ownerCounter++;
        return newOwnerIds[index];
    }
}