package commands;

import events.OnMessage;
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
                "part" TEXT DEFAULT "",
                "about" TEXT DEFAULT "",
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
                {name: 'Уровень увожения', value: '${u.rep}', _inline: true},
                {name: 'Баланс', value: '${u.coins}', _inline: true},
                
                {name: 'Понаписал', value: '${u.exp}', _inline: true},
                {name: 'Наговорил', value: '${inVoice.hours}:${inVoice.minutes}:${inVoice.seconds}', _inline: true},
                {name: 'Ливал раз', value: '${u.leave}', _inline: true},
            ],
        }
        if (u.part != '') {embed.fields.push({name: 'В браке с', value: '<@${u.part}>'});}
        if (u.about != '') {embed.fields.push({name: 'Об юзере', value: '${u.about}'});}
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
        m.reply({content: 'Теперь увожение <@${u.tag}> повысилось до `$rep`'});

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
        var p = 1;
        for (pos in top) 
            c += '${p++}.<@${pos.userId}>:`${pos.rep}`\n';

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
        var p = 1;

        for (pos in top) {
            var v = DateTools.parse(pos.voice);
            c += '${p++}.<@${pos.userId}>:`${v.hours}:${v.minutes}:${v.seconds}`\n';
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
        var p = 1;

        for (pos in top) {
            c += '${p++}.<@${pos.userId}>:`${pos.exp}`\n';
        }
        var embed:Embed = {
            fields: [
                {name: '**Топ активности в чате**', value: c, _inline: true}, 
            ]
        }
        m.reply({embed: embed});
    }
    
    static var marryArr:Array<String> = new Array();
    @command(['marry','свадьба'], "Позвать юзера в брак", ">ping Юзера")
    public static function marry(m:Message, w:Array<String>) {
        
        var has = Rgd.db.request('SELECT part FROM users WHERE userId = "${m.author.id.id}"');
        if (has.results().first().part != "") {
            m.reply({content: 'ты уже состоишь в браке'});
            return;
        } 
        var u = m.mentions[0];
        if (u == null) {
            m.reply({content: 'не указан юзер для брака'});
            return;
        }

        if (u.id.id == m.author.id.id) {
            m.reply({content: 'нельзя заключить брак с самим собой'});
            return;
        }

        if (marryArr.contains(u.id.id) || marryArr.contains(m.author.id.id)) {
            m.reply({content: 'вашему предложение мешает какое-то другое'});
            return;
        }

        var parthas = Rgd.db.request('SELECT part FROM users WHERE userId = "${u.id.id}"').results().first().part;
        if (parthas != "") {
            m.reply({content: 'этот человек занят'});
            return;
        }

        m.reply({content: '${u.tag}, ${m.author.tag} предложил заключить брачный союз, если согласны, напишите `да` иначе `нет`'}, (msg, err) -> {
            if (err != null) return;

            var awaiter = null;
            var timer = new Timer(1000 * 30);

            awaiter = function (dm:Message) {
                if (dm.author.id.id != u.id.id) return;
                if (dm.content == 'да' || dm.content == 'нет') {
                    if (dm.content == 'да') {
                        Rgd.db.request('UPDATE users SET part = "${u.id.id}" WHERE userId = "${m.author.id.id}"');
                        Rgd.db.request('UPDATE users SET part = "${m.author.id.id}" WHERE userId = "${u.id.id}"');
                        m.reply({content: '${u.tag} и ${m.author.tag} сыграли свадьбу!'});
                    } else {
                        m.reply({content: '${m.author.tag}, тебе отказали'});
                    }
                    marryArr.remove(u.id.id);
                    marryArr.remove(m.author.id.id);
                    OnMessage.messageOn.remove(awaiter);
                    timer.stop();
                }
            }
            timer.run = function () {
                m.reply({content: '${u.tag}, ${m.author.tag}, время вышло'});
                OnMessage.messageOn.remove(awaiter);
                marryArr.remove(u.id.id);
                marryArr.remove(m.author.id.id);
                timer.stop();
            }

            OnMessage.messageOn.push(awaiter);
            marryArr.push(u.id.id);
            marryArr.push(m.author.id.id);
        });
    }

    @command(['divorce', 'развод'], "Развестись")
    public static function divorce(m:Message, w:Array<String>) {
        var has = Rgd.db.request('SELECT part FROM users WHERE userId = "${m.author.id.id}"');
        var id = has.results().first().part;
        if (id == '') {
            m.reply({content: 'ты не состоишь ни в каком браке'});
            return;
        } 
        
        m.reply({content: '<@${id}>, ${m.author.tag} разводится с вами'}, (msg, err) -> {
            if (err != null) return;

            Rgd.db.request('UPDATE users SET part = "" WHERE userId = "${m.author.id.id}"');
            Rgd.db.request('UPDATE users SET part = "" WHERE userId = "${id}"');
        });
    }

    @inbot
    @command(['setdesc'], "Установить описание себя в карточку юзера", ">описание(не более 500 символов)")
    public static function setdesc(m:Message, w:Array<String>) {
        var desc = w.join(" ");
        if (desc.length == 0){
            m.reply({content: 'Нужно описание'});
            return;
        }
        if (desc.length > 500){
            m.reply({content: 'Слишком жирно'});
            return;
        }
        Rgd.db.request('UPDATE users SET about = "$desc" WHERE userId = "${m.author.id.id}"');
        m.reply({content: '${m.author.tag} описание установлено'});
    }
}