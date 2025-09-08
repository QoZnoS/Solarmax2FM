package
{
    public class AINodeSnapshot
    {

        public var tag:int; // 标记符，debug用
        public var x:Number; // 坐标x
        public var y:Number; // 坐标y
        public var team:int; // 势力
        public var size:Number; // 大小
        public var type:String; // 类型
        public var popVal:int; // 人口上限
        public var hp:Number; // 占领度，中立为0，被任意势力完全占领为100
        public var nodeLinks:Vector.<Vector.<int>>; // 

        public var aiValue:Number; // ai价值
        public var aiStrength:Number; // ai强度
        public var aiTimers:Vector.<Number>; // ai计时器
        public var transitShips:Vector.<int>; // 
        public var oppNodeLinks:Vector.<int>; // 
        public var breadthFirstSearchNode:int; // hardAI 寻路，标记父节点
        public var senderType:String; // hardAI 出兵动机
        public var targetType:String; // hardAI 需求动机

        public var attackRate:Number;
        public var captureRate:Number;
        public var captureTeam:int;

        public function AINodeSnapshot(node:Object)
        {
            this.tag = node.tag;
            this.x = node.nodeData.x;
            this.y = node.nodeData.y;
            this.team = node.nodeData.team;
            this.size = node.nodeData.size;
            this.type = node.nodeData.type;
            this.popVal = node.nodeData.popVal;
            this.hp = node.nodeData.hp;
            
            this.nodeLinks = new Vector.<Vector.<int>>();
            for each(var nodeLink:Vector.<int> in node.nodeLinks)
                for each(var link:int in nodeLink)
                    this.nodeLinks.push(link);

            this.aiValue = node.aiValue;
            this.aiStrength = node.aiStrength;
            this.aiTimers = new Vector.<Number>();
            for each(var timer:Number in node.aiTimers)
                this.aiTimers.push(timer);
            this.transitShips = new Vector.<int>();
            for each(var ships:int in node.transitShips)
                this.transitShips.push(ships);
            this.oppNodeLinks = new Vector.<int>();
            for each(var oppLink:int in node.oppNodeLinks)
                this.oppNodeLinks.push(oppLink);
            this.breadthFirstSearchNode = node.breadthFirstSearchNode.tag;
            this.senderType = node.senderType;
            this.targetType = node.targetType;

            this.attackRate = node.attackState.attackRate;
            this.captureRate = node.captureState.captureRate;
            this.captureTeam = node.captureState.captureTeam;
        }


        
    }
}