package Entity.Node.States {
    import Entity.Node;
    import Entity.Node.Attack.IAttackStrategy;
    import Entity.Node.NodeData;

    public class NodeAttackState implements INodeState {

        private var node:Node;
        private var nodeData:NodeData;
        public var attackStrategy:IAttackStrategy; // 攻击策略

        public function NodeAttackState(node:Node) {
            this.node = node;
        }

        public function init():void {
            this.nodeData = node.nodeData;
        }

        public function deinit():void {
        }

        public function update(dt:Number):void {
            attackStrategy.executeAttack(node, dt);
        }

        public function toJSON(k:String):* {
            throw new Error("Method not implemented.");
        }

        public function get enable():Boolean {
            return (nodeData.team != 0 && attackStrategy.attackType != "basic");
        }

        public function get stateType():String {
            return NodeStateFactory.ATTACK;
        }

        public function get attackRange():Number{
            return attackStrategy.attackRange;
        }

        public function get attackRate():Number{
            return attackStrategy.attackRate;
        }
    }
}
