public class BrokerFeeBatchInvoker {
    public class RunBatchJob implements Queueable {
        private String objectName;
        public RunBatchJob(String objectName) {
            this.objectName = objectName;
        }
        public void execute(QueueableContext context) {
            Database.executeBatch(new BrokerFeeBatch(objectName), 200);
        }
    }

    public static void runBatch(String objectName) {
        System.enqueueJob(new RunBatchJob(objectName));
    }
}
