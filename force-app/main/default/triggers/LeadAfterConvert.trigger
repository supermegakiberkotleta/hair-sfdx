trigger LeadAfterConvert on Lead (after update) {
    LeadConvertHandler.afterLeadConvert(Trigger.new, Trigger.oldMap);
}