package commands;

import sys.io.File;
import haxe.Json;
import com.raidandfade.haxicord.types.structs.Embed;
import com.raidandfade.haxicord.types.Message;

@desc("Jam","Модуль информации о джемах")
class Jam {
    
    @inbot
    @command(["jam", "джем"], "Получить информацию о джеме", ">номер джема")
    public static function jam(m:Message, w:Array<String>) {
        var jams:JamDoc = Json.parse(File.getContent('jams.txt'));
        var n = Std.parseInt(w[0]);
        var embed:Embed = {
            color: 0xFF9900,
            footer: {text: 'по запросу ${m.author.username}', icon_url: m.author.avatarUrl}
        }
        if (n == null) {
            embed.author = {name :'Архив джемов Russian Gamedev'}
            embed.description = 'Вы можете узнать результаты прошедших джемов нашего сервера, а также поиграть в игры с этих джемов!';
            var k = 1;
            var text = '';
            for (jam in jams.info) 
                text += '${k++}. ${jam.name}\n';
            embed.fields = [{name: '**Список Джемов**', value: text}];
        } else {
            n--;
            if (n<0 || n>jams.info.length) {
                m.reply({content: 'Джема с таким номером нет'});
                return;
            }
            var j = jams.info[n]; 
            embed.author = {name : j.name}
            embed.description = '**Тема**: ${j.theme}\n**Призы**: ${j.prize}\n**Дата проведения**: ${j.time}';
            
            var games = '';
            var k = 1;
            for (proj in j.projects) {
                games += '${k++}.${proj.author}: `${proj.name}`\n';
            }
            embed.fields = [
                {name: 'Игры', value: games},
                {name: 'Ссылки', value: '' + (j.streamlink == '' ? '': 'Ссылка на стрим: ${j.streamlink}\n') + (j.link == '' ? '': 'Ссылка на игры: ${j.link}\n')}
            ];
        }

        m.reply({embed: embed});
    }

}

typedef JamDoc = {
    var ?info:Array<{
        var ?name:String;
        var ?theme:String;
        var ?prize:String;
        var ?time:String;
        var ?places_format:Bool;
        var ?link:String;
        var ?streamlink:String;
        var ?googledoc:String;
        var ?projects:Array<{
            var ?name:String;
            var ?author:String;
            var ?win:Bool;
            var ?nomination:String;
            var ?link:String;
        }>;
    }>;
}