public class LoanLeadsConvertedBatchStarter implements Queueable {
    private List<Id> leadIds;

    public LoanLeadsConvertedBatchStarter(List<Id> leadIds) {
        this.leadIds = leadIds;
    }

    public void execute(QueueableContext context) {
        if (!leadIds.isEmpty()) {
            Database.executeBatch(new LoanLeadsConvertedBatch(leadIds));
        }
    }
}
