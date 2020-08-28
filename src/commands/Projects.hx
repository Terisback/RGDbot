package commands;

import com.raidandfade.haxicord.types.structs.Embed;
import events.OnMessage;
import haxe.Timer;
import com.raidandfade.haxicord.types.Message;


@desc("Projects","Модуль для демонстрации своих проектов и просмотра чужих")
class Projects {
    
    @initialize
    public static function initialize() {
        Rgd.db.request('
            CREATE TABLE IF NOT EXISTS "proj" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT,
                "userId" TEXT,
                "projName" TEXT,
                "projDesc" TEXT,
                "projLink" TEXT,
                "projPic" TEXT
            )'
        );
        
    }


    static var adds:Map<String, {?name:String, ?desc:String, ?url:String, ?pic:String}> = new Map();
    @inbot
    @command(['projadd','проэдд','продоб'], 'Добавить проект в свой список')
    public static function projadd(m:Message, w:Array<String>) {

        if (adds.exists(m.author.id.id)) return;

        if (w[0] != "+") {
            m.reply({embed: {description: '${m.author.tag}, эта команда предназначена для добавления проекта в свой список, если вы хотите добавить его, то напишите `${Rgd.prefix}projadd +`, затем бот попросит по порядку у вас имя,описание,ссылку,картинку проекта, если вы что-то обнаружите ошибку, то просто напишите `стоп`'}});
            return;
        }

        m.reply({embed: {description: '${m.author.tag}, введите название проекта'}}, (msg, err)-> {
            if (err != null) {
                m.reply({content: 'что-то пошло не так'});
                return;
            }

            var timer = new Timer(1000*60*2);
            var awaiter = null;

            awaiter = function (dm:Message) {
                if (dm.author.id.id != m.author.id.id) return;
                if (dm.channel_id.id != m.channel_id.id) return;

                var i = m.author.id.id;

                if (dm.content == 'стоп') {
                    m.reply({embed: {description: '${m.author.tag}, добавление проекта прекращено'}});
                    adds.remove(m.author.id.id);
                    OnMessage.messageOn.remove(awaiter);
                    timer.stop();
                    return;
                }

                if (adds[i].name == null) {
                    adds[i].name = dm.content;
                    m.reply({embed: {description: '${m.author.tag}, введите описание проекта'}});
                } else if (adds[i].desc == null) {
                    adds[i].desc = dm.content;
                    m.reply({embed: {description: '${m.author.tag}, введите ссылку на страницу проекта'}});
                } else if (adds[i].url == null) {
                    adds[i].url = dm.content;
                    m.reply({embed: {description: '${m.author.tag}, введите ссылку со скриншотом/обложкой вашего проекта'}});
                } else if (adds[i].pic == null) {
                    adds[i].pic = dm.content;
                    
                    var p = adds[i];
                    Rgd.db.request('INSERT INTO proj(userId, projName, projDesc, projLink, projPic) VALUES("${i}", "${p.name}", "${p.desc}", "${p.url}", "${p.pic}")');

                    m.reply({embed: {description: '${m.author.tag}, вы успешно добавили проект в свой список проектов, теперь и другие смогут посмотреть на него'}});
                    adds.remove(m.author.id.id);
                    OnMessage.messageOn.remove(awaiter);
                    timer.stop();
                }

            }

            timer.run = function () {
                m.reply({embed: {description: '${m.author.tag}, добавление проекта прекращено, вы не успели добавить его за отведенное время'}});
                adds.remove(m.author.id.id);
                OnMessage.messageOn.remove(awaiter);
                timer.stop();
            }

            adds.set(m.author.id.id, {});
            OnMessage.messageOn.push(awaiter);
        });


    }

    @inbot
    @command(['projects','proj','проекты'], 'Просмотреть проекты пользователя', '>юзер ?номер проекта')
    public static function projects(m:Message, w:Array<String>) {
        
        var mention = m.mentions[0];
        if (mention == null) {
            m.reply({embed: {description: '${m.author.tag}, не указано чьи проекта смотреть'}});
            return;
        }

        var proj = Rgd.db.request('SELECT * FROM proj WHERE userId = "${mention.id.id}"');

        if (proj.length == 0) {
            m.reply({embed: {description: '${m.author.tag}, у него не на что смотреть'}});
            return;
        }

        var embed:Embed = {
            author: {icon_url: mention.avatarUrl, name: mention.username}, 
            footer: {text: 'запрос от ${m.author.username}'},
        };
        var k = 1;

        var n = Std.parseInt(w[1]);
        if (n != null) {

            for (p in proj) {
                if (k==n) {
                    embed.title = p.projName;
                    embed.description = p.projDesc;
                    embed.image = {url: p.projPic};
                    embed.url = p.projLink;
                    m.reply({embed: embed});
                    break;
                }
                k++;
            }
            return;
        }

        var d = '';
        for (p in proj) {
            d += '${k++}. ${p.projName} \n';
        }
        embed.description = d;
        m.reply({embed: embed});

    }


    @inbot
    @command(['projdel','продел'], 'Удалить проект из своего списка', ' >номер проекта')
    public static function projdel(m:Message, w:Array<String>) {

        var n = Std.parseInt(w[0]);

        if (n == null) {
            m.reply({embed: {description: '${m.author.tag}, не указано какой проект удалять'}});
            return;
        }

        var proj = Rgd.db.request('SELECT * FROM proj WHERE userId = "${m.author.id.id}"');

        var  k = 1;
        for (p in proj) {
            if (k==n) {
                Rgd.db.request('DELETE FROM proj WHERE userId = "${m.author.id.id}" and projName = "${p.projName}"');
                m.reply({embed: {description: '${m.author.tag}, `${p.projName}` удален из списка твоих проектов'}});
                return;
            }
            k++;
        }

        m.reply({embed: {description: '${m.author.tag}, такого проекта не найдено'}});

    }

}