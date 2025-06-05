public class CallRecordingBatchStarter implements Queueable {
    private List<Id> taskIds;

    public CallRecordingBatchStarter(List<Id> taskIds) {
        this.taskIds = taskIds;
    }

    public void execute(QueueableContext context) {
        Database.executeBatch(new CallRecordingBatch(taskIds), 10);
    }
}
