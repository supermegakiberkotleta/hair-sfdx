public class LeadQueueAssigner {

    private static final String TARGET_RECORD_TYPE_ID = '012Kc000000ten6IAA';

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
              AND Participates_in_the_queue__c = true
            ORDER BY CreatedDate ASC, Id ASC
        ];

        if (queueUsers.isEmpty()) {
            return;
        }

        List<Id> queueUserIds = new List<Id>();
        for (User u : queueUsers) {
            queueUserIds.add(u.Id);
        }

        // Получить последний созданный лид с нужным RecordTypeId
        Lead lastLead;
        try {
            lastLead = [
                SELECT OwnerId
                FROM Lead
                WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID
                  AND OwnerId IN :queueUserIds
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        } catch (Exception e) {
            lastLead = null;
        }

        Id lastOwnerId = lastLead != null ? lastLead.OwnerId : null;
        Integer startIndex = 0;

        if (lastOwnerId != null) {
            Integer idx = queueUserIds.indexOf(lastOwnerId);
            if (idx != -1 && idx + 1 < queueUserIds.size()) {
                startIndex = idx + 1;
            } else {
                startIndex = 0;
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
