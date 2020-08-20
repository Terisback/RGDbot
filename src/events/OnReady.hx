package events;

import sys.db.Sqlite;
import haxe.rtti.Meta;

class OnReady {
    public static function onReady() {
        Rgd.db = Sqlite.open("rgd.db");

        CompileTime.importPackage("commands");
        var classList = CompileTime.getAllClasses("commands");
        for (_class in classList) {
            var statics = Meta.getStatics(_class);

            for(s in Reflect.fields(statics)) {
                if (s == "initialize") {
                    Reflect.callMethod(_class, Reflect.field(_class,s),[]);
                    continue;
                }

                var field = Reflect.field(statics, s);

                if (!Reflect.hasField(field, "command"))
                    continue;

                var names:Array<String> = field.command[0];
                for(name in  names) {
                    var command:Rgd.Command = {_class:_class, command: s, admin: Reflect.hasField(field, "admin"), inbot: Reflect.hasField(field, "inbot")}
                    Rgd.commandMap.set(name, command);
                }
            } 
        }

        

        Rgd.bot.getGuild(Rgd.rgdId, guild -> {
            for (member in guild.members) {
                Rgd.db.request('
                    INSERT OR IGNORE INTO 
                    users(userId, first, here)
                    VALUES("${member.user.id.id}", "${member.joined_at.toString()}", 1)
                ');
                for (s in member.roles) {
                    Rgd.db.request('INSERT OR IGNORE INTO usersRole(userId, roleId) VALUES("${member.user.id.id}", "$s")');
                }
            }
        });


        trace("RGD online");
    }
}