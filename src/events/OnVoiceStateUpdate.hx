package events;

import com.raidandfade.haxicord.types.GuildMember;

class OnVoiceStateUpdate {
    static var voiceMap:Map<String, Date> = new Map();

    public static function onVoiceStateUpdate(data:VoiceUpdateStruck) {
        if (data.guild_id != Rgd.rgdId) return;

        if (data.channel_id == null) {
            if (voiceMap.exists(data.user_id)) {
                var time = Date.now().getTime() - voiceMap[data.user_id].getTime();
                Rgd.db.request('UPDATE users SET voice = voice + $time WHERE userId = "${data.user_id}"');
                voiceMap.remove(data.user_id);
            }
        } else {
            if (!voiceMap.exists(data.user_id)) {
                voiceMap.set(data.user_id, Date.now());
            }
        }
    }

}


typedef VoiceUpdateStruck = {
	var ?deaf:Bool;
	var ?suppress:Bool;
	var ?mute:Bool;
	var ?user_id:String;
	var ?guild_id:String;
	var ?self_video:Bool;
	var ?member:GuildMember;
	var ?self_mute:Bool;
	var ?self_deaf:Bool;
	var ?channel_id:String;
}