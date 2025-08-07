/**
 * Упрощенный обработчик для изменения статуса лидов на Final Denied
 * Работает синхронно в триггере без использования очередей и батчей
 */
public class LeadDeniedStatusHandler {
    
    /**
     * Обрабатывает лиды со статусом DENIED и проверяет условия для перевода в Final Denied
     * @param leads - список лидов для обработки
     * @return список лидов, которые нужно обновить
     */
    public static List<Lead> processLeads(List<Lead> leads) {
        List<Lead> leadsToUpdate = new List<Lead>();
        
        for (Lead lead : leads) {
            String newStatus = checkFieldValues(lead);
            
            if (String.isNotBlank(newStatus)) {
                lead.Status = newStatus;
                leadsToUpdate.add(lead);
                System.debug('Lead ' + lead.Id + ' will be updated to status: ' + newStatus);
            }
        }
        
        return leadsToUpdate;
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
    
    /**
     * Проверяет, должен ли лид быть переведен в статус Final Denied
     * @param lead - лид для проверки
     * @return true, если лид должен быть обновлен
     */
    public static Boolean shouldUpdateLead(Lead lead) {
        return String.isNotBlank(checkFieldValues(lead));
    }
    
    /**
     * Получает целевой статус для лида
     * @param lead - лид для проверки
     * @return целевой статус или пустая строка
     */
    public static String getTargetStatus(Lead lead) {
        return checkFieldValues(lead);
    }
}