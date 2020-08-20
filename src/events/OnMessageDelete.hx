package events;

class OnMessageDelete {
    
    public static function onMessageDelete(id:String) {
        Rgd.db.request('DELETE FROM rr WHERE msgId = "$id"');
    }

}