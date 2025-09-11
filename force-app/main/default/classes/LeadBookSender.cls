public with sharing class LeadBookSender {
    @AuraEnabled
    public static Object sendLeadToEndpoint(Id leadId) {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            // ⚠️ Уберите лишние пробелы в URL!
            request.setEndpoint('https://lenderpro.ai/api/v1/ocrolus/create-book-second');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(new Map<String, Object>{
                'leadId' => leadId
            }));

            HttpResponse response = http.send(request);

            Map<String, Object> result = new Map<String, Object>();

            if (response.getStatusCode() == 200) {
                result.put('success', true);
                result.put('message', 'Успешно отправлено');
                result.put('responseBody', response.getBody());
            } else {
                result.put('success', false);
                result.put('message', 'Ошибка запроса: ' + response.getStatus());
                result.put('responseBody', response.getBody()); // <-- Здесь будет {"error":"Lead not found"}
            }

            return result;

        } catch (Exception e) {
            return new Map<String, Object>{
                'success' => false,
                'message' => 'Исключение: ' + e.getMessage(),
                'responseBody' => null
            };
        }
    }
}