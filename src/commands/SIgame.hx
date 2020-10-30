package commands;


import haxe.Timer;
import haxe.Json;
import sys.FileSystem;
import haxe.Http;
import haxe.xml.Access;
import haxe.zip.Reader;
import haxe.io.BytesInput;
import sys.io.File;
import com.raidandfade.haxicord.types.Message;

@desc("SIgame","Модуль для задавания вопросов из своей игры в чат")
class SIgame {

    static var siQuests:Array<SiQuest> = new Array();
    static var quester:Timer;
    static var skipVoted:Array<String> = [];
    
    static var hinted:Array<Int> = [];



    @initialize
    public static function initialize() {
        if (FileSystem.exists("si.json")) {
            siQuests = Json.parse(File.getContent("si.json"));
            if (siQuests.length == 0) return;
            quester = new Timer(1000 * 60 * 60);
            quester.run = askNext;
        }
    }


    static function ask() {
        var qq = siQuests[0];
        Rgd.bot.sendMessage(Rgd.botChan, {
            embed: {
                author: {
                    name: 'Категория: ${qq.theme}',
                    icon_url: "https://vladimirkhil.com/images/si.jpg",
                },
                description: "**Вопрос:\n**" + qq.question.join('\n'),
                footer: {
                    text: 'Цена вопроса: ${qq.price}',
                }
            }
        });
    }

    static function siParse(m:Message, w:Array<String>) {  
        var packBytes = File.getBytes('pack.zip');
        var byteInput = new BytesInput(packBytes);
        var reader = Reader.readZip(byteInput);

        var newQuest:Array<SiQuest> = [];

        for(file in reader) {
            if (file.fileName == 'content.xml') {

                haxe.zip.Tools.uncompress(file);
                var data = file.data.toString();
                
                var xml = Xml.parse(data);
                var acc = new Access(xml.firstElement());

                var rounds = acc.node.rounds;

                for (r in rounds.elements) {
                    trace(r.name + ' ' + r.att.name);

                    for(theme in r.node.themes.elements) {

                        for (q in theme.node.questions.nodes.question) {

                            var qq:SiQuest = {};
                            qq.theme = theme.att.name;
                            qq.price = q.att.price;
                            qq.answer = q.node.right.node.answer.innerData;

                            var s = q.node.scenario;
                            
                            var atoms:Array<String> = [];
                            var nonText = false;

                            for(atom in s.nodes.atom) {
                                atoms.push(atom.innerData);
                                if (atom.has.type) {
                                    nonText = true;
                                    break;
                                }
                            }

                            if (nonText == true)
                                continue;

                            qq.question = atoms;
                            newQuest.push(qq);
                        }   
                    }
                }
                break;
            }

        }


        if (newQuest.length > 0) {
            Rgd.bot.sendMessage(m.channel_id.id, {
                embed: {
                    description: 'Загружен пак с `${newQuest.length}` вопросами и теперь он начнет спрашиваться'
                }
            });
            siQuests = newQuest;
            ask();

            if (quester != null) 
                quester.stop();
            quester = new Timer(1000 * 60 * 60);
            quester.run = askNext;
        } else {
            Rgd.bot.sendMessage(m.channel_id.id, {
                embed: {
                    description: 'В паке ни одного подходящего вопроса'
                }
            });
        }

    }


    @admin
    @command(['siLoad'], " ", " ")
    public static function siLoad(m:Message, w:Array<String>) {
        if (w[0] == null) {
            m.reply({content: 'не указана ссылка на пак'});
            return;
        } 

        var r = new Http(w[0]);
        r.onBytes = function (b) {
            File.saveBytes('pack.zip', b);
            siParse(m, w);
        }
        r.request();
    }

    @inbot
    @command(['siAnswer', 'si', 'a', 'си'], "Ответить на вопрос", ">ответ")
    public static function siAnswer(m:Message, w:Array<String>) {
        if (siQuests[0] == null) return;

        var ra = siQuests[0].answer.split(" ").filter(e -> e != " ");
        
        for (i in 0...ra.length) 
            ra[i] = toDownCase(ra[i]);

        for (i in 0...w.length) 
            w[i] = toDownCase(w[i]);
        
        

        var has = 0;

        for (word in w) { 
            if (ra.contains(word))
                has++;
        }
        
        var percent = has / ra.length;

        var ans = siQuests[0].answer;

        var miss = function () {
            if (hinted.length < Math.min(5, ans.length)) {

                var hint = "";
                while (true) {
                    var r = Std.random(ans.length);
                    var code = ans.charCodeAt(r);
                    var sym = String.fromCharCode(code);
                    trace('pushed $r $code $sym');
                    if (!hinted.contains(code)) {
                        hinted.push(r);
                        break;
                    }
                }
                

                for (i in 0...ans.length) {
                    if (hinted.contains(ans.charCodeAt(i))) {
                        hint += ans.charAt(i);
                    } else {
                        hint += (ans.charAt(i) == " ") ? " " : "*";
                    }
                }

                m.reply({content: 'Подсказка `$hint`'});

            } else {
                askNext();
            }
        }

        if (percent < 0.1) {
            m.reply({content: '<@${m.author.id.id}>, абсолютно неверный ответ'});
            miss();
        } else if (percent >= 0.1 && percent < 0.5) {
            m.reply({content: '<@${m.author.id.id}>, кажется близко к ответу'});
            miss();
        } else if (percent >= 0.5 && percent < 0.75){
            m.reply({content: '<@${m.author.id.id}>, не совсем, но засчитывается'});
            askNext();
        } else {
            m.reply({content: '<@${m.author.id.id}>, абсолютно верно'});
            askNext();
        }
    }


    public static function askNext() {
        Rgd.bot.sendMessage(Rgd.botChan,{content: 'Следующий вопрос,а ответом на этот был `${siQuests[0].answer}`'});

        hinted = [];
        quester.stop();
        siQuests.shift();

        if (siQuests.length > 0) {
            ask();
            quester = new Timer(1000 * 60 * 60);
            quester.run = askNext;
        } else {
            Rgd.bot.sendMessage(Rgd.botChan, {
                embed: {
                    description: 'Вопросы пака закончились, ставьте следующий'
                }
            });
        }
    }

    @inbot
    @command(['siNext', 'skip', 's', 'next', 'с', 'дальше'], "Пропуск вопроса", "")
    public static function siNext(m:Message, w:Array<String>) {
        if (siQuests.length > 0) {

            if (!skipVoted.contains(m.author.id.id)) {
                skipVoted.push(m.author.id.id);
            }
    
            if (skipVoted.length < 2) {
                m.reply({content: 'Голосов для пропуска ${skipVoted.length}/2'});
                return;
            } else {
                skipVoted = [];
            }

            askNext();
        }
    }


    @inbot
    @admin
    @command(['siNextCat', 'skipCat', 'категорияГовно', 'ск'], "Пропуск категории", "")
    public static function siNextCat(m:Message, w:Array<String>) {
        if (siQuests.length > 0) {
            var theme = siQuests[0].theme;
            for (q in siQuests) {
                if (q.theme != theme) {
                    break;
                }
                siQuests.shift();
            }
            askNext();
        }
    }

    @down
    public static function down() {
        File.saveContent('si.json', Json.stringify(siQuests));
    }

    /*
    @command(['cs'], "", "")
    public static function cs(m:Message, w:Array<String>) {
        var u:UnicodeString = w[0];
        m.reply({content: ${u.toLowerCase()}}); 
    }
    */

    static function toDownCase(str:String):String {
        str = str.toLowerCase();
        

        var up = ["Й", "Ц", "У", "К", "Е", "Н", "Г", "Ш", "Щ", "З", "Х", "Ъ", "Ф", "Ы", "В", "А", "П", "Р", "О", "Л", "Д", "Ж", "Э", "Я", "Ч", "С", "М", "И", "Т", "Ь", "Б", "Ю", "Ё"];
        var dw = ["й", "ц", "у", "к", "е", "н", "г", "ш", "щ", "з", "х", "ъ", "ф", "ы", "в", "а", "п", "р", "о", "л", "д", "ж", "э", "я", "ч", "с", "м", "и", "т", "ь", "б", "ю", "ё"];
        var tr = ['`', '!', '@', '$', '$', '%', '^', '&', '*', '-', '+', '[', ']', '\\', "'", '"', '|', '<', '>', ',', '.', '?', '(', ')'];
        var s = '';

        for (i in 0...str.length) {
            var l = str.charAt(i);
            if (up.contains(l)) {
                l = dw[up.indexOf(l)];
            }
            if (tr.contains(l)) {
                l = " ";
            }

            s += l;
        }

        return s;
    }

}


typedef SiQuest = {
    var ?theme:String;
    var ?question:Array<String>;
    var ?answer:String;
    var ?price:String;
}
