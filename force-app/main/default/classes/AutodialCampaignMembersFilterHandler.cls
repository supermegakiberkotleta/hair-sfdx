public class AutodialCampaignMembersFilterHandler {
    
    /**
     * Обрабатывает создание и обновление фильтров
     * Находит записи, соответствующие фильтру, и добавляет их в Autodial_CampaignMembers__c
     */
    public static void handleInsertUpdate(List<Autodial_Campaign_Members_Filtres__c> filters) {
        if (filters == null || filters.isEmpty()) {
            return;
        }
        
        // Группируем фильтры по кампании
        Map<Id, List<Autodial_Campaign_Members_Filtres__c>> filtersByCampaign = new Map<Id, List<Autodial_Campaign_Members_Filtres__c>>();
        
        for (Autodial_Campaign_Members_Filtres__c filter : filters) {
            if (filter.Autodial_Campaign__c != null) {
                if (!filtersByCampaign.containsKey(filter.Autodial_Campaign__c)) {
                    filtersByCampaign.put(filter.Autodial_Campaign__c, new List<Autodial_Campaign_Members_Filtres__c>());
                }
                filtersByCampaign.get(filter.Autodial_Campaign__c).add(filter);
            }
        }
        
        // Обрабатываем каждую кампанию
        for (Id campaignId : filtersByCampaign.keySet()) {
            List<Autodial_Campaign_Members_Filtres__c> campaignFilters = filtersByCampaign.get(campaignId);
            processCampaignFilters(campaignId, campaignFilters);
        }
    }
    
    /**
     * Обрабатывает удаление фильтров
     * Удаляет соответствующие записи из Autodial_CampaignMembers__c с Added_type__c = 'auto'
     */
    public static void handleDelete(List<Autodial_Campaign_Members_Filtres__c> deletedFilters) {
        if (deletedFilters == null || deletedFilters.isEmpty()) {
            return;
        }
        
        // Группируем удаленные фильтры по кампании
        Map<Id, List<Autodial_Campaign_Members_Filtres__c>> filtersByCampaign = new Map<Id, List<Autodial_Campaign_Members_Filtres__c>>();
        
        for (Autodial_Campaign_Members_Filtres__c filter : deletedFilters) {
            if (filter.Autodial_Campaign__c != null) {
                if (!filtersByCampaign.containsKey(filter.Autodial_Campaign__c)) {
                    filtersByCampaign.put(filter.Autodial_Campaign__c, new List<Autodial_Campaign_Members_Filtres__c>());
                }
                filtersByCampaign.get(filter.Autodial_Campaign__c).add(filter);
            }
        }
        
        // Удаляем записи для каждой кампании
        for (Id campaignId : filtersByCampaign.keySet()) {
            List<Autodial_Campaign_Members_Filtres__c> campaignFilters = filtersByCampaign.get(campaignId);
            deleteCampaignMembersByFilters(campaignId, campaignFilters);
        }
    }
    
    /**
     * Обрабатывает фильтры для конкретной кампании
     */
    private static void processCampaignFilters(Id campaignId, List<Autodial_Campaign_Members_Filtres__c> filters) {
        // Группируем фильтры по типу объекта
        Map<String, List<Autodial_Campaign_Members_Filtres__c>> filtersByObjectType = new Map<String, List<Autodial_Campaign_Members_Filtres__c>>();
        
        for (Autodial_Campaign_Members_Filtres__c filter : filters) {
            if (String.isNotBlank(filter.Object_type__c)) {
                if (!filtersByObjectType.containsKey(filter.Object_type__c)) {
                    filtersByObjectType.put(filter.Object_type__c, new List<Autodial_Campaign_Members_Filtres__c>());
                }
                filtersByObjectType.get(filter.Object_type__c).add(filter);
            }
        }
        
        // Обрабатываем каждый тип объекта
        for (String objectType : filtersByObjectType.keySet()) {
            List<Autodial_Campaign_Members_Filtres__c> objectFilters = filtersByObjectType.get(objectType);
            processObjectTypeFilters(campaignId, objectType, objectFilters);
        }
    }
    
    /**
     * Обрабатывает фильтры для конкретного типа объекта
     */
    private static void processObjectTypeFilters(Id campaignId, String objectType, List<Autodial_Campaign_Members_Filtres__c> filters) {
        try {
            // Строим SOQL запрос
            String soqlQuery = buildSoqlQuery(objectType, filters);
            if (String.isBlank(soqlQuery)) {
                return;
            }
            
            // Выполняем запрос
            List<SObject> matchingRecords = Database.query(soqlQuery);
            
            // Получаем существующие записи кампании
            Set<Id> existingMemberIds = getExistingMemberIds(campaignId, objectType);
            
            // Создаем новые записи членов кампании
            List<SObject> membersToInsert = new List<SObject>();
            Schema.SObjectType memberType = Schema.getGlobalDescribe().get('Autodial_CampaignMembers__c');
            Map<String, Schema.SObjectField> memberFields = memberType.getDescribe().fields.getMap();
            
            Schema.SObjectField campaignField = memberFields.get('Autodial_Campaign__c');
            Schema.SObjectField addedTypeField = memberFields.get('Added_type__c');
            Schema.SObjectField recordTypeField = memberFields.get('Record_Type__c');
            Schema.SObjectField phoneField = memberFields.get('Phone__c');
            Schema.SObjectField nameField = memberFields.get('Name');
            Schema.SObjectField recordField = memberFields.get('Record__c');
            
            String objectFieldName = getObjectFieldName(objectType);
            Schema.SObjectField objectField = memberFields.get(objectFieldName);
            
            for (SObject record : matchingRecords) {
                Id recordId = (Id)record.get('Id');
                if (!existingMemberIds.contains(recordId)) {
                    SObject member = memberType.newSObject();
                    
                    // Основные поля
                    member.put(campaignField, campaignId);
                    member.put(objectField, recordId);
                    member.put(addedTypeField, 'auto');
                    member.put(recordTypeField, objectType);
                    
                    // Заполняем поля в зависимости от типа объекта
                    fillMemberFields(member, record, objectType, memberFields, recordId);
                    
                    membersToInsert.add(member);
                }
            }
            
            // Вставляем новые записи
            if (!membersToInsert.isEmpty()) {
                insert membersToInsert;
                System.debug('Создано ' + membersToInsert.size() + ' записей членов кампании для типа объекта ' + objectType);
            }
            
        } catch (Exception e) {
            System.debug('Ошибка при обработке фильтров для типа объекта ' + objectType + ': ' + e.getMessage());
        }
    }
    
    /**
     * Удаляет записи членов кампании по фильтрам
     */
    private static void deleteCampaignMembersByFilters(Id campaignId, List<Autodial_Campaign_Members_Filtres__c> filters) {
        try {
            // Группируем фильтры по типу объекта
            Map<String, List<Autodial_Campaign_Members_Filtres__c>> filtersByObjectType = new Map<String, List<Autodial_Campaign_Members_Filtres__c>>();
            
            for (Autodial_Campaign_Members_Filtres__c filter : filters) {
                if (String.isNotBlank(filter.Object_type__c)) {
                    if (!filtersByObjectType.containsKey(filter.Object_type__c)) {
                        filtersByObjectType.put(filter.Object_type__c, new List<Autodial_Campaign_Members_Filtres__c>());
                    }
                    filtersByObjectType.get(filter.Object_type__c).add(filter);
                }
            }
            
            // Для каждого типа объекта находим и удаляем соответствующие записи
            for (String objectType : filtersByObjectType.keySet()) {
                List<Autodial_Campaign_Members_Filtres__c> objectFilters = filtersByObjectType.get(objectType);
                deleteObjectTypeMembersByFilters(campaignId, objectType, objectFilters);
            }
            
        } catch (Exception e) {
            System.debug('Ошибка при удалении записей членов кампании: ' + e.getMessage());
        }
    }
    
    /**
     * Удаляет записи членов кампании для конкретного типа объекта
     */
    private static void deleteObjectTypeMembersByFilters(Id campaignId, String objectType, List<Autodial_Campaign_Members_Filtres__c> filters) {
        try {
            // Строим SOQL запрос для поиска записей
            String soqlQuery = buildSoqlQuery(objectType, filters);
            if (String.isBlank(soqlQuery)) {
                return;
            }
            
            // Выполняем запрос
            List<SObject> matchingRecords = Database.query(soqlQuery);
            
            if (matchingRecords.isEmpty()) {
                return;
            }
            
            // Собираем ID записей
            Set<Id> recordIds = new Set<Id>();
            for (SObject record : matchingRecords) {
                recordIds.add((Id)record.get('Id'));
            }
            
            // Находим записи членов кампании для удаления
            String objectFieldName = getObjectFieldName(objectType);
            String deleteQuery = 'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND ' + 
                               objectFieldName + ' IN :recordIds AND Added_type__c = \'auto\'';
            
            List<SObject> membersToDelete = Database.query(deleteQuery);
            
            // Удаляем записи
            if (!membersToDelete.isEmpty()) {
                delete membersToDelete;
                System.debug('Удалено ' + membersToDelete.size() + ' записей членов кампании для типа объекта ' + objectType);
            }
            
        } catch (Exception e) {
            System.debug('Ошибка при удалении записей членов кампании для типа объекта ' + objectType + ': ' + e.getMessage());
        }
    }
    
    /**
     * Строит SOQL запрос на основе фильтров
     */
    private static String buildSoqlQuery(String objectType, List<Autodial_Campaign_Members_Filtres__c> filters) {
        if (filters == null || filters.isEmpty()) {
            return null;
        }
        
        // Определяем базовые поля для SELECT
        String baseFields = 'Id';
        if (objectType == 'Lead') {
            baseFields += ', LastName, Phone, Company, Status';
        } else if (objectType == 'Contact') {
            baseFields += ', LastName, Phone, Email';
        } else if (objectType == 'Account') {
            baseFields += ', Name, Phone, Type, Industry';
        }
        
        String soql = 'SELECT ' + baseFields + ' FROM ' + objectType + ' WHERE ';
        
        List<String> conditions = new List<String>();
        
        for (Autodial_Campaign_Members_Filtres__c filter : filters) {
            if (String.isNotBlank(filter.Field__c) && String.isNotBlank(filter.Operator__c)) {
                String condition = buildCondition(filter);
                if (String.isNotBlank(condition)) {
                    conditions.add(condition);
                }
            }
        }
        
        if (conditions.isEmpty()) {
            return null;
        }
        
        soql += String.join(conditions, ' AND ');
        soql += ' LIMIT 1000'; // Ограничиваем количество записей
        
        return soql;
    }
    
    /**
     * Строит условие WHERE для одного фильтра
     */
    private static String buildCondition(Autodial_Campaign_Members_Filtres__c filter) {
        String fieldName = filter.Field__c;
        String operator = filter.Operator__c;
        String value = filter.Value__c;
        
        // Проверяем валидность оператора
        Set<String> validOperators = new Set<String>{
            'equals', 'not equal to', 'less than', 'greater than', 
            'less or equal', 'greater or equal', 'contains', 
            'does not contain', 'is null'
        };
        
        if (!validOperators.contains(operator)) {
            System.debug('Неверный оператор: ' + operator);
            return null;
        }
        
        String condition = '';
        
        switch on operator {
            when 'equals' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' = \'' + String.escapeSingleQuotes(value) + '\'';
                }
            }
            when 'not equal to' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' != \'' + String.escapeSingleQuotes(value) + '\'';
                }
            }
            when 'less than' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' < \'' + String.escapeSingleQuotes(value) + '\'';
                }
            }
            when 'greater than' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' > \'' + String.escapeSingleQuotes(value) + '\'';
                }
            }
            when 'less or equal' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' <= \'' + String.escapeSingleQuotes(value) + '\'';
                }
            }
            when 'greater or equal' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' >= \'' + String.escapeSingleQuotes(value) + '\'';
                }
            }
            when 'contains' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' LIKE \'%' + String.escapeSingleQuotes(value) + '%\'';
                }
            }
            when 'does not contain' {
                if (String.isNotBlank(value)) {
                    condition = fieldName + ' NOT LIKE \'%' + String.escapeSingleQuotes(value) + '%\'';
                }
            }
            when 'is null' {
                condition = fieldName + ' = null';
            }
        }
        
        return condition;
    }
    
    /**
     * Получает ID существующих записей членов кампании
     */
    private static Set<Id> getExistingMemberIds(Id campaignId, String objectType) {
        Set<Id> existingIds = new Set<Id>();
        
        try {
            String objectFieldName = getObjectFieldName(objectType);
            String query = 'SELECT ' + objectFieldName + ' FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId';
            
            List<SObject> existingMembers = Database.query(query);
            for (SObject member : existingMembers) {
                Id recordId = (Id)member.get(objectFieldName);
                if (recordId != null) {
                    existingIds.add(recordId);
                }
            }
        } catch (Exception e) {
            System.debug('Ошибка при получении существующих записей членов кампании: ' + e.getMessage());
        }
        
        return existingIds;
    }
    
    /**
     * Возвращает имя поля для типа объекта
     */
    private static String getObjectFieldName(String objectType) {
        switch on objectType {
            when 'Lead' {
                return 'Lead__c';
            }
            when 'Contact' {
                return 'Contact__c';
            }
            when 'Account' {
                return 'Account__c';
            }
        }
        return null;
    }
    
    /**
     * Заполняет дополнительные поля записи члена кампании
     */
    private static void fillMemberFields(SObject member, SObject record, String objectType, Map<String, Schema.SObjectField> memberFields, Id recordId) {
        try {
            // Заполняем поле Name
            String nameValue = getNameFromRecord(record, objectType);
            if (String.isNotBlank(nameValue)) {
                Schema.SObjectField nameField = memberFields.get('Name');
                if (nameField != null) {
                    member.put(nameField, nameValue);
                }
            }
            
            // Заполняем поле Phone__c
            String phoneValue = getPhoneFromRecord(record, objectType);
            if (String.isNotBlank(phoneValue)) {
                Schema.SObjectField phoneField = memberFields.get('Phone__c');
                if (phoneField != null) {
                    member.put(phoneField, phoneValue);
                }
            }
            
            // Заполняем поле Record__c (ссылка на объект)
            String recordUrl = buildRecordUrl(recordId, objectType);
            if (String.isNotBlank(recordUrl)) {
                Schema.SObjectField recordField = memberFields.get('Record__c');
                if (recordField != null) {
                    member.put(recordField, recordUrl);
                }
            }
            
        } catch (Exception e) {
            System.debug('Ошибка при заполнении дополнительных полей: ' + e.getMessage());
        }
    }
    
    /**
     * Получает имя из записи в зависимости от типа объекта
     */
    private static String getNameFromRecord(SObject record, String objectType) {
        try {
            switch on objectType {
                when 'Lead' {
                    String lastName = (String)record.get('LastName');
                    return String.isNotBlank(lastName) ? lastName : null;
                }
                when 'Contact' {
                    String lastName = (String)record.get('LastName');
                    return String.isNotBlank(lastName) ? lastName : null;
                }
                when 'Account' {
                    String name = (String)record.get('Name');
                    return String.isNotBlank(name) ? name : null;
                }
            }
        } catch (Exception e) {
            System.debug('Ошибка при получении имени из записи: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * Получает телефон из записи в зависимости от типа объекта
     */
    private static String getPhoneFromRecord(SObject record, String objectType) {
        try {
            switch on objectType {
                when 'Lead' {
                    String phone = (String)record.get('Phone');
                    return String.isNotBlank(phone) ? phone : null;
                }
                when 'Contact' {
                    String phone = (String)record.get('Phone');
                    return String.isNotBlank(phone) ? phone : null;
                }
                when 'Account' {
                    String phone = (String)record.get('Phone');
                    return String.isNotBlank(phone) ? phone : null;
                }
            }
        } catch (Exception e) {
            System.debug('Ошибка при получении телефона из записи: ' + e.getMessage());
        }
        return null;
    }
    
    /**
     * Строит URL для записи объекта
     */
    private static String buildRecordUrl(Id recordId, String objectType) {
        try {
            String objectApiName = objectType.toLowerCase();
            
            // Захардкоженный URL в формате Lightning
            return 'https://dream-velocity-3162.lightning.force.com/lightning/r/' + objectApiName + '/' + recordId + '/view';
            
        } catch (Exception e) {
            System.debug('Ошибка при построении URL записи: ' + e.getMessage());
            return null;
        }
    }
}