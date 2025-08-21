// Apex-класс для создания нового Lead на основе Opportunity
// Копируются поля Company (берется из Name, если Company хранится в другом поле — заменить), LastName, uuid__c и устанавливается нужный RecordTypeId
public with sharing class CreateLeadFromOpportunity {
    @AuraEnabled
    public static Id createLead(Id opportunityId) {
        Opportunity opp = [SELECT Id, Name, uuid__c, SlaesForceLeadId__c FROM Opportunity WHERE Id = :opportunityId LIMIT 1];
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
        sendLeadIdToRefinance(newLead.Id, opportunityId, opp.SlaesForceLeadId__c);
        return newLead.Id;
    }
    @future(callout=true)
    private static void sendLeadIdToRefinance(Id leadId, Id opportunityId, Id slaesForceLeadId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://lenderpro.itprofit.net/api/v1/loans/refinance');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000);
        Map<String, Object> body = new Map<String, Object>{
            'leadId' => String.valueOf(leadId),
            'id' => String.valueOf(leadId),
            'opportunityId' => String.valueOf(opportunityId),
            'SlaesForceLeadId__c' => slaesForceLeadId == null ? null : String.valueOf(slaesForceLeadId)
        };
        req.setBody(JSON.serialize(body));
        System.debug('sendLeadIdToRefinance endpoint=' + req.getEndpoint() + ', body=' + req.getBody());
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            System.debug('sendLeadIdToRefinance status=' + res.getStatusCode() + ', body=' + res.getBody());
        } catch (Exception e) {
            System.debug('sendLeadIdToRefinance error: ' + e.getMessage());
        }
    }
}