public class AccountTriggerHandler {
    private static final String TARGET_RECORD_TYPE_ID = '012Kc000000tenBIAQ';
    private static final Integer SYNC_THRESHOLD = 50;
    
    public static void handleDeactivation(List<Account> accounts) {
        for (Account l : accounts) {
            if (l.Client_Type__c == 'Closed Lost') {
                l.Active_status__c = false;
                    if (String.isBlank(l.Reason_for_closure__c)) {
                        l.Reason_for_closure__c.addError('Please provide a reason for closure.');
                    }
            } else {
                l.Active_status__c = true;
            }
        }
    }
    
    public static void handleAccountSync(List<Account> newAccounts) {
        // Фильтруем аккаунты с нужным RecordTypeId
        List<Id> accountIdsToSync = new List<Id>();
        
        for (Account acc : newAccounts) {
            if (acc.RecordTypeId == TARGET_RECORD_TYPE_ID) {
                accountIdsToSync.add(acc.Id);
            }
        }
        
        // Если нет аккаунтов для синхронизации, выходим
        if (accountIdsToSync.isEmpty()) {
            return;
        }
        
        // Если аккаунтов больше порогового значения, используем очередь
        if (accountIdsToSync.size() > SYNC_THRESHOLD) {
            System.enqueueJob(new AccountSyncQueueable(accountIdsToSync));
        } else {
            // Иначе синхронизируем сразу
            AccountSyncService.syncAccounts(accountIdsToSync);
        }
    }
}