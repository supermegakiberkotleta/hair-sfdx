global class CallRecordingBatch implements Database.Batchable<Task>, Database.Stateful {

    private List<Id> taskIds;

    public CallRecordingBatch(List<Id> taskIds) {
        this.taskIds = taskIds;
    }

    global Iterable<Task> start(Database.BatchableContext BC) {
        return [
            SELECT Id, Subject, Description, WhoId, WhatId, OwnerId
            FROM Task
            WHERE Id IN :taskIds
        ];
    }

    global void execute(Database.BatchableContext BC, List<Task> tasks) {
        List<Call_record__c> recordsToInsert = new List<Call_record__c>();

        for (Task task : tasks) {
            String description = task.Description;
            if (String.isBlank(description)) continue;

            String sid = extractSid(description);
            if (String.isBlank(sid)) continue;

            CallRecordingInfo info = TwilioService.getRecordingInfoByConferenceSid(sid);
            if (info == null || String.isBlank(info.mediaUrl)) continue;

            Call_record__c record = new Call_record__c();
            record.Name = 'Call: ' + info.startTime + ' (' + info.duration + ' sec)';
            record.Record__c = info.mediaUrl;
            record.Duration__c = info.duration;
            record.Start_time__c = info.startTime;

            record.OwnerId = getOwnerId(task);
            setRelatedObject(record, task);
            recordsToInsert.add(record);
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }
    }

    global void finish(Database.BatchableContext BC) {}

    private String extractSid(String descriptionText) {
        Pattern p = Pattern.compile('Sid:\\s*(CF[\\w]+)');
        Matcher m = p.matcher(descriptionText);
        if (m.find()) return m.group(1);
        return null;
    }

    private Id getOwnerId(Task task) {
        if (task.WhoId != null) return task.WhoId;
        if (task.WhatId != null) return task.WhatId;
        return task.OwnerId;
    }

    private void setRelatedObject(Call_record__c rec, Task task) {
        if (task.WhoId != null && String.valueOf(task.WhoId).startsWith('00Q')) {
            rec.Lead__c = task.WhoId;
        } else if (task.WhoId != null && String.valueOf(task.WhoId).startsWith('003')) {
            rec.Contact__c = task.WhoId;
        }

        if (task.WhatId != null && String.valueOf(task.WhatId).startsWith('001')) {
            rec.Account__c = task.WhatId;
        } else if (task.WhatId != null && String.valueOf(task.WhatId).startsWith('006')) {
            rec.Opportunity__c = task.WhatId;
        }
    }
}
