public class BrokerFeeCalculator {
    private static final Map<String, Decimal> tagToPercent = new Map<String, Decimal>{
        'Biz Capital 12%'     => 0.12,
        'Biz Capital 10%'     => 0.14,
        'Biz Capital 8%'      => 0.14,
        'Biz Capital 6%'      => 0.14,
        'Boostra 12%'         => 0.12,
        'Boostra High Risk'   => 0.10,
        'No MCA'              => 0.12,
        'Denied'              => 0.10
    };

    public static Decimal calculate(String tag, Decimal offerAmount) {
        if (String.isBlank(tag) || offerAmount == null) return null;

        if (!tagToPercent.containsKey(tag)) return null;

        Decimal percent = tagToPercent.get(tag);
        return offerAmount * percent;
    }
}
