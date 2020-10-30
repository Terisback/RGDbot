package events;

import haxe.Timer;
import com.raidandfade.haxicord.utils.DPERMS;
import com.raidandfade.haxicord.types.Message;

using StringTools;
class OnMessage {

    public static var messageOn:Array<(m:Message) -> Void> = new Array();

    public static function onMessage(m:Message) {
        
        if (m.getGuild().id.id != Rgd.rgdId) return;
        if (m.author.bot) return;

        var words = m.content.split(" ").filter(e -> e.length > 0);



        if (words[0] != null  ) {

            var p:String = '';
            for (s in Rgd.prefix) {
                var symbol = String.fromCharCode(s);
                if (words[0].startsWith(symbol)) {
                    p = symbol;
                    break;
                }
            }
            
            if (p.length > 0) {
                var comName = words.shift().replace(p, "");
                if (Rgd.commandMap.exists(comName)) {
                    var command:Rgd.Command = Rgd.commandMap.get(comName);

                    if (command.admin) {
                        if (!m.hasPermission(DPERMS.ADMINISTRATOR)){
                            return;
                        }
                    }
                    if (command.inbot) {
                        if (m.channel_id.id != Rgd.botChan) {
                            m.reply({content: 'Данная команда работает только в <#${Rgd.botChan}>'}, (msg, err) -> {
                                if (err != null) return;
                                var timer = new Timer(1000*10);
                                timer.run = function () {
                                    msg.delete();
                                    timer.stop();
                                }
                            });
                            return; 
                        }
                    }
                    Reflect.callMethod(command._class, Reflect.field(command._class,command.command),[m, words]);
                }
            } else {
                for (func in messageOn) {
                    func(m);
                }
            }

            Rgd.db.request('UPDATE users SET exp = exp + ${words.length} WHERE userId = "${m.author.id.id}"');
            Rgd.db.request('UPDATE day SET text = text + ${words.length} WHERE userId = "${m.author.id.id}"');
            Rgd.db.request('UPDATE week SET text = text + ${words.length} WHERE userId = "${m.author.id.id}"');
        }
        
       

    
    }
}