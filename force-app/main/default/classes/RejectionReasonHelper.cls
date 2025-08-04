public class RejectionReasonHelper {
    // Метод для установки значений причин в объекте RejectionReason__c
    public static void setReasonValues(List<String> reasons, RejectionReason__c record, Map<String, String> reasonFields) {
        for (String reason : reasons) {
            reason = reason.trim();
            if (reasonFields.containsKey(reason)) {
                record.put(reasonFields.get(reason), true);
            }
        }
    }
}