package events;

import haxe.Timer;
import com.raidandfade.haxicord.utils.DPERMS;
import com.raidandfade.haxicord.types.Message;

class OnMessage {
    public static function onMessage(m:Message) {
        
        if (m.getGuild().id.id != Rgd.rgdId) return;

        if (StringTools.startsWith(m.content, Rgd.prefix)) {
            if (!m.inGuild()) return;
            var words:Array<String> = m.content.split(" ");
            
            words = words.filter(w -> w.length > 0);

            var comName = words.shift();
            comName = StringTools.replace(comName, Rgd.prefix, "");
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
        }

        Rgd.db.request('UPDATE users SET exp = exp + ${m.content.length} WHERE userId = "${m.author.id.id}"');

    }
}