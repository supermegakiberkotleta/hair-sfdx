public class CallRecordingInfo {
    public String mediaUrl;
    public Integer duration;
    public Datetime startTime;

    public CallRecordingInfo() {
        // Пустой конструктор нужен для создания экземпляра вручную
    }

    public CallRecordingInfo(String mediaUrl, Integer duration, Datetime startTime) {
        this.mediaUrl = mediaUrl;
        this.duration = duration;
        this.startTime = startTime;
    }
}