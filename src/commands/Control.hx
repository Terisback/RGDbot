package commands;

import com.raidandfade.haxicord.types.Message;

@admin
@desc('Control', 'Модуль с командами для контроля')
class Control {

    @admin
    @command(['статус', 'status'], 'установить статус боту', '>фраза для статуса')
    public static function setStatus(m:Message, w:Array<String>) {
        Rgd.bot.setStatus({
            afk: false,
            status: 'online',
            game: {
                type: 0,
                name: w.join(' '),
            }
        });
    }
    
}