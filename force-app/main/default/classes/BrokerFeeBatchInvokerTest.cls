@isTest
public class BrokerFeeBatchInvokerTest {
    @isTest
    static void testRunBatch() {
        String testObjectName = 'Lead';

        Test.startTest();
        BrokerFeeBatchInvoker.runBatch(testObjectName);
        Test.stopTest();
    }
}
