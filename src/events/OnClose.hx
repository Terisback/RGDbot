package events;

class OnClose {
    public static function onClose(i:Int) {
        OnVoiceStateUpdate.saveTime();
        Sys.exit(0);
    }
}