public class LeadDeniedStatusFuture {
    
    /**
     * Future метод для обработки лидов со статусом DENIED
     * Используется как fallback когда лимиты Queueable исчерпаны
     * @param leadIds - список ID лидов для обработки
     */
    @future
    public static void processLeadsFuture(Set<Id> leadIds) {
        try {
            System.debug('LeadDeniedStatusFuture: Processing ' + leadIds.size() + ' leads');
            
            // Запрашиваем лиды из базы данных
            List<Lead> leadsToProcess = [
                SELECT Id, Status, Parsing_Status__c, Company, Industry__c
                FROM Lead 
                WHERE Id IN :leadIds
            ];
            
            List<Lead> leadsToUpdate = new List<Lead>();
            
            for (Lead lead : leadsToProcess) {
                String newStatus = checkFieldValues(lead);
                
                if (String.isNotBlank(newStatus)) {
                    lead.Status = newStatus;
                    leadsToUpdate.add(lead);
                    System.debug('Lead ' + lead.Id + ' will be updated to status: ' + newStatus);
                }
            }
            
            if (!leadsToUpdate.isEmpty()) {
                // Теперь триггер не должен срабатывать в Future контексте
                update leadsToUpdate;
                System.debug('Successfully updated ' + leadsToUpdate.size() + ' leads to Final Denied status via Future');
            }
            
        } catch (Exception e) {
            System.debug('Error in LeadDeniedStatusFuture: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
    
    /**
     * Проверяет значения полей лида согласно конфигурации
     * @param lead - лид для проверки
     * @return новый статус или пустая строка, если изменения не требуются
     */
    private static String checkFieldValues(Lead lead) {
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
}