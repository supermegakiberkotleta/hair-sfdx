public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {
    private List<Id> accountIds;
    private static final Integer BATCH_SIZE = 50;
    
    /**
     * Конструктор
     * @param accountIds список ID аккаунтов для синхронизации
     */
    public AccountSyncQueueable(List<Id> accountIds) {
        this.accountIds = accountIds;
    }
    
    /**
     * Метод выполнения Queueable job
     */
    public void execute(QueueableContext context) {
        try {
            // Проверяем, есть ли аккаунты для обработки
            if (accountIds == null || accountIds.isEmpty()) {
                System.debug('No accounts to sync');
                return;
            }
            
            // Обрабатываем первую партию аккаунтов
            List<Id> currentBatch = new List<Id>();
            List<Id> remainingIds = new List<Id>();
            
            for (Integer i = 0; i < accountIds.size(); i++) {
                if (i < BATCH_SIZE) {
                    currentBatch.add(accountIds[i]);
                } else {
                    remainingIds.add(accountIds[i]);
                }
            }
            
            // Синхронизируем текущую партию
            if (!currentBatch.isEmpty()) {
                AccountSyncService.syncAccounts(currentBatch);
            }
            
            // Если есть еще аккаунты для обработки, создаем новую задачу в очереди
            if (!remainingIds.isEmpty() && !Test.isRunningTest()) {
                System.enqueueJob(new AccountSyncQueueable(remainingIds));
            }
            
        } catch (Exception e) {
            System.debug('Error in AccountSyncQueueable: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
}

