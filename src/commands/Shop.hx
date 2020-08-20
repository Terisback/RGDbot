package commands;

import com.raidandfade.haxicord.types.structs.Embed;
import com.raidandfade.haxicord.types.Message;

@desc("Shop","Модуль магазина")
class Shop {

    @inbot
    @command(['shop', 'магазин'], "Серверный магазин", "?номер товара")
    public static function shop(m:Message, w:Array<String>) {
        var t = Std.parseInt(w.shift());

        if (t == null) {
            var embed:Embed = {
                author: {name: 'Магазин Russian Gamedev'},
                description: 'Вы можете купить любой товар из списка в магазине за игровую валюту на сервере',
                fields: [
                    {name: '1. Сменить боту статус', value: '500<:rgd_coin_rgd:745172019619823657>'},
                    {name: '2. Выбрать существующий цвет никнейма', value: '1000<:rgd_coin_rgd:745172019619823657>'},
                    {name: '3. Создать новый цвет никнейма', value: '50000 <:rgd_coin_rgd:745172019619823657>'},
                ],
                color: 0xff9900,
            }
            m.reply({embed: embed});
        } else {
            var has = Rgd.db.request('SELECT coins FROM users WHERE userId = "${m.author.id.id}"').getIntResult(0);
            switch(t) {
                case 1: 
                    if (w.length == 0) {
                        var embed:Embed = {
                            author: {name: 'Сменить боту статус'},
                            description: 'Стоимость 500<:rgd_coin_rgd:745172019619823657>\nДля покупки укажите номер товара и новый статус',
                            fields: [{name: 'Пример', value: '${Rgd.prefix}shop 1 женя лох'}],
                            color: 0xff9900,
                        }
                        m.reply({embed: embed});
                        return;
                    }

                    if (has >= 500) {
                        Rgd.bot.setStatus({
                            afk: false,
                            status: 'online',
                            game: {
                                type: 0,
                                name: w.join(' '),
                            }
                        });
                        Rgd.db.request('UPDATE users SET coins = coins - 500 WHERE userId = "${m.author.id.id}"');
                    } else {
                        m.reply({content: 'у тебя не хватает монет'});
                    }
                case 2:
                    var rs = w.shift();
                    if (rs == null) {
                        var embed:Embed = {
                            author: {name: 'Магазин цветных ролей'},
                            description: 'Все за 1000<:rgd_coin_rgd:745172019619823657>\nДля покупки укажите номер товара и номер роли',
                            fields: [{name: 'Каталог', value: ''}],
                            color: 0xff9900,
                        }
                        var k = 1;

                        for (role in m.getGuild().roles) 
                            if (role.name == 'role') 
                                embed.fields[0].value += '${k++}.<@&${role.id.id}>\n';

                        m.reply({embed: embed});
                        return;
                    }
                    if (has >= 1000) {
                        var n = Std.parseInt(rs);
                        if (n == null) {
                            m.reply({content: 'Неверно указан номер товара'});
                            return;
                        }

                        var k = 1;
                        for (role in m.getGuild().roles) {
                            if (role.name == 'role') {
                                if (k == n) {
                                    m.getMember().addRole(role.id.id);
                                    m.reply({embed: {description: '<@${m.author.id.id}> куплена роль <@&${role.id.id}>'}});
                                    Rgd.db.request('UPDATE users SET coins = coins - 1000 WHERE userId = "${m.author.id.id}"');
                                    return;
                                }
                                k++;
                            }
                        }
                        m.reply({content: 'Такого товара нет'});
                    } else {
                        m.reply({content: 'у тебя не хватает монет'});
                    }
                case 3:
                    var roleName = w.shift();
                    if (roleName == null) {
                        var embed:Embed = {
                            author: {name: 'Купить уникальную цветную роль'},
                            description: 'Стоимость 50000<:rgd_coin_rgd:745172019619823657>\nДля покупки укажите номер товара и имя(1 словом) для роли и цвет в формате HEX(без #)',
                            fields: [{name: 'Пример', value: '${Rgd.prefix}shop 3 КрутаяРоль ff9900'}],
                            color: 0xff9900,
                        }
                        m.reply({embed: embed});
                        return;
                    }
                    if (has >= 50000) {
                        var roleCol = w.shift();

                        if (roleCol == null) {
                            m.reply({content: 'не указан цвет'});
                            return;
                        }

                        var roleColHex = Std.parseInt('0x'+roleCol);
                        
                        if (roleColHex == null){
                            m.reply({content: 'неверно указан цвет'});
                            return;
                        }

                        m.getGuild().createRole({name: roleName, color: roleColHex, mentionable: false, hoist: false},
                            (role, err) -> {
                                if (err != null) {
                                    trace(err);
                                    m.reply({content: 'что-то пошло не так'});
                                    return;
                                }
                                m.getMember().addRole(role.id.id);
                                m.reply({embed: {description: '<@${m.author.id.id}> куплена и создана роль <@&${role.id.id}>'}});
                                Rgd.db.request('UPDATE users SET coins = coins - 50000 WHERE userId = "${m.author.id.id}"');
                            }
                        );
                    } else {
                        m.reply({content: 'у тебя не хватает монет'});
                    }
                    
            }
        }

    }

}