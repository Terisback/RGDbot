package commands;

import haxe.xml.Access;
import haxe.zip.Reader;
import haxe.io.BytesInput;
import sys.io.File;
import com.raidandfade.haxicord.types.Message;

class SIgame {

    @admin
    @command(['si'], " ", " ")
    public static function si(m:Message, w:Array<String>) {
        
        // if (w[0] == null) {
        //     m.reply({content: 'не указана ссылка на пак'});
        //     return;
        // } 
        

        
        var packFiles:List<haxe.zip.Entry> = new List();
        var packBytes = File.getBytes('pack.zip');
        var byteInput = new BytesInput(packBytes);
        var reader = Reader.readZip(byteInput);

        

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
                                //trace(atom.has.type + ' ' + atom.innerData);
                                
                                atoms.push(atom.innerData);

                                if (atom.has.type) {
                                    nonText = true;
                                    break;
                                }
                            }

                            if (nonText == true)
                                continue;

                            qq.question = atoms;
                            
                            Rgd.bot.sendMessage(Rgd.botChan, {
                                embed: {
                                    description: qq.question.join('\n'),
                                    author: {
                                        name: qq.theme,
                                    },
                                    footer: {
                                        text: qq.price,
                                    }
                                }
                            });

                            Sys.sleep(0.5);
                        }   

                    }

                }

                break;
            }

        }
        

    }




}


typedef SiQuest = {
    var ?theme:String;
    var ?question:Array<String>;
    var ?answer:String;
    var ?price:String;
}