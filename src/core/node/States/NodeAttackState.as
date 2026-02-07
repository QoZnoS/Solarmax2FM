package core.node.states {
    import core.entities.Node;
    import core.factories.AttackStrategyFactory;
    import core.factories.NodeStateFactory;
    import core.node.NodeData;
    import core.node.NodeType;
    import core.node.attacks.IAttackStrategy;

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

        public function get attackRange():Number {
            return attackStrategy.attackRange;
        }

        public function get attackRate():Number {
            return attackStrategy.attackRate;
        }

        public function deserialize(obj:Object):void {
            if ("attackType" in obj) {
                var type:String = obj.attackType;
                var attackRate:Number = NodeType.getDefaultAttackRate(type, nodeData.size);
                var attackRange:Number = NodeType.getDefaultAttackRange(type, nodeData.size);
                var attackLast:Number = NodeType.getDefaultAttackLast(type, nodeData.size);
                this.attackStrategy = AttackStrategyFactory.create(NodeType.getDefaultAttackType(type), attackRate, attackRange, attackLast);
            }
            if ("attackTimer" in obj)
                this.attackStrategy.attackTimer = obj.attackTimer;
            if ("attackRate" in obj)
                this.attackStrategy.attackRate = obj.attackRate;
            if ("attackRange" in obj)
                this.attackStrategy.attackRange = obj.attackRange;
            if ("attackLast" in obj)
                this.attackStrategy.attackLast = obj.attackLast;
        }
    }
}
