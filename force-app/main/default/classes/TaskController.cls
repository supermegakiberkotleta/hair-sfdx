public with sharing class TaskController {
    public class TaskWrapper {
        @AuraEnabled public List<Task> tasks { get; set; }
        @AuraEnabled public Decimal missedPaymentCount { get; set; }
    }

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

    @AuraEnabled
    public static void updateTask(Id taskId, String status, Date activityDate) {
        Task taskToUpdate = new Task(
            Id = taskId,
            Status = status,
            ActivityDate = activityDate
        );
        update taskToUpdate;
    }

    @AuraEnabled
    public static Map<String, List<sObject>> getActivityDetailsForTask(Id opportunityId, Date activityDate) {
        List<OpportunityContactRole> opportunityContactRoles = [
            SELECT ContactId, Contact.Email, Contact.Phone
            FROM OpportunityContactRole
            WHERE OpportunityId = :opportunityId
        ];

        List<Id> contactIds = new List<Id>();

        List<String> contactEmails = new List<String>();

        List<String> contactPhones = new List<String>();

        for (OpportunityContactRole opportunityContactRole : opportunityContactRoles) {
            if (opportunityContactRole.ContactId != null) {
                contactIds.add(opportunityContactRole.ContactId);
            }

            if (opportunityContactRole.Contact.Email != null) {
                contactEmails.add(opportunityContactRole.Contact.Email);
            }

            if (opportunityContactRole.Contact.Phone != null) {
                contactPhones.add(opportunityContactRole.Contact.Phone);
            }
        }

        Map<String, List<sObject>> result = new Map<String, List<sObject>>();

        List<EmailMessage> emails = [
            SELECT Id, Subject, ToAddress, CreatedDate, TextBody
            FROM EmailMessage
            WHERE DAY_ONLY(CreatedDate) = :activityDate
            AND ToAddress IN :contactEmails 
            ORDER BY CreatedDate DESC
        ];

        List<Call_record__c> calls = [
            SELECT Id, Name, duration__c, Record__c
            FROM Call_record__c
            WHERE DAY_ONLY(start_time__c) = :activityDate
            AND Contact__c IN :contactIds
            ORDER BY start_time__c DESC
        ];

        List<TwilioSF__Message__c> sms = [
            SELECT Id, Name, TwilioSF__Body__c, TwilioSF__Date_Created__c
            FROM TwilioSF__Message__c
            WHERE DAY_ONLY(TwilioSF__Date_Created__c) = :activityDate
            AND (TwilioSF__From_Number__c IN :contactPhones OR TwilioSF__To_Number__c IN :contactPhones)
            ORDER BY TwilioSF__Date_Created__c DESC
        ];

        result.put('emails', emails);
        result.put('calls', calls);
        result.put('sms', sms);

        return result;
    }
}