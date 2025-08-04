trigger LeadQueueAssignmentTrigger on Lead (before insert) {
    LeadQueueAssigner.assignOwners(Trigger.new);
}