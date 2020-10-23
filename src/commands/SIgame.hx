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

class SIgame {

    static var siQuests:Array<SiQuest> = new Array();
    static var quester:Timer;


    @initialize
    public static function initialize() {
        if (FileSystem.exists("si.json")) {
            siQuests = Json.parse(File.getContent("si.json"));
            quester = new Timer(1000 * 60 * 1);
            quester.run = askNext;
        }
    }


    static function ask() {
        var qq = siQuests[0];
        Rgd.bot.sendMessage(Rgd.msgChan, {
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
            quester = new Timer(1000 * 60 * 1);
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


    @command(['siAnswer', 'si', 'a'], "Ответить на вопрос", ">ответ")
    public static function siAnswer(m:Message, w:Array<String>) {
        if (m.channel_id.id != Rgd.msgChan) return;
        if (siQuests[0] == null) return;

        var ra = siQuests[0].answer.split(" ").filter(e -> e != " ");
        var has = 0;

        for (word in w) { 
            if (ra.contains(word))
                has++;
        }
        
        var percent = has / ra.length;

        if (percent < 0.1) {
            m.reply({content: '<@${m.author.id.id}>, абсолютно неверный ответ'});
        } else if (percent >= 0.1 && percent < 0.5) {
            m.reply({content: '<@${m.author.id.id}>, кажется близко к ответу'});
        } else if (percent >= 0.5 && percent < 0.75){
            m.reply({content: '<@${m.author.id.id}>, не совсем, но засчитывается'});
            askNext();
        } else {
            m.reply({content: '<@${m.author.id.id}>, абсолютно верно'});
            askNext();
        }
    }


    public static function askNext() {

        Rgd.bot.sendMessage(Rgd.msgChan,{content: 'Следующий вопрос,а ответом на этот был `${siQuests[0].answer}`'});

        quester.stop();
        siQuests.shift();

        if (siQuests.length > 0) {
            ask();
            quester = new Timer(1000 * 60 * 1);
            quester.run = askNext;
        } else {
            Rgd.bot.sendMessage(Rgd.msgChan, {
                embed: {
                    description: 'Вопросы пака закончились, ставьте следующий'
                }
            });
        }
    }

    @admin
    @command(['siNext'], "Пропуск вопроса", "")
    public static function siNext(m:Message, w:Array<String>) {
        if (siQuests.length > 0) {
            askNext();
        }
    }

    @down
    public static function down() {
        File.saveContent('si.json', Json.stringify(siQuests));
    }




}


typedef SiQuest = {
    var ?theme:String;
    var ?question:Array<String>;
    var ?answer:String;
    var ?price:String;
}
