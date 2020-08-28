package commands;

import haxe.Timer;
import com.raidandfade.haxicord.types.structs.Embed;
import com.raidandfade.haxicord.types.Message;

@desc("Coin","Модуль работы с монетами")
class Coin {
    static var flips:Array<String> = new Array();

    @inbot
    @command(["флип", "flip"], "Бросить монетку на деньги или нет", "?деньги")
    public static function coin(m:Message, w:Array<String>) {
        if (flips.indexOf(m.author.id.id) >= 0) return;

        var coins:Int = Std.parseInt(w[0]);
        if (coins == null)
            coins = 0;

        coins = Math.round(Math.abs(coins));

        var balance = Rgd.db.request('SELECT coins FROM users WHERE userId = "${m.author.id.id}"').getIntResult(0);
        if (coins <= balance) {
            
            flips.push(m.author.id.id);

            var embed:Embed = {
                author: {
                    icon_url: m.author.avatarUrl,
                    name: '${m.getMember().displayName} подбросил монетку',
                },
                description: '**ПОДБРАСЫВАЕМ...**\n__Ставка:__ $coins <:rgd_coin_rgd:745172019619823657>\n__Баланс:__ $balance <:rgd_coin_rgd:745172019619823657>',
                thumbnail: {
                    url: 'https://cdn.discordapp.com/emojis/518875396545052682.gif?v=1'
                },
                color: 0xFF9900,
            }

            m.reply({embed: embed}, (msg, err) -> {
                var timer = new Timer(1000*3);
                timer.run = function () {
                    var win = Std.random(100) > 50 ? true : false;
                    if (!win)
                        coins *= -1;
                    Rgd.db.request('UPDATE users SET coins = coins + $coins WHERE userId = "${m.author.id.id}"');
                    
                    msg.edit({embed:{
                        author: {
                            icon_url: m.author.avatarUrl,
                            name: '${m.getMember().displayName} подбросил монетку',
                        },
                        description: '**${win ? 'ПОБЕДА!' : 'ПРОИГРЫШ'}**\n__Ставка:__ ${Math.abs(coins)} <:rgd_coin_rgd:745172019619823657>\n__Баланс:__ ${balance+coins} <:rgd_coin_rgd:745172019619823657>',
                        thumbnail: {
                            url: win ? "https://cdn.discordapp.com/emojis/518875768814829568.png?v=1" : "https://cdn.discordapp.com/emojis/518875812913610754.png?v=1"
                        },
                        color: 0xFF9900,
                    }});

                    flips.remove(m.author.id.id);
                    timer.stop();
                }
            });
        } else {
            m.reply({content: 'Извините, <@${m.author.id.id}>, но у вас недостаточно монет'});
        }
    }


    static var giftCd:Map<String, {timer: Timer, date:Date}> = new Map();
    
    @inbot
    @command(["подарок", "gift"], "Получить монет")
    public static function gift(m:Message, w:Array<String>) {

        if (giftCd.exists(m.author.id.id)) {
            var future = DateTools.delta(giftCd[m.author.id.id].date, 3 * 60 * 60 * 1000);
            var now = Date.now();
            var dif = future.getTime() - now.getTime();
            var r = DateTools.parse(dif);
            m.reply({content: 'Извините, <@${m.author.id.id}>, ваш подарок еще не доступен, попробуйте `через ${r.hours} часов ${r.minutes} минут`'});
            return;
        }

        var random = Std.random(16) + 5;

        Rgd.db.request('UPDATE users SET coins = coins + $random WHERE userId = "${m.author.id.id}"');
        m.reply({content: '<@${m.author.id.id}> получил из подарка `$random` монет'});

        var timer = new Timer(1000*60*60*3);
        timer.run = function () {
            giftCd.remove(m.author.id.id);
            timer.stop();
        }

        giftCd.set(m.author.id.id, {timer: timer, date: Date.now()});

    }

    @inbot
    @command(["give", "дать"], "дать часть своих монет",">кому >сколько")
    public static function give(m:Message, w:Array<String>) {
        if (m.mentions[0] == null ) {
            m.reply({content: 'Не указано кому выдать'});
            return;
        }
        if (m.mentions[0].id.id == m.author.id.id) {
            m.reply({content: 'Нельзя передать самому себе'});
            return;
        }
        var amount = Std.parseInt(w[1]);
        if (amount == null) {
            m.reply({content: 'Не указано число передачи'});
            return;
        }
        if (amount <= 0) {
            m.reply({content: 'Нельзя передавать такие числа'});
            return;
        }

        var has = Rgd.db.request('SELECT coins FROM users WHERE userId = "${m.author.id.id}"').getIntResult(0);
        if (has < amount) {
            m.reply({content: 'Недостаточно монет для передачи'});
            return;
        } 
        Rgd.db.request('UPDATE users SET coins = coins - $amount WHERE userId = "${m.author.id.id}"');
        Rgd.db.request('UPDATE users SET coins = coins + $amount WHERE userId = "${m.mentions[0].id.id}"');
        m.reply({content: '${m.author.tag} передал ${m.mentions[0].tag} `$amount` <:rgd_coin_rgd:745172019619823657>'});
    }

    @inbot
    @command(["монеты", "balance", "coins"], "Сколько монет у пользователя","?юзер/?топ")
    public static function balance(m:Message, w:Array<String>) {
        if (w[0] == 'топ' || w[0] == 'top') {

            var top = Rgd.db.request('SELECT userId,coins FROM users WHERE here = 1 ORDER BY coins DESC LIMIT 10');
            var c = '';
            var p = 1;

            for (pos in top) 
                c += '${p++}. <@${pos.userId}> :`${pos.coins}` \n';
            

            var embed:Embed = {
                author: {icon_url: 'https://cdn.discordapp.com/emojis/518875768814829568.png?v=1', name: 'Топ по монетам'},
                fields: [
                    {name: '**Никнейм**', value: c, _inline: true}, 
                ]
            }
            m.reply({embed: embed});
        } else {
            var who = m.mentions[0] == null ? m.author.id.id : m.mentions[0].id.id;
            var has = Rgd.db.request('SELECT coins FROM users WHERE userId = "${who}"').getIntResult(0);
            m.reply({content: 'У <@$who> `$has` монет<:rgd_coin_rgd:745172019619823657>'});
        }
    }

    @admin
    @command(["выдать", 'award'], "создать для пользователя монет(или отобрать)",">пингЮзера >сколькоМонет")
    public static function award(m:Message, w:Array<String>) {
        if (m.mentions[0] == null ) {
            m.reply({content: 'Не указано кому выдать'});
            return;
        }
        var amount = Std.parseInt(w[1]);
        if (amount == null) {
            m.reply({content: 'Не указано число передачи'});
            return;
        }

        Rgd.db.request('UPDATE users SET coins = coins + $amount WHERE userId = "${m.mentions[0].id.id}"');
        m.reply({content: 'Выдано ${m.mentions[0].tag} `$amount` <:rgd_coin_rgd:745172019619823657>'});
    }

}