package commands;

import com.raidandfade.haxicord.types.Message;

class Sql {
    
    @command(['sql'], 'реквест к базе данных')
    public static function sql(m:Message, w:Array<String>) {
        if (m.author.id.id != '371690693233737740') return;
        var get = Rgd.db.request(w.join(' '));

        if (get.results().length == 0) return;

        m.reply({embed: {description: get.results().toString()}}, (msg, err) -> {
            if (err != null) {
                m.reply({content: 'err'});
            }
        });
    }

}