// Apex-класс для создания нового Lead на основе Opportunity
// Копируются поля Company (берется из Name, если Company хранится в другом поле — заменить), LastName, uuid__c и устанавливается нужный RecordTypeId
public with sharing class CreateLeadFromOpportunity {
    @AuraEnabled
    public static Id createLead(Id opportunityId) {
        Opportunity opp = [SELECT Id, Name, uuid__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
        Id loanLeadsRecordTypeId = [
            SELECT Id FROM RecordType WHERE SObjectType = 'Lead' AND Name = 'Loan leads' LIMIT 1
        ].Id;
        Lead newLead = new Lead();
        newLead.Company = opp.Name; // Замените на нужное поле, если Company не в Name
        newLead.LastName = opp.Name; // Обязательное поле
        newLead.Status = 'MANUAL PARSING';
        newLead.RecordTypeId = loanLeadsRecordTypeId;
        if (Schema.sObjectType.Lead.fields.getMap().containsKey('uuid__c')) {
            newLead.put('uuid__c', opp.uuid__c);
        }
        insert newLead;
        return newLead.Id;
    }
}