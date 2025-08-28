public class SendLenderTypeService {
    @future(callout=true)
    public static void sendLenderType(String opportunityId, String lenderType) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://lenderpro.ai/api/v1/lender-type');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            Map<String, String> payload = new Map<String, String>{
                'opportunityId' => opportunityId,
                'lenderType' => lenderType
            };

            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            System.debug('Response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Callout failed: ' + e.getMessage());
        }
    }
}