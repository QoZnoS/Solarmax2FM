package Entity.Node.States
{
    import Entity.Node;

    public class NodeIdleState implements INodeState
    {
        public function NodeIdleState()
        {
            
        }

        public function update(node:Node, dt:Number):void
        {
        	throw new Error("Method not implemented.");
        }

        public function checkEnter(node:Node):Boolean
        {
        	return true;
        }

        public function checkExit(node:Node):Boolean
        {
        	return true;
        }

        public function get stateType():String
        {
        	return NodeStateFactory.IDLE;
        }

    }
}