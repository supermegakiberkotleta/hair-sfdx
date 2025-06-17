public class BrokerFeeBatchInvoker {
    @future
    public static void runBatch(String objectName) {
        Database.executeBatch(new BrokerFeeBatch(objectName), 200);
    }
}
