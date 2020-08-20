package commands;

import com.raidandfade.haxicord.utils.DPERMS;
import haxe.rtti.Meta;
import com.raidandfade.haxicord.types.structs.Embed;
import com.raidandfade.haxicord.types.Message;
import com.raidandfade.haxicord.types.structs.Embed.EmbedField;

@desc("Info","Модуль информации о модулях/командах")
class Help {

    
    @command(["about"], "Информация о боте")
    public static function about(m:Message, w:Array<String>) {
        var f1:EmbedField = {
            name: "Автор",
            value: "@Fataliti // Reifshneider#3923",
        }
        var f2:EmbedField = {
            name: "Написан на",
            value: "Haxe+Haxicord -> NekoVM",
        }
        var f3:EmbedField = {
            name: "Дайте деняк на джем",
            value: "QIWI +79057444964",
        }
        var f4:EmbedField = {
            name: "Дайте деняк автору бота",
            value: "https://qiwi.com/n/REIFSHNEIDER\nhttps://money.yandex.ru/to/4100111915700580",
        }
        var embed:Embed = {
            author: {name: "RGDbot",icon_url: Rgd.bot.user.avatarUrl, },
            fields: [f1, f2, f3, f4],
            color: 0xFF9900,
            title: "Сурсы",
            url: "https://github.com/fataliti/RGDbot",
            thumbnail: {url: "https://cdn.discordapp.com/attachments/735105892264968234/745941444044390400/YxQQFFHzypg.png",},
        }
        m.reply({embed: embed});
    }

    @inbot
    @command(["info", "help"], "Показать модули либо информацию о конкретном модуле/команде"," ?модуль|команда")
    public static function help(m:Message, words:Array<String>) {
        var shift = words.shift();
        if (shift != null) {

            var command = Rgd.commandMap.get(shift);
            if (command != null){
                var _static = Meta.getStatics(command._class);
                var field   = Reflect.fields(_static).filter((e) -> e == command.command)[0];
                var refl    = Reflect.field(_static, field);
                
                if (Reflect.hasField(refl, "admin")) 
                    if (!m.hasPermission(DPERMS.ADMINISTRATOR)) 
                        return;


                var embed:Embed = {}
                embed.color = 0xFF9900;
                embed.author = { name: "RGDbot", icon_url: Rgd.bot.user.avatarUrl,}
                embed.fields = [{name: refl.command[0].join(", "), value: '${refl.command[1]}',}];
                embed.footer = {text: '${Rgd.prefix}help|info ?команда/модуль'}

                if (refl.command[2] != null) {
                    embed.fields.push({name:"Использование", value: '${Rgd.prefix}${refl.command[0].join("|")} ${refl.command[2]}'});
                }

                m.reply({embed: embed});
            } else {
                var classList = CompileTime.getAllClasses("commands");
                var mod = classList.filter(_class -> Type.getClassName(_class).indexOf(shift) > -1).first();
               
                if (mod == null) return;
                
                var meta = Meta.getType(mod);
                var refl = Reflect.field(meta, "desc");
                if (refl == null) return;

                if (Reflect.hasField(meta, "admin")) 
                    if (!m.hasPermission(DPERMS.ADMINISTRATOR)) 
                        return;
                
                var embed:Embed = {}
                embed.color = 0xFF9900;
                embed.author = { name: refl[0], icon_url: Rgd.bot.user.avatarUrl,}
                embed.description = refl[1];
                embed.footer = {text: '${Rgd.prefix}help|info ?команда/модуль'}

                var commands = Meta.getStatics(mod);
                var comlist  = "";
                for(com in Reflect.fields(commands)) {
                    var filds = Reflect.field(commands, com);
                    if (!Reflect.hasField(filds, "command")) continue;

                    if (Reflect.hasField(filds, "admin")) 
                        if (!m.hasPermission(DPERMS.ADMINISTRATOR)) 
                            continue;

                    comlist += '`${filds.command[0].join('|')}` ${filds.command[1]}\n';
                }

                embed.fields = [{
                    name: 'Команды модуля:',
                    value: comlist,
                }];

                m.reply({embed: embed});
            }
        } else {
            
            var classList = CompileTime.getAllClasses("commands");

            var embed:Embed = {}
            embed.color = 0xFF9900;
            embed.author = { name: "RGDbot", icon_url: Rgd.bot.user.avatarUrl,}
            embed.footer = {text: '${Rgd.prefix}help|info ?команда/модуль'}
            var embFild:EmbedField = {name: 'Модули', value: ''};
            
            for (_class in classList) {
                var meta = Meta.getType(_class);
                var refl = Reflect.field(meta, "desc");
                if (refl == null) continue;

                if (Reflect.hasField(meta, "admin")) 
                    if (!m.hasPermission(DPERMS.ADMINISTRATOR)) 
                        continue;
                
                embFild.value += '`${refl[0]}` ${refl[1]}\n';
            }
            embed.fields = [embFild];
            m.reply({embed: embed});
        }
    }

    @command(["ison", "ping"], "Проверить отвечает ли бот")
    public static function ison(m:Message, w:Array<String>)  {
        m.reply({content: 'РГД на связи'});
    }
    
}