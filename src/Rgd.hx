

import com.raidandfade.haxicord.types.GuildMember;
import events.*;
import sys.db.Connection;
import com.raidandfade.haxicord.DiscordClient;

class Rgd {
	public static var bot:DiscordClient;
	
	public static var db:Connection;
	public static var commandMap:Map<String,Command> = new Map();

	#if test
	static var token = "";
	public static var prefix = "";
	public static var rgdId = "";
	public static var botChan = "";
	public static var msgChan = "";
	#else 
	static var token = "";
	public static var prefix = "";
	public static var rgdId = "";
	public static var botChan = "";
	public static var msgChan = "";
	#end
	// public static var dbChan = '';

	static function main() {
		bot = new DiscordClient(token);
		bot.onReady = OnReady.onReady;
		bot.onMessage = OnMessage.onMessage;
		bot.onMemberLeave = OnMemberLeave.onMemberLeave;
		bot.onMemberJoin = OnMemberJoin.onMemberJoin;
		bot.onMemberUpdate = OnMemberUpdate.onMemberUpdate;
		bot.onVoiceStateUpdate = OnVoiceStateUpdate.onVoiceStateUpdate;
		bot.onMessageDelete = OnMessageDelete.onMessageDelete;
		//bot.onMessageEdit =
		bot.onReactionAdd = OnReactionAdd.onReactionAdd;
		bot.onReactionRemove = OnReactionRemove.onReactionRemove;

		bot.ws.onClose = i -> Sys.exit(0);
	}
}

typedef Command = {
    var _class:Class<Dynamic>;
	var command:String;
	var ?inbot:Bool;
	var ?admin:Bool;
}

