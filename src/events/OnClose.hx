package events;

import haxe.rtti.Meta;

class OnClose {
    public static function onClose(i:Int) {
        OnVoiceStateUpdate.saveTime();

        var classList = CompileTime.getAllClasses("commands");
        for (_class in classList) {
            var statics = Meta.getStatics(_class);

            for(s in Reflect.fields(statics)) {
                if (s == "down") {
                    Reflect.callMethod(_class, Reflect.field(_class,s),[]);
                    continue;
                }
            }
        }

        Sys.exit(0);
    }
}