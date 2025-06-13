global class CallRecordingBatch implements Database.Batchable<Task>, Database.Stateful, Database.AllowsCallouts {

    private List<Id> taskIds;

    public CallRecordingBatch(List<Id> taskIds) {
        this.taskIds = taskIds;
    }

    global Iterable<Task> start(Database.BatchableContext BC) {
        System.debug('CallRecordingBatch.start — Task IDs: ' + taskIds);
        return [
            SELECT Id, Subject, Description, WhoId, WhatId, OwnerId
            FROM Task
            WHERE Id IN :taskIds
        ];
    }

    global void execute(Database.BatchableContext BC, List<Task> tasks) {
        System.debug('CallRecordingBatch.execute — Tasks received: ' + tasks.size());

        List<Call_record__c> recordsToInsert = new List<Call_record__c>();

        for (Task task : tasks) {
            System.debug('Processing Task ID: ' + task.Id);
            System.debug('Description: ' + task.Description);

            String description = task.Description;
            if (String.isBlank(description)) {
                System.debug('Description is blank, skipping');
                continue;
            }

            String sid = extractSid(description);
            System.debug('Extracted SID: ' + sid);

            if (String.isBlank(sid)) {
                System.debug('SID is blank, skipping');
                continue;
            }

            CallRecordingInfo info = TwilioService.getRecordingInfoByConferenceSid(sid);
            System.debug('TwilioService returned: ' + info);

            if (info == null || String.isBlank(info.mediaUrl)) {
                System.debug('No recording info or mediaUrl is blank, skipping');
                continue;
            }

            Call_record__c record = new Call_record__c();
            record.Name = 'Call: ' + info.startTime + ' (' + info.duration + ' sec)';
            record.Record__c = info.mediaUrl;
            record.Duration__c = info.duration;
            record.Start_time__c = info.startTime;

            record.OwnerId = getOwnerId(task);
            System.debug('Owner ID set to: ' + record.OwnerId);

            setRelatedObject(record, task);
            System.debug('Related object set. Record: ' + record);

            recordsToInsert.add(record);
        }

        System.debug('Total records to insert: ' + recordsToInsert.size());
        if (!recordsToInsert.isEmpty()) {
            try {
                insert recordsToInsert;
                System.debug('Successfully inserted records');
            } catch (Exception e) {
                System.debug('Insert failed: ' + e.getMessage());
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('CallRecordingBatch finished');
    }

    private String extractSid(String descriptionText) {
        Pattern p = Pattern.compile('Sid:\\s*(CF[\\w]+)');
        Matcher m = p.matcher(descriptionText);
        if (m.find()) return m.group(1);
        return null;
    }

    private Id getOwnerId(Task task) {
        return task.OwnerId;
    }

    private void setRelatedObject(Call_record__c rec, Task task) {
        if (task.WhoId != null && String.valueOf(task.WhoId).startsWith('00Q')) {
            rec.Lead__c = task.WhoId;
            System.debug('Linked to Lead: ' + task.WhoId);
        } else if (task.WhoId != null && String.valueOf(task.WhoId).startsWith('003')) {
            rec.Contact__c = task.WhoId;
            System.debug('Linked to Contact: ' + task.WhoId);
        }

        if (task.WhatId != null && String.valueOf(task.WhatId).startsWith('001')) {
            rec.Account__c = task.WhatId;
            System.debug('Linked to Account: ' + task.WhatId);
        } else if (task.WhatId != null && String.valueOf(task.WhatId).startsWith('006')) {
            rec.Opportunity__c = task.WhatId;
            System.debug('Linked to Opportunity: ' + task.WhatId);
        }
    }
}
