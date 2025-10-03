trigger AutodialCampaignMembersFilterTrigger on Autodial_Campaign_Members_Filtres__c (after insert, after update, after delete) {
    
    if (Trigger.isAfter) {
        try {
            if (Trigger.isInsert || Trigger.isUpdate) {
                // Обрабатываем создание и обновление фильтров
                List<Autodial_Campaign_Members_Filtres__c> filtersToProcess = new List<Autodial_Campaign_Members_Filtres__c>();
                
                if (Trigger.isInsert) {
                    filtersToProcess.addAll(Trigger.new);
                } else if (Trigger.isUpdate) {
                    // Проверяем, изменились ли поля, влияющие на фильтрацию
                    for (Autodial_Campaign_Members_Filtres__c newFilter : Trigger.new) {
                        Autodial_Campaign_Members_Filtres__c oldFilter = Trigger.oldMap.get(newFilter.Id);
                        
                        Boolean fieldsChanged = 
                            newFilter.Object_type__c != oldFilter.Object_type__c ||
                            newFilter.Field__c != oldFilter.Field__c ||
                            newFilter.Operator__c != oldFilter.Operator__c ||
                            newFilter.Value__c != oldFilter.Value__c ||
                            newFilter.Autodial_Campaign__c != oldFilter.Autodial_Campaign__c;
                        
                        if (fieldsChanged) {
                            filtersToProcess.add(newFilter);
                        }
                    }
                }
                
                if (!filtersToProcess.isEmpty()) {
                    AutodialCampaignMembersFilterHandler.handleInsertUpdate(filtersToProcess);
                }
            }
            
            if (Trigger.isDelete) {
                // Обрабатываем удаление фильтров
                AutodialCampaignMembersFilterHandler.handleDelete(Trigger.old);
            }
            
        } catch (Exception e) {
            System.debug('Ошибка в AutodialCampaignMembersFilterTrigger: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
    }
}