package MapEditor
{
    /** 数据结构，纯结构类 */
    public class Data{
        public var name:String;
        public var icon:String;
        public var describe:Array;
        public var team:Array;
        public var level:Array;

        public function Data(){
            team = defaultTeam();
            level = [];
            describe = [];
            icon = "icon192";
        }

        public function addLevel():Level{
            var lvl:Level = new Level()
            level.push(lvl)
            lvl.id = level.length
            lvl.name = String(lvl.id)
            lvl.node = []
            return lvl
        }

        public function addTeam():Team{
            var team:Team = newTeam();
            team.id = this.team.length;
            this.team.push(team);
            return team;
        }

        public static function defaultTeam():Array{
            const color:Array = [0xCCCCCC, 0x5FB6FF, 0xFF5D93, 0xFF8C5A, 0xCAFF6E, 0x999999, 0x000000]
            var result:Array = [];
            var team:Team;
            for (var i:int = 0;i < color.length;i++){
                team = newTeam();
                team.id = i;
                team.color = color[i];
                if (i == 6)
                    team.shipSpeed = 100;
                result.push(team)
            }
            return result
        }

        public static function newTeam():Team{
            var team:Team = new Team();
            team.id = 0;
            team.color = 0x000000;
            team.shipSpeed = 50;
            team.shipAttack = 1; 
            team.shipDefence = 1; 
            team.repairingSpeed = 1; 
            team.colonizingSpeed = 1; 
            team.destroyingSpeed = 1; 
            team.decolonizingSpeed = 1; 
            team.constructionStrength = 1; 
            team.nodeBuild = 1; 
            team.nodePop = 1; 
            return team;
        }
    }
}
/** 关卡 */
internal class Level{
    public var id:int;
    public var name:String;
    public var color:uint;
    public var node:Array;
}
/** 天体 */
internal class Node{
    public var tag:int;
    public var x:Number;
    public var y:Number;
    public var type:String;
    public var size:Number;
    public var team:int;
}
/** 势力 */
internal class Team{
    public var id:int;
    public var color:uint;
    public var shipSpeed:Number;
    public var shipAttack:Number;
    public var shipDefence:Number;
    public var repairingSpeed:Number;
    public var colonizingSpeed:Number;
    public var destroyingSpeed:Number;
    public var decolonizingSpeed:Number;
    public var constructionStrength:Number;
    public var nodeBuild:Number;
    public var nodePop:Number;
}