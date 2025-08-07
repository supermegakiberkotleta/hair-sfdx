public class LeadDeniedStatusQueueable implements Queueable {
    
    private List<Lead> leadsToProcess;
    
    public LeadDeniedStatusQueueable(List<Lead> leads) {
        this.leadsToProcess = leads;
    }
    
    public void execute(QueueableContext context) {
        try {
            processLeads();
        } catch (Exception e) {
            System.debug('Error in LeadDeniedStatusQueueable: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    private void processLeads() {
        // Собираем ID лидов для обновления
        Set<Id> leadIdsToUpdate = new Set<Id>();
        
        for (Lead lead : leadsToProcess) {
            String newStatus = checkFieldValues(lead);
            
            if (String.isNotBlank(newStatus)) {
                leadIdsToUpdate.add(lead.Id);
                System.debug('Lead ' + lead.Id + ' will be updated to status: ' + newStatus);
            }
        }
        
        if (!leadIdsToUpdate.isEmpty()) {
            try {
                // Заново запрашиваем записи из базы данных для обновления
                List<Lead> leadsToUpdate = [SELECT Id, Status FROM Lead WHERE Id IN :leadIdsToUpdate];
                
                for (Lead lead : leadsToUpdate) {
                    lead.Status = 'Final Denied';
                }
                
                update leadsToUpdate;
                System.debug('Successfully updated ' + leadsToUpdate.size() + ' leads to Final Denied status');
            } catch (Exception e) {
                System.debug('Error updating leads: ' + e.getMessage());
                System.debug('Stack trace: ' + e.getStackTraceString());
                // Можно добавить логирование ошибок в отдельную таблицу
            }
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
     * Метод для получения текущей конфигурации (для отладки)
     */
    public static Map<String, List<String>> getCurrentConfig() {
        return LeadDeniedStatusConfig.getFieldValuesConfig();
    }
}