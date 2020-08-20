package commands;

import com.raidandfade.haxicord.types.structs.Emoji;
import events.OnReactionRemove;
import events.OnReactionAdd;
import com.raidandfade.haxicord.types.Message;

@admin
@desc("RoleMessage","Модуль управления сообщений с реакциями")
class RoleMessage {

    static var roleMsg:Array<String> = [];

    @initialize
    public static function initialize() { 
        Rgd.db.request('
            CREATE TABLE IF NOT EXISTS "rr" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "chanId" TEXT,
                "msgId" TEXT,
                "roleId" TEXT,
                "emoji" TEXT
            )'
        );
        OnReactionAdd.reactOn.push((m, u, e) -> {
            if (u == null || u.bot) return; 
            var emote = e.id == null ? e.name : e.id;
            var rolesId = Rgd.db.request('SELECT roleId FROM rr WHERE chanId = "${m.channel_id.id}" and msgId = "${m.id.id}" and emoji = "$emote"');
            for (role in rolesId) {
                m.getGuild().getMember(u.id.id, member -> {
                    member.addRole(role.roleId);
                });
            }
        });

        OnReactionRemove.reactOff.push((m, u, e) -> {
            if (u == null || u.bot) return; 
            var emote = e.id == null ? e.name : e.id;
            var rolesId = Rgd.db.request('SELECT roleId FROM rr WHERE chanId = "${m.channel_id.id}" and msgId = "${m.id.id}" and emoji = "$emote"');
            for (role in rolesId) {
                m.getGuild().getMember(u.id.id, member -> {
                    member.removeRole(role.roleId);
                });
            }
        });
    }

    @admin
    @command(["rradd"], "Роль по реакции у сообщения", ">id_сообщения >emoji >roleId/rolePing")
    public static function rolereact(m:Message, w:Array<String>) {
        var msgId = w.shift();
        if (msgId == null) {
            m.reply({content: "не указан Id сообщения"});
            return;
        }
        m.getChannel().getMessage(msgId, (msg, str) -> {
            if (msg == null) {
                m.reply({content: "сообщение не найдено"});
                return;
            }
            var emoji = w.shift();
            if (emoji == null) {
                m.reply({content: "не указано эмодзи"});
                return;
            }

            var emote = null;
            if (StringTools.startsWith(emoji, '<')) {
                var p = emoji.lastIndexOf(':')+1;
                emoji = emoji.substr(p,  emoji.length - p - 1);
                emote = m.getGuild().emojis.filter(em -> em.id == emoji)[0];
                if (emote == null) {
                    m.reply({content: "не найдено эмодзи на этом сервере"});
                    return;
                }
            }
            var role = w.shift();
            if (role == null && m.mention_roles[0] == null) {
                m.reply({content: "не указана роль"});
                return;
            }
            if (m.mention_roles[0] != null) 
                role = m.mention_roles[0].id.id;
            if (!m.getGuild().roles.exists(role)){
                m.reply({content: "кажется такой роли не существует"});
                return;
            }
            msg.react(emote == null ? emoji : ':${emote.name}:${emote.id}', (e1, err) -> {
                if (err != null) {
                    trace(err);
                    m.reply({content: "что-то пошло не так"});
                    return;
                }                
                Rgd.db.request('INSERT OR IGNORE INTO rr(chanId, msgId, roleId, emoji) VALUES("${m.channel_id.id}", "${msg.id.id}", "$role", "$emoji")');
                return;
            });

        });

    }

    @admin
    @command(["rrdel"], "Удалить роль по реакции у сообщения", ">id сообщения >emoji")
    public static function rrdel(m:Message, w:Array<String>) {
        var msgId = w.shift();
        if (msgId == null) {
            m.reply({content: "не указан Id сообщения"});
            return;
        }
        m.getChannel().getMessage(msgId, (msg, str) -> {
            if (msg == null) {
                m.reply({content: "сообщение не найдено"});
                return;
            }
            var emoji = w.shift();
            if (emoji == null) {
                m.reply({content: "не указано эмодзи"});
                return;
            }

            var emote = null;
            if (StringTools.startsWith(emoji, '<')) {
                var p = emoji.lastIndexOf(':')+1;
                emoji = emoji.substr(p,  emoji.length - p - 1);
                emote = m.getGuild().emojis.filter(em -> em.id == emoji)[0];
                if (emote == null) {
                    m.reply({content: "не найдено эмодзи на этом сервере"});
                    return;
                }
            }

            Rgd.db.request('DELETE FROM rr WHERE msgId = "${msg.id.id}" and chanId = "${m.channel_id.id}" and emoji = "$emoji"');
            m.reply({content: 'удалено'});
        });
    }

    @admin
    @command(["rrpurge"], "Удалить все роли по реакции у сообщения", ">id сообщения")
    public static function rrpurge(m:Message, w:Array<String>) {
        var msgId = w.shift();
        if (msgId == null) {
            m.reply({content: "не указан Id сообщения"});
            return;
        }
        m.getChannel().getMessage(msgId, (msg, str) -> {
            if (msg == null) {
                m.reply({content: "сообщение не найдено"});
                return;
            }
            msg.removeAllReactions((m_, err) -> {
                if (err != null) {
                    m.reply({content: "что-то пошло не так"});
                    return;
                }
                m.reply({content: "удалено"});
                Rgd.db.request('DELETE FROM rr WHERE msgId = "${msg.id.id}" and chanId = "${m.channel_id.id}"');
            });
        });
    }
    

}