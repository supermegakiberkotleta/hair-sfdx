public class LeadDeniedStatusBatch implements Database.Batchable<Lead>, Database.Stateful {
    
    // Статический флаг для предотвращения одновременного запуска
    private static Boolean isBatchRunning = false;
    
    private List<Lead> leadsToProcess;
    private Integer totalProcessed = 0;
    private Integer totalUpdated = 0;
    
    public LeadDeniedStatusBatch(List<Lead> leads) {
        this.leadsToProcess = leads;
    }
    
    /**
     * Start метод - возвращает итератор для обработки лидов
     */
    public Iterable<Lead> start(Database.BatchableContext context) {
        System.debug('LeadDeniedStatusBatch: Starting batch with ' + leadsToProcess.size() + ' leads');
        return leadsToProcess;
    }
    
    /**
     * Execute метод - обрабатывает каждый лид
     */
    public void execute(Database.BatchableContext context, List<Lead> scope) {
        System.debug('LeadDeniedStatusBatch: Processing batch of ' + scope.size() + ' leads');
        
        // Собираем ID лидов для обновления
        Set<Id> leadIdsToUpdate = new Set<Id>();
        
        for (Lead lead : scope) {
            totalProcessed++;
            
            String newStatus = checkFieldValues(lead);
            
            if (String.isNotBlank(newStatus)) {
                leadIdsToUpdate.add(lead.Id);
                System.debug('Lead ' + lead.Id + ' will be updated to status: ' + newStatus);
            }
        }
        
        if (!leadIdsToUpdate.isEmpty()) {
            try {
                // Заново запрашиваем записи из базы данных для обновления
                List<Lead> leadsToUpdate = [
                    SELECT Id, Status, Parsing_Status__c, Company, Industry__c
                    FROM Lead 
                    WHERE Id IN :leadIdsToUpdate
                ];
                
                for (Lead lead : leadsToUpdate) {
                    lead.Status = 'Final Denied';
                }
                
                update leadsToUpdate;
                totalUpdated += leadsToUpdate.size();
                System.debug('Successfully updated ' + leadsToUpdate.size() + ' leads to Final Denied status in batch');
            } catch (Exception e) {
                System.debug('Error updating leads in batch: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
            }
        }
    }
    
    /**
     * Finish метод - вызывается после завершения всех batch'ей
     */
    public void finish(Database.BatchableContext context) {
        System.debug('LeadDeniedStatusBatch: Completed. Total processed: ' + totalProcessed + ', Total updated: ' + totalUpdated);
        
        // Сбрасываем флаг после завершения
        isBatchRunning = false;
        
        // Можно добавить отправку уведомлений или логирование результатов
        if (totalUpdated > 0) {
            System.debug('Batch successfully updated ' + totalUpdated + ' leads to Final Denied status');
        }
    }
    
    /**
     * Проверяет значения полей лида согласно конфигурации
     * @param lead - лид для проверки
     * @return новый статус или пустая строка, если изменения не требуются
     */
    private String checkFieldValues(Lead lead) {
        Map<String, List<String>> config = LeadDeniedStatusConfig.getFieldValuesConfig();
        
        for (String fieldName : config.keySet()) {
            // Получаем значение поля динамически
            Object fieldValue = lead.get(fieldName);
            
            if (fieldValue != null) {
                String stringValue = String.valueOf(fieldValue);
                String targetStatus = LeadDeniedStatusConfig.getTargetStatus(fieldName, stringValue);
                
                if (String.isNotBlank(targetStatus)) {
                    return targetStatus;
                }
            }
        }
        
        return ''; // Нет изменений
    }
    
    /**
     * Статический метод для запуска batch с проверкой на одновременный запуск
     */
    public static void startBatch(List<Lead> leads) {
        if (leads != null && !leads.isEmpty()) {
            // Проверяем, не запущен ли уже batch
            if (!isBatchRunning) {
                isBatchRunning = true;
                LeadDeniedStatusBatch batch = new LeadDeniedStatusBatch(leads);
                Database.executeBatch(batch, 200); // Размер batch = 200 записей
                System.debug('LeadDeniedStatusBatch: Started successfully');
            } else {
                System.debug('LeadDeniedStatusBatch: Already running, skipping this execution');
            }
        }
    }
    
    /**
     * Метод для сброса флага (для тестирования)
     */
    public static void resetBatchFlag() {
        isBatchRunning = false;
    }
}