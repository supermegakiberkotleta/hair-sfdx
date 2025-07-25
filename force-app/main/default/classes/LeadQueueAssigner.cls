public class LeadQueueAssigner {

    private static final String TARGET_RECORD_TYPE_ID = '012Kc000000ten6IAA';
    private static final String SPECIAL_USER_ID = '005Kc000001SqnjIAC';

    public static void assignOwners(List<Lead> newLeads) {
        List<Lead> filteredLeads = new List<Lead>();

        for (Lead l : newLeads) {
            if (l.RecordTypeId == TARGET_RECORD_TYPE_ID && l.Participates_in_the_queue__c == true) {
                filteredLeads.add(l);
            }
        }

        if (filteredLeads.isEmpty()) {
            return;
        }

        // Получить пользователей в очереди
        List<User> queueUsers = [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Hair'
              AND Participates_in_the_queue__c = true AND IsActive = true
            ORDER BY CreatedDate ASC, Id ASC
        ];

        if (queueUsers.isEmpty()) {
            return;
        }

        List<Id> queueUserIds = new List<Id>();
        for (User u : queueUsers) {
            queueUserIds.add(u.Id);
        }

        // Получить два последних созданных лида с нужным RecordTypeId
        List<Lead> lastLeads = [
            SELECT OwnerId
            FROM Lead
            WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID
              AND OwnerId IN :queueUserIds
            ORDER BY CreatedDate DESC
            LIMIT 2
        ];

        Id currentOwnerId = null;
        Integer consecutiveCount = 0;

        if (!lastLeads.isEmpty()) {
            currentOwnerId = lastLeads[0].OwnerId;
            
            // Подсчитываем количество подряд лидов у текущего владельца
            for (Lead l : lastLeads) {
                if (l.OwnerId == currentOwnerId) {
                    consecutiveCount++;
                } else {
                    break;
                }
            }
        }

        // Определяем начальный индекс для назначения
        Integer startIndex = 0;
        if (currentOwnerId != null) {
            Integer idx = queueUserIds.indexOf(currentOwnerId);
            if (idx != -1) {
                // Если текущий пользователь - специальный и у него меньше 2 лидов подряд
                if (currentOwnerId == SPECIAL_USER_ID && consecutiveCount < 2) {
                    startIndex = idx; // Продолжаем с того же пользователя
                } else {
                    // Переходим к следующему пользователю
                    startIndex = Math.mod(idx + 1, queueUserIds.size());
                }
            }
        }

        // Назначаем OwnerId по очереди
        Integer totalUsers = queueUserIds.size();
        for (Integer i = 0; i < filteredLeads.size(); i++) {
            Integer assignedIndex = Math.mod(startIndex + i, totalUsers);
            filteredLeads[i].OwnerId = queueUserIds[assignedIndex];
        }
    }
}
