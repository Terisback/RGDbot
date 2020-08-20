package events;

import com.raidandfade.haxicord.types.structs.Emoji;
import com.raidandfade.haxicord.types.User;
import com.raidandfade.haxicord.types.Message;

class OnReactionAdd {
    public static var reactOn:Array<(m:Message, u:User, e:Emoji) -> Void> = new Array();
    
    public static function onReactionAdd(m:Message, u:User, e:Emoji) {
        for (func in reactOn) {
            func(m, u, e);
        }
    }
}