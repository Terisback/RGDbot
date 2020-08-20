package commands;

import haxe.Timer;
import com.raidandfade.haxicord.types.structs.Embed;
import com.raidandfade.haxicord.types.Message;

@desc("User","Модуль получения информации о юзерах")
class User {
    
    @initialize
    public static function initialize() {
        Rgd.db.request('
            CREATE TABLE IF NOT EXISTS "users" (
                "userId" TEXT PRIMARY KEY,
                "first" TEXT,
                "rep" INTEGER DEFAULT 0,
                "exp" INTEGER DEFAULT 0,
                "coins" INTEGER DEFAULT 0,
                "voice" INTEGER DEFAULT 0,
                "leave" INTEGER DEFAULT 0,
                "here" INTEGER
            )'
        );
        Rgd.db.request('
            CREATE TABLE IF NOT EXISTS "usersRole" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "userId" TEXT,
                "roleId" TEXT
            )'
        );
    }


    @command(["online", "онлайн"], "Статистика онлайна")
    public static function online(m:Message, w:Array<String>) {
        var g = m.getGuild();
        var act = 0;
        var aid = '';
        for (role in g.roles) {
            if (role.name == "Актив") {
                aid = role.id.id;
                break;
            }
        }
        for (member in g.members) {
            if (member.roles.indexOf(aid) >= 0) {
                act++;
            }
        }
        var embed:Embed = {
            description: "**Статистика Russian Gamedev**",
            color: 0x99FF00,
            fields: [
                {
                    name: 'Пользователи',
                    value: 'Всего: ${g.member_count}\n Активнов: $act',
                    _inline: true,
                }
            ],
        }
        m.reply({embed: embed});
    }

    @inbot
    @command(["user", "юзер", "u"], "Информация о пользователе", ">пингЮзера")
    public static function user(m:Message, w:Array<String>) {
        var uid = m.mentions[0] == null ? m.author.id.id : m.mentions[0].id.id;

        var u = Rgd.db.request('SELECT * FROM users WHERE userId = "$uid"').results().first();
        var member = m.getGuild().members[uid];

        var inVoice = DateTools.parse(u.voice);

        var embed:Embed = {
            footer: {text: 'Запрос от ${m.getMember().displayName}'},
            color: 0xFF9900,
            thumbnail: {url: member.user.avatarUrl},
            fields: [
                {name: 'Имя аккаунта', value: '`${member.user.username}#${member.user.discriminator}`', _inline: true},
                {name: 'Упоминание', value: '${member.user.tag}', _inline: true},
                {name: 'Создан', value: '${Date.fromTime(member.user.id.timestamp).toString()}', _inline: true},
                {name: 'Первый вход', value: '${u.first}', _inline: true},
                {name: 'Репутация', value: '${u.rep}', _inline: true},
                {name: 'Баланс', value: '${u.coins}', _inline: true},
                {name: 'Понаписал', value: '${u.exp}', _inline: true},
                {name: 'Наговорил', value: '${inVoice.hours}:${inVoice.minutes}:${inVoice.seconds}', _inline: true},
                {name: 'Ливал раз', value: '${u.leave}', _inline: true},
            ],
        }

        m.reply({embed: embed});

    }

    @command(["когда", "when"], "Когда пользователь зашел на сервер", ">пингЮзера")
    public static function when(m:Message, w:Array<String>) {
        var u = m.mentions[0];
        if (u == null) {
            m.reply({content: 'Сервер был созддан `${Date.fromTime(m.getGuild().id.timestamp).toString()}`'});
        } else {
            var time = Rgd.db.request('SELECT first FROM users WHERE userId = "${u.id.id}"').getResult(0);
            m.reply({content: '`${u.username}` зашел на сервер `${time}`'});
        }
    }


    static var respectCd:Map<String, Timer> = new Map();
    @command(["респект", "respect"], "Проявить увожение", ">пингЮзера")
    public static function respect(m:Message, w:Array<String>) {
        if (respectCd.exists(m.author.id.id)) {
            m.reply({content: 'Нельзя так часто проявлять увожение'});
            return;
        }

        var u = m.mentions[0];
        if (u == null) {
            m.reply({content: 'Не указан юзер'});
            return;
        }
        if (u.id.id == m.author.id.id) {
            m.reply({content: 'Нельзя уважать самого себя'});
            return;
        }

        Rgd.db.request('UPDATE users SET rep = rep + 1 WHERE userId = "${u.id.id}"');
        var rep = Rgd.db.request('SELECT rep FROM users WHERE userId = "${u.id.id}"').getIntResult(0);
        m.reply({content: 'Теперь репутация <@${u.id.id}> повысилась до `$rep`'});

        var timer = new Timer(1000*60*60*3);
        timer.run = function () {
            respectCd.remove(m.author.id.id);
            timer.stop();
        }
        respectCd.set(m.author.id.id, timer);
    }


    @inbot
    @command(["reptop", 'рептоп'], "Топ юзеров по репутации")
    public static function reptop(m:Message, w:Array<String>) {
        var top = Rgd.db.request('SELECT userId,rep FROM users WHERE here = 1 ORDER BY rep DESC LIMIT 10');
        var c = '';
        var members = m.getGuild().members;
        var p = 1;

        for (pos in top) 
            c += '${p++}.${members[pos.userId].user.tag}:`${pos.rep}`\n';

        var embed:Embed = {
            fields: [
                {name: '**Топ по репутации**', value: c, _inline: true}, 
            ]
        }
        m.reply({embed: embed});

    }


    @inbot
    @command(["voicetop", 'войстоп'], "Топ юзеров по времни в войсе")
    public static function voicetop(m:Message, w:Array<String>) {
        var top = Rgd.db.request('SELECT userId,voice FROM users WHERE here = 1 ORDER BY voice DESC LIMIT 10');
        var c = '';
        var members = m.getGuild().members;
        var p = 1;

        for (pos in top) {
            var v = DateTools.parse(pos.voice);
            c += '${p++}.${members[pos.userId].user.tag}:`${v.hours}:${v.minutes}:${v.seconds}`\n';
        }
        var embed:Embed = {
            fields: [
                {name: '**Топ по времени в войсе**', value: c, _inline: true}, 
            ]
        }
        m.reply({embed: embed});
    }


    @inbot
    @command(["chattop", 'чаттоп'], "Топ юзеров по активности в чате")
    public static function chattop(m:Message, w:Array<String>) {
        var top = Rgd.db.request('SELECT userId,exp FROM users WHERE here = 1 ORDER BY exp DESC LIMIT 10');
        var c = '';
        var members = m.getGuild().members;
        var p = 1;

        for (pos in top) {
            c += '${p++}.${members[pos.userId].user.tag}:`${pos.exp}`\n';
        }
        var embed:Embed = {
            fields: [
                {name: '**Топ активности в чате**', value: c, _inline: true}, 
            ]
        }
        m.reply({embed: embed});
    }
    

}