// 建议先通读一遍SimpleAI了解一下ai的基本运作方式
// 天体标准兵力特指100*size

package Entity {
    import Game.GameScene;
    import Entity.GameEntity;
    import utils.Rng;
    import Entity.AI.IEnemyAI;
    import Entity.AI.EnemyAIFactory;

    public class EnemyAI extends GameEntity {

        public var debugTrace:Array; // 调试输出栏
        public var ai:IEnemyAI;

        public function EnemyAI() { // 初始化ai参数
            super();
            debugTrace = [null, null, null, null, null];
        }

        public function initAI(_GameScene:GameScene, rng:Rng, team:int, type:String, actionDelay:Number = -1, startDelay:Number = -1):void {
            this.init(_GameScene);
            ai = EnemyAIFactory.create(type, rng, actionDelay, startDelay);
            ai.team = team;
        }

        override public function deInit():void {
            ai = null;
        }

        override public function update(dt:Number):void {
            ai.update(dt)
        }

        // #endregion
        // #region 调试工具
        public function traceDebug(_text:String):void {
            debugTrace.unshift(_text);
            debugTrace.pop();
        }
        // #endregion

        public function get team():int {
            return ai.team;
        }
    }
}
