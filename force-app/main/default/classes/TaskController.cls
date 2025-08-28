public with sharing class TaskController {
    public class TaskWrapper {
        @AuraEnabled public List<Task> tasks { get; set; }
        @AuraEnabled public Decimal missedPaymentCount { get; set; }
    }

    // Получение задач по Opportunity
    @AuraEnabled(cacheable=true)
    public static TaskWrapper getTasksByOpportunity(Id opportunityId) {
        TaskWrapper wrapper = new TaskWrapper();

        wrapper.tasks = [
            SELECT Id, Subject, ActivityDate, Status, Type,
                   Who.Name, Who.FirstName, Who.LastName,
                   Owner.Name, Owner.FirstName, Owner.LastName,
                   IsClosed, Priority
            FROM Task
            WHERE WhatId = :opportunityId
            ORDER BY ActivityDate ASC NULLS LAST, CreatedDate DESC
        ];

        Opportunity opp = [
            SELECT Missed_Payment_Count__c 
            FROM Opportunity 
            WHERE Id = :opportunityId
        ];
        wrapper.missedPaymentCount = opp.Missed_Payment_Count__c;

        return wrapper;
    }

    // Обновление задачи
    @AuraEnabled
    public static void updateTask(Id taskId, String status, Date activityDate) {
        Task taskToUpdate = new Task(
            Id = taskId,
            Status = status,
            ActivityDate = activityDate
        );
        update taskToUpdate;
    }

    // Получение Email/SMS/Calls по задаче
    @AuraEnabled
    public static Map<String, List<sObject>> getActivityDetailsForTask(Id taskId) {
        Map<String, List<sObject>> result = new Map<String, List<sObject>>();

        // EmailMessage связан с задачей через ParentId
        List<EmailMessage> emails = [
            SELECT Id, Subject, FromAddress, ToAddress, CreatedDate, TextBody
            FROM EmailMessage
            WHERE ParentId = :taskId
            ORDER BY CreatedDate DESC
        ];

        // Calls — те задачи, которые указывают в WhatId эту задачу
        List<Task> calls = [
            SELECT Id, Subject, ActivityDate, Status, Description
            FROM Task
            WHERE WhatId = :taskId AND Type = 'Call'
            ORDER BY ActivityDate DESC
        ];

        // SMS — задачи с Subject LIKE '%SMS%', у которых WhatId = taskId
        List<Task> smsList = [
            SELECT Id, Subject, ActivityDate, Status, Description
            FROM Task
            WHERE WhatId = :taskId AND Subject LIKE '%SMS%'
            ORDER BY ActivityDate DESC
        ];

        result.put('emails', emails);
        result.put('calls', calls);
        result.put('sms', smsList);

        return result;
    }
}