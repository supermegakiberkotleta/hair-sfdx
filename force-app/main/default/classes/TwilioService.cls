public class TwilioService {
    public static CallRecordingInfo getRecordingInfoByConferenceSid(String sid) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Twilio_Recording/conferences/' + sid + '/Recordings.json');
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> recordings = (List<Object>) jsonMap.get('recordings');

            if (!recordings.isEmpty()) {
                Map<String, Object> recording = (Map<String, Object>) recordings[0];
                CallRecordingInfo info = new CallRecordingInfo();
                info.mediaUrl = (String) recording.get('media_url');

                // Приведение строки к целому числу
                String durationStr = (String) recording.get('duration');
                if (durationStr != null) {
                    info.duration = Integer.valueOf(durationStr.split('\\.')[0]);
                }

                info.startTime = parseDatetime((String) recording.get('start_time'));
                return info;
            }
        }
        return null;
    }

    private static Datetime parseDatetime(String datetimeStr) {
        if (datetimeStr == null) return null;
        return Datetime.valueOfGmt(datetimeStr.replace(' +0000', ''));
    }
}
