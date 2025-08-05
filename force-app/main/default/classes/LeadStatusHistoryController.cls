public with sharing class LeadStatusHistoryController {
    
    /**
     * Получает предыдущий статус лида из стандартной истории Salesforce
     * @param leadId ID лида
     * @return String предыдущий статус или null, если история пуста
     */
    @AuraEnabled(cacheable=true)
    public static String getPreviousStatus(Id leadId) {
        try {
            // Получаем текущий статус лида
            Lead currentLead = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];
            String currentStatus = currentLead.Status;
            
            // Получаем историю изменений поля Status из стандартной истории Salesforce
            List<LeadHistory> history = [
                SELECT OldValue, NewValue, CreatedDate
                FROM LeadHistory
                WHERE LeadId = :leadId
                AND Field = 'Status'
                ORDER BY CreatedDate DESC
            ];
            
            // Ищем предыдущий статус, исключая текущий
            for (LeadHistory record : history) {
                String newValue = String.valueOf(record.NewValue);
                String oldValue = String.valueOf(record.OldValue);
                
                // Если NewValue не равен текущему статусу и не null, возвращаем его
                if (newValue != currentStatus && newValue != 'null' && String.isNotBlank(newValue)) {
                    return newValue;
                }
                
                // Если OldValue не равен текущему статусу и не null, возвращаем его
                if (oldValue != currentStatus && oldValue != 'null' && String.isNotBlank(oldValue)) {
                    return oldValue;
                }
            }
            
            return null;
            
        } catch (Exception e) {
            System.debug('Error getting previous status: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Получает полную историю статусов лида из стандартной истории Salesforce
     * @param leadId ID лида
     * @return List<String> список статусов в хронологическом порядке
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getStatusHistory(Id leadId) {
        try {
            List<String> statusHistory = new List<String>();
            
            // Получаем историю изменений поля Status
            List<LeadHistory> history = [
                SELECT OldValue, NewValue, CreatedDate
                FROM LeadHistory
                WHERE LeadId = :leadId
                AND Field = 'Status'
                ORDER BY CreatedDate ASC
            ];
            
            // Собираем все уникальные статусы
            Set<String> uniqueStatuses = new Set<String>();
            
            for (LeadHistory record : history) {
                String newValue = String.valueOf(record.NewValue);
                String oldValue = String.valueOf(record.OldValue);
                
                if (String.isNotBlank(newValue) && newValue != 'null') {
                    uniqueStatuses.add(newValue);
                }
                
                if (String.isNotBlank(oldValue) && oldValue != 'null') {
                    uniqueStatuses.add(oldValue);
                }
            }
            
            // Добавляем текущий статус лида
            Lead currentLead = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];
            if (String.isNotBlank(currentLead.Status)) {
                uniqueStatuses.add(currentLead.Status);
            }
            
            // Преобразуем в список и сортируем
            statusHistory.addAll(uniqueStatuses);
            statusHistory.sort();
            
            return statusHistory;
            
        } catch (Exception e) {
            System.debug('Error getting status history: ' + e.getMessage());
            return new List<String>();
        }
    }
    
    /**
     * Получает детальную историю изменений статуса с датами
     * @param leadId ID лида
     * @return List<Map<String, Object>> список изменений с датами
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getDetailedStatusHistory(Id leadId) {
        try {
            List<Map<String, Object>> detailedHistory = new List<Map<String, Object>>();
            
            // Получаем историю изменений поля Status
            List<LeadHistory> history = [
                SELECT OldValue, NewValue, CreatedDate
                FROM LeadHistory
                WHERE LeadId = :leadId
                AND Field = 'Status'
                ORDER BY CreatedDate ASC
            ];
            
            for (LeadHistory record : history) {
                String newValue = String.valueOf(record.NewValue);
                String oldValue = String.valueOf(record.OldValue);
                
                if (String.isNotBlank(newValue) && newValue != 'null') {
                    Map<String, Object> change = new Map<String, Object>();
                    change.put('status', newValue);
                    change.put('date', record.CreatedDate);
                    change.put('type', 'New Value');
                    detailedHistory.add(change);
                }
            }
            
            return detailedHistory;
            
        } catch (Exception e) {
            System.debug('Error getting detailed status history: ' + e.getMessage());
            return new List<Map<String, Object>>();
        }
    }
}