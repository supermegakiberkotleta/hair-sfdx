trigger OpportunityTrigger on Opportunity (after insert) {
    // Собираем все LeadId из новых Opportunities
    Set<Id> leadIds = new Set<Id>();
    for (Opportunity opp : Trigger.new) {
        if (opp.SlaesForceLeadId__c != null) {
            leadIds.add(opp.SlaesForceLeadId__c);
        }
    }

    // Загружаем связанные лиды одной выборкой
    Map<Id, Lead> leadsMap = new Map<Id, Lead>(
        [SELECT Id, Name FROM Lead WHERE Id IN :leadIds]
    );

    // Отправляем email по каждой Opportunity
    for (Opportunity opp : Trigger.new) {
        Id leadId = opp.SlaesForceLeadId__c;
        if (leadId != null && leadsMap.containsKey(leadId)) {
            Lead lead = leadsMap.get(leadId);
            LeadEmailSender.sendOpportunityCreatedEmail(
                opp.Id,
                opp.Name,
                leadId,
                lead.Name
            );
        }
    }
}