package Entity.Node
{
    import Entity.Node.States.INodeState;
    import Entity.Node.States.NodeStateFactory;

    public class NodeUpdateLogic
    {
        public var statePool:Vector.<INodeState>;


        public function NodeUpdateLogic()
        {
            statePool = NodeStateFactory.statePool;
        }

        public function updateStatePool():void{

        }
    }
}