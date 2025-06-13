public class TwilioService {
    public static CallRecordingInfo getRecordingInfoByConferenceSid(String sid) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Twilio_Recording/Conferences/' + sid + '/Recordings.json');
        req.setMethod('GET');

        Http http = new Http();
        HttpResponse res = http.send(req);

        System.debug('--- TwilioService.getRecordingInfoByConferenceSid ---');
        System.debug('Status code: ' + res.getStatusCode());
        System.debug('Body: ' + res.getBody());

        if (res.getStatusCode() == 200) {
            try {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                System.debug('Parsed JSON: ' + jsonMap);

                List<Object> recordings = (List<Object>) jsonMap.get('recordings');
                System.debug('Recordings list: ' + recordings);

                if (recordings == null || recordings.isEmpty()) {
                    System.debug('No recordings found');
                    return null;
                }

                Map<String, Object> recording = (Map<String, Object>) recordings[0];
                System.debug('First recording: ' + recording);

                CallRecordingInfo info = new CallRecordingInfo();
                info.mediaUrl = (String) recording.get('media_url');
                System.debug('Parsed mediaUrl: ' + info.mediaUrl);

                Object durationObj = recording.get('duration');
                System.debug('Raw duration: ' + durationObj);

                if (durationObj != null) {
                    if (durationObj instanceof String) {
                        info.duration = Integer.valueOf(((String) durationObj).split('\\.')[0]);
                    } else if (durationObj instanceof Integer) {
                        info.duration = (Integer) durationObj;
                    } else if (durationObj instanceof Decimal) {
                        info.duration = ((Decimal) durationObj).intValue();
                    }
                    System.debug('Parsed duration: ' + info.duration);
                }

                String rawStartTime = (String) recording.get('start_time');
                System.debug('Raw start_time: ' + rawStartTime);
                info.startTime = parseDatetime(rawStartTime);
                System.debug('Parsed start_time: ' + info.startTime);

                return info;

            } catch (Exception e) {
                System.debug('Exception while parsing response: ' + e.getMessage());
            }
        } else {
            System.debug('Non-200 response: ' + res.getStatusCode());
        }

        return null;
    }

    private static Datetime parseDatetime(String datetimeStr) {
        if (datetimeStr == null) return null;
        System.debug('Parsing datetime from: ' + datetimeStr);

        try {
            List<String> parts = datetimeStr.split(', ');
            if (parts.size() > 1) {
                String[] dateTimeParts = parts[1].replace(' +0000', '').split(' ');
                String formatted = dateTimeParts[2] + '-' +
                                   monthToNumber(dateTimeParts[1]) + '-' +
                                   dateTimeParts[0] + ' ' +
                                   dateTimeParts[3];

                System.debug('Formatted datetime string: ' + formatted);
                return Datetime.valueOfGmt(formatted);
            }
        } catch (Exception e) {
            System.debug('Error parsing datetime: ' + e.getMessage());
        }

        return null;
    }

    private static String monthToNumber(String month) {
        Map<String, String> months = new Map<String, String>{
            'Jan' => '01', 'Feb' => '02', 'Mar' => '03',
            'Apr' => '04', 'May' => '05', 'Jun' => '06',
            'Jul' => '07', 'Aug' => '08', 'Sep' => '09',
            'Oct' => '10', 'Nov' => '11', 'Dec' => '12'
        };
        return months.get(month);
    }
}
