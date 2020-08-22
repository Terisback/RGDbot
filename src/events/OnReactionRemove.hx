package events;

import com.raidandfade.haxicord.types.User;
import com.raidandfade.haxicord.types.structs.Emoji;

import com.raidandfade.haxicord.types.Message;

class OnReactionRemove {
    public static var reactOff:Array<(m:Message, u:User, e:Emoji) -> Void> = new Array();

    public static function onReactionRemove(m:Message, u:User, e:Emoji) {
        if (u.bot) return;
        for (func in reactOff) {
            func(m, u, e);
        }
    }
}