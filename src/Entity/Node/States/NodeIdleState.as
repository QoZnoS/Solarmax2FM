package Entity.Node.States {
    import Entity.Node;

    public class NodeIdleState implements INodeState {
        public function NodeIdleState() {

        }

        public function update(node:Node, dt:Number):void {
        }

        public function checkStart(node:Node):void
        {
        	throw new Error("Method not implemented.");
        }

        public function checkEnd(node:Node):void
        {
        	throw new Error("Method not implemented.");
        }

        public function toJSON(k:String):*
        {
        	throw new Error("Method not implemented.");
        }

        public function get stateType():String {
            return NodeStateFactory.IDLE;
        }

        public function get enable():Boolean
        {
        	throw new Error("Method not implemented.");
        }
    }
}
