trigger TaskTrigger on Task (after insert) {
    List<Id> taskIds = new List<Id>();

    for (Task t : Trigger.new) {
        if (t.Subject != null && t.Subject.contains('Completed') && t.Description != null && t.Description.contains('Sid:')) {
            taskIds.add(t.Id);
        }
    }

    if (!taskIds.isEmpty()) {
        System.enqueueJob(new CallRecordingBatchStarter(taskIds));
    }
}
