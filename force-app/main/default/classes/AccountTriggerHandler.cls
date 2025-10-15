public class AccountTriggerHandler {
    private static final String TARGET_RECORD_TYPE_ID = '012Kc000000tenBIAQ';
    private static final Integer SYNC_THRESHOLD = 50;
    
    public static void handleDeactivation(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }
        
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
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        
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
    
    /**
     * Handles after insert event for Marketing Report creation
     */
     public static void handleMarketingReportInsert(List<Lead> converted) {
        if (converted == null || converted.isEmpty()) {
            return;
        }
    
        // Собираем ID аккаунтов из лидов, которые действительно сконвертированы
        Set<Id> accountIds = new Set<Id>();
        for (Lead l : converted) {
            if (l.IsConverted && l.ConvertedAccountId != null) {
                accountIds.add(l.ConvertedAccountId);
            }
        }
        if (accountIds.isEmpty()) {
            return;
        }
    
        // Подтягиваем только нужные аккаунты сразу фильтром в SOQL
        List<Account> filteredAccounts = [
            SELECT Id, RecordTypeId
            FROM Account
            WHERE Id IN :accountIds
            AND RecordTypeId = :TARGET_RECORD_TYPE_ID
        ];
    
        if (!filteredAccounts.isEmpty()) {
            AccountMarketingReportHandler.handleAfterInsert(filteredAccounts);
        }
    }
    
    
    /**
     * Handles after update event for Marketing Report creation
     */
    public static void handleMarketingReportUpdate(List<Account> newAccounts, List<Account> oldAccounts) {
        if (newAccounts == null || newAccounts.isEmpty() || oldAccounts == null || oldAccounts.isEmpty()) {
            return;
        }
        
        List<Account> filteredAccounts = new List<Account>();
        for (Integer i = 0; i < newAccounts.size(); i++) {
            Account newAcc = newAccounts[i];
            Account oldAcc = oldAccounts[i];
            
            // Check if RecordTypeId was changed to target type
            if (newAcc.RecordTypeId == TARGET_RECORD_TYPE_ID && oldAcc.RecordTypeId != TARGET_RECORD_TYPE_ID) {
                filteredAccounts.add(newAcc);
            }
        }
        
        if (!filteredAccounts.isEmpty()) {
            AccountMarketingReportHandler.handleAfterInsert(filteredAccounts);
        }
    }
    
    /**
     * Handles before delete event for Marketing Report deletion
     */
    public static void handleMarketingReportDelete(List<Account> oldAccounts) {
        if (oldAccounts == null || oldAccounts.isEmpty()) {
            return;
        }
        
        try {
            List<Account> filteredAccounts = new List<Account>();
            for (Account acc : oldAccounts) {
                if (acc.RecordTypeId == TARGET_RECORD_TYPE_ID) {
                    filteredAccounts.add(acc);
                }
            }
            
            if (!filteredAccounts.isEmpty()) {
                AccountMarketingReportHandler.handleBeforeDelete(filteredAccounts);
            }
        } catch (Exception e) {
            // Логируем ошибку, но не прерываем процесс удаления
            System.debug('Error in handleMarketingReportDelete: ' + e.getMessage());
        }
    }
}