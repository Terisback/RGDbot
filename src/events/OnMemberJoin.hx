package events;


import com.raidandfade.haxicord.types.GuildMember;
import com.raidandfade.haxicord.types.Guild;

class OnMemberJoin {
    public static function onMemberJoin(g:Guild, m:GuildMember) {
        if (g.id.id != Rgd.rgdId) return;

        var roles = Rgd.db.request('SELECT roleId FROM usersRole WHERE userId = "${m.user.id.id}"');
        for (role in roles) 
            m.addRole(role.roleId);
        
        Rgd.db.request('INSERT OR IGNORE INTO users(userId, first, here) VALUES("${m.user.id.id}", "${m.joined_at.toString()}", 1)');
        Rgd.db.request('UPDATE users SET here = 1 WHERE userId = "${m.user.id.id}"');
    }
}