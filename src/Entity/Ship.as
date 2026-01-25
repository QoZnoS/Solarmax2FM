package Entity {
    import Game.GameScene;
    import Entity.GameEntity;
    import starling.display.Image;
    import utils.Rng;
    import utils.GS;
    import starling.display.QuadBatch;
    import UI.UIContainer;
    import utils.CalcTools;
    import UI.LayerFactory;

    public class Ship extends GameEntity {
        // #region 类变量
        public var x:Number; // 坐标x
        public var y:Number; // 坐标y
        public var tx:Number; // 坐标x的偏移量
        public var ty:Number; // 坐标y的偏移量
        public var node:Node; // 所属天体
        public var preNode:Node; // 上一个所属天体
        public var team:int; // 势力
        public var image:Image; // 贴图
        public var trail:Image; // 拖尾
        public var pulse:Image; // 光圈
        public var orbitDist:Number; // 绕天体轨道大小
        public var orbitAngle:Number; // 绕天体轨道角度
        public var orbitSpeed:Number; // 绕天体旋转速度
        public var jumpSpeed:Number; // 移动速度
        public var chargeRate:Number; // 制动速度
        public var jumpDist:Number; // 本次飞行走过的距离
        public var jumpAngle:Number; // 移动方向
        public var trailLength:Number; // 拖尾长度
        public var hp:Number; // 血量
        public var warping:Boolean; // 是否在传送
        public var foreground:Boolean; // 决定与天体贴图的图层关系
        public var state:int; // 状态数
        public var targetDist:Number; // 到目标的距离
        public var followShip:Ship; // 跟随的飞船

        public var rng:Rng;

        public var currentBatch:QuadBatch;
        public var prevForeground:Boolean;

        private var frame:int;

        // #endregion
        public function Ship() {
            super();
            state = 0;
            image = new Image(Root.assets.getTexture("ship"));
            image.pivotX = image.pivotY = image.width * 0.5;
            trail = new Image(Root.assets.getTexture("quad8x4"));
            trail.pivotX = trail.width;
            trail.pivotY = trail.height * 0.5;
            trail.adjustVertices();
            trail.setVertexAlpha(0, 0);
            trail.setVertexAlpha(2, 0);
            pulse = new Image(Root.assets.getTexture("ship_pulse"));
            pulse.pivotX = pulse.pivotY = pulse.width * 0.5;
        }

        public function initShip(gameScene:GameScene, rng:Rng, team:int, node:Node, productionEffect:Boolean = true):void {
            frame = 0;
            super.init(gameScene);
            this.team = team;
            this.node = node;
            this.preNode = node;
            this.rng = rng;
            node.ships[team].push(this);
            image.alpha = 1;
            image.color = Globals.teamColors[team];
            if (Globals.teamColorEnhance[team])
                image.color = CalcTools.scaleColorToMax(image.color);
            image.scaleX = image.scaleY = 1;
            trail.alpha = 0;
            trail.color = image.color;
            trail.scaleX = trail.scaleY = 1;
            trailLength = 2;
            pulse.color = image.color;
            pulse.alpha = 0;
            orbitDist = (40 + rng.nextNumber() * 40) * node.nodeData.size * 2;
            orbitAngle = rng.nextNumber() * Math.PI * 2;
            orbitSpeed = rng.nextNumber() * 0.15 + 0.05;
            x = node.nodeData.x + Math.cos(orbitAngle) * orbitDist;
            y = node.nodeData.y + Math.sin(orbitAngle) * orbitDist * 0.15;
            trailLength = 2;
            resetChargeRate();
            jumpDist = 0;
            jumpSpeed = Globals.teamShipSpeeds[team];
            hp = 100;
            state = 0; // 状态数
            // 生产飞船时的动画
            if (productionEffect) {
                image.alpha = 0;
                pulse.alpha = 1;
                pulse.visible = true;
                pulse.scaleX = pulse.scaleY = 1;
            }
            if (orbitAngle > 0 && orbitAngle < Math.PI)
                foreground = true;
            else
                foreground = false;
        }

        override public function deInit():void {
            state = 0;
            warping = false;
            followShip = null;
        }

        // #region 更新
        override public function update(dt:Number):void // 更新
        {
            frame++;
            switch (state) // 按状态决定更新方式
            {
                case 0: // 在天体上
                    updateOrbit(dt); // 围绕天体旋转
                    break;
                case 1: // 接收到起飞命令，进入制动阶段（受制动速度影响，拉伸贴图至原长6倍）
                    updatePreJump1(dt);
                    break;
                case 2: // 制动结束，进入起飞阶段（不受制动速度影响，压缩贴图至原长2倍）
                    updatePreJump2(dt); // 若为传送门则跳过状态3
                    break;
                case 3: // 起飞后，保持贴图2倍拉伸飞向目标天体
                    updateJump(dt);
                    break;
                case 4: // 航母产生的跟随飞船
                    updateFollow(dt);
                    break;
            }
            if (!node.active)
                moveTo(closestNode()); // 飞船所属天体消失时自动飞向最近的天体（不含障碍，存在随机数
        }

        // 围绕天体旋转
        private function updateOrbit(dt:Number):void {
            // 生产飞船时的动画
            if (image.alpha < 1 || pulse.scaleX > 0) {
                image.alpha += dt;
                pulse.alpha = image.alpha * 0.5;
                pulse.scaleX = pulse.scaleY = 1 - image.alpha;
                if (image.alpha >= 1) {
                    image.alpha = 1;
                    pulse.alpha = 0;
                }
            }
            // 着陆时恢复贴图缩放
            if (image.scaleX > 1) {
                image.scaleX = Math.max(1, image.scaleX - dt * 2);
                image.scaleY = image.scaleX;
            }
            // 着陆时减少拖尾长度和不透明度
            if (trail.alpha > 0) {
                trail.alpha -= dt * 0.5;
                trail.rotation = 0;
                trailLength -= dt * 120;
                if (trail.alpha <= 0 || trailLength <= 1) {
                    trail.alpha = 0;
                    trailLength = 1;
                }
                trail.width = trailLength;
                trail.rotation = jumpAngle;
                updateForeground()
                drawTrail();
            }
            if (!node.conflict && !node.capturing)
                hp = Math.min(100, hp + dt * 50);
            orbitAngle += orbitSpeed * dt;
            orbitAngle %= Math.PI * 2
            x = node.nodeData.x + Math.cos(orbitAngle) * orbitDist;
            y = node.nodeData.y + Math.sin(orbitAngle) * orbitDist * 0.15;
            updateForeground()
            drawImage();
            if (pulse.alpha > 0)
                drawPulse();
        }

        // 制动飞船
        private function updatePreJump1(dt:Number):void {
            image.rotation = 0;
            image.scaleX += dt * chargeRate;
            if (image.scaleX > 6) {
                image.scaleX = 6;
                state = 2;
            }
            image.scaleY = 1 - image.scaleX / 6 * 0.25;
            image.rotation = jumpAngle;
            if (orbitAngle > 0 && orbitAngle < Math.PI)
                foreground = true;
            else
                foreground = false;
            drawImage();
        }

        // 准备起飞
        private function updatePreJump2(dt:Number):void {
            var foreground:Boolean = false;
            image.rotation = 0;
            image.scaleX = Math.max(2, image.scaleX - dt * 40);
            image.scaleY = 1 - image.scaleX / 6 * 0.25;
            if (image.scaleX == 2) {
                image.scaleY = 0.5;
                if (warping) {
                    foreground = false;
                    if (orbitAngle > 0 && orbitAngle < Math.PI)
                        foreground = true;
                    FXHandler.addWarp(x, y, tx, ty, Globals.teamColors[team], foreground);
                    x = tx;
                    y = ty;
                    node.ships[team].push(this);
                    if (node.aiTimers[team] < 0.1)
                        node.aiTimers[team] = 0.1;
                    node.basicState.warps[team] = true;
                    state = 0;
                    GS.playWarp(this.x);
                } else {
                    state = 3;
                    GS.playJumpStart(this.x);
                }
            }
            image.rotation = jumpAngle;
            drawImage();
        }

        // 飞行状态下的更新
        private function updateJump(dt:Number):void {
            var x1:Number = NaN;
            var y1:Number = NaN;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var angle:Number = NaN;
            var distance:Number = NaN;
            var dtime:Number = NaN;
            var dAngle:Number = NaN;
            var x2:Number = NaN;
            var y2:Number = NaN;
            jumpSpeed += dt * Globals.teamShipSpeeds[team] / 12.5;
            if (node.moveState.orbitNode) {
                x1 = Math.cos(orbitAngle) * orbitDist;
                y1 = Math.sin(orbitAngle) * orbitDist;
                tx = node.nodeData.x + x1;
                ty = node.nodeData.y + y1 * 0.15;
                dx = tx - x;
                dy = ty - y;
                angle = Math.atan2(dy, dx);
                dtime = (distance = Math.sqrt(dx * dx + dy * dy)) / jumpSpeed;
                dAngle = node.moveState.orbitAngle + node.moveState.orbitSpeed * dtime;
                if (dAngle > Math.PI * 2)
                    dAngle -= Math.PI * 2;
                x2 = node.moveState.orbitNode.nodeData.x + Math.cos(dAngle) * node.moveState.orbitDist;
                y2 = node.moveState.orbitNode.nodeData.y + Math.sin(dAngle) * node.moveState.orbitDist;
                tx = x2 + x1;
                ty = y2 + y1 * 0.15;
                dx = tx - x;
                dy = ty - y;
                dtime = (distance = Math.sqrt(dx * dx + dy * dy)) / jumpSpeed;
                dAngle = node.moveState.orbitAngle + node.moveState.orbitSpeed * dtime;
                if (dAngle > Math.PI * 2)
                    dAngle -= Math.PI * 2;
                x2 = node.moveState.orbitNode.nodeData.x + Math.cos(dAngle) * node.moveState.orbitDist;
                y2 = node.moveState.orbitNode.nodeData.y + Math.sin(dAngle) * node.moveState.orbitDist;
                tx = x2 + x1;
                ty = y2 + y1 * 0.15;
                dx = tx - x;
                dy = ty - y;
                distance = Math.sqrt(dx * dx + dy * dy);
                targetDist = distance;
                angle = Math.atan2(dy, dx);
            } else if (Globals.isApril_Fools) {
                x1 = Math.cos(orbitAngle) * orbitDist;
                y1 = Math.sin(orbitAngle) * orbitDist;
                tx = node.nodeData.x + x1;
                ty = node.nodeData.y + y1 * 0.15;
                dx = tx - x;
                dy = ty - y;
                jumpAngle = angle = Math.atan2(dy, dx);
                targetDist = distance = dx * dx + dy * dy;
            } else {
                targetDist -= jumpSpeed * dt;
                distance = targetDist;
                angle = jumpAngle;
            }
            if (distance > jumpSpeed * dt) {
                x += Math.cos(angle) * jumpSpeed * dt;
                y += Math.sin(angle) * jumpSpeed * dt;
                jumpAngle = angle;
            } else {
                x1 = Math.cos(orbitAngle) * orbitDist;
                y1 = Math.sin(orbitAngle) * orbitDist;
                tx = node.nodeData.x + x1;
                ty = node.nodeData.y + y1 * 0.15;
                x = tx;
                y = ty;
                node.ships[team].push(this);
                if (node.aiTimers[team] < 0.1)
                    node.aiTimers[team] = 0.1;
                state = 0;
                GS.playJumpEnd(this.x);
            }
            jumpDist += jumpSpeed * dt;
            trail.rotation = 0;
            trailLength = 16 * (jumpSpeed / 50 - 0.5);
            if (trailLength > 75)
                trailLength = 4 * (jumpSpeed / 50 + 13.5625);
            trailLength = Math.min(trailLength, targetDist);
            trail.width = trailLength;
            trail.rotation = jumpAngle;
            image.rotation = jumpAngle;
            trail.visible = true;
            updateForeground()
            drawImage();
            drawTrail();
        }

        // 跟随飞船
        private function updateFollow(dt:Number):void {
            if (trail.alpha < 1)
                trail.alpha += dt * 2;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var angle:Number = NaN;
            var moved:Number;
            if (followShip.active && !followShip.warping) {
                dx = followShip.x - x;
                dy = followShip.y - y;
                distance = dx * dx + dy * dy;
                angle = Math.atan2(dy, dx);
                moved = followShip.jumpSpeed * 5 * dt;
                if (distance < moved * moved) {
                    dx = node.nodeData.x + Math.cos(orbitAngle) * orbitDist - x;
                    dy = node.nodeData.y + Math.sin(orbitAngle) * orbitDist * 0.15 - y;
                    jumpAngle = Math.atan2(dy, dx);
                    jumpSpeed = followShip.jumpSpeed;
                    targetDist = Math.sqrt(dx * dx + dy * dy);
                    state = 3;
                    followShip = null;
                } else {
                    x += Math.cos(angle) * moved;
                    y += Math.sin(angle) * moved;
                    jumpSpeed = followShip.jumpSpeed;
                    jumpAngle = angle;
                }
            } else {
                dx = node.nodeData.x + Math.cos(orbitAngle) * orbitDist - x;
                dy = node.nodeData.y + Math.sin(orbitAngle) * orbitDist * 0.15 - y;
                distance = dx * dx + dy * dy;
                jumpAngle = Math.atan2(dy, dx);
                state = 3;
                followShip = null;
                jumpSpeed = Globals.teamShipSpeeds[team];
                targetDist = Math.sqrt(distance);
            }
            image.scaleX = Math.max(2, image.scaleX - dt * 100);
            image.scaleY = 1 - image.scaleX / 6 * 0.25;
            trailLength = 16 * (jumpSpeed / 50 - 0.5);
            if (trailLength > 75)
                trailLength = 4 * (jumpSpeed / 50 + 13.5625);
            trailLength = Math.min(trailLength, targetDist);
            trail.width = trailLength;
            trail.rotation = jumpAngle;
            image.rotation = jumpAngle;
            drawImage();
            drawTrail();
        }

        // 重置制动速度
        private function resetChargeRate():void {
            chargeRate = rng.nextNumber() * 6 + 6;
        }

        // #endregion
        // #region 绘制贴图
        private function updateForeground():void {
            if (orbitAngle > 0 && orbitAngle < Math.PI)
                foreground = true;
            else
                foreground = false;
        }

        private function updateImage():void {
            image.x = x;
            image.y = y;
        }

        // 绘制贴图
        private function drawImage():void {
            //  if (Globals.exOptimization > 1)
            //     if (node.ships[team].length > 1024)
            //        if (rng.nextNumber() > 1024/game.ships.active.length)
            //           return;
            image.x = x;
            image.y = y;
            LayerFactory.call(LayerFactory.ADD_IMAGE)(image, foreground, Globals.teamDeepColors[team])
        }

        // 绘制拖尾
        private function drawTrail():void {
            if (Globals.exOptimization > 0)
                return;
            trail.x = x;
            trail.y = y;
            LayerFactory.call(LayerFactory.ADD_IMAGE)(trail, foreground, Globals.teamDeepColors[team])
        }

        // 绘制光圈
        private function drawPulse():void {
            if (Globals.exOptimization > 0)
                return;
            pulse.x = x;
            pulse.y = y;
            LayerFactory.call(LayerFactory.ADD_IMAGE)(pulse, foreground, Globals.teamDeepColors[team])
        }

        // #endregion
        // #region 其他功能性函数 
        // 跟随另一艘飞船
        public function followTo(ship:Ship):void {
            this.followShip = ship;
            this.jumpSpeed = ship.jumpSpeed;
            this.preNode = this.node;
            this.node = ship.node;
            this.hp = ship.hp;
            this.state = 4;
            GS.playJumpCharge(this.x);
        }

        // 移动至参数node指定天体
        public function moveTo(node:Node, capture:Boolean = false):void {
            var dtime:Number = NaN;
            var dAngle:Number = NaN;
            var x2:Number = NaN;
            var y2:Number = NaN;
            var x1:Number = NaN;
            var y1:Number = NaN;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number;
            jumpSpeed = Globals.teamShipSpeeds[team];
            this.preNode = this.node;
            this.node = node;
            orbitDist = (40 + rng.nextNumber() * 40) * node.nodeData.size * 2;
            orbitSpeed = rng.nextNumber() * 0.15 + 0.05;
            x1 = Math.cos(orbitAngle) * orbitDist;
            y1 = Math.sin(orbitAngle) * orbitDist;
            tx = node.nodeData.x + x1;
            ty = node.nodeData.y + y1 * 0.15;
            dx = tx - x;
            dy = ty - y;
            jumpAngle = Math.atan2(dy, dx);
            targetDist = distance = Math.sqrt(dx * dx + dy * dy);
            if (node.moveState.orbitNode) {
                dtime = distance / jumpSpeed;
                dAngle = node.moveState.orbitAngle + node.moveState.orbitSpeed * dtime;
                if (dAngle > Math.PI * 2)
                    dAngle -= Math.PI * 2;
                x2 = node.moveState.orbitNode.nodeData.x + Math.cos(dAngle) * node.moveState.orbitDist;
                y2 = node.moveState.orbitNode.nodeData.y + Math.sin(dAngle) * node.moveState.orbitDist;
                tx = x2 + x1;
                ty = y2 + y1 * 0.15;
                dx = tx - x;
                dy = ty - y;
                dtime = (distance = Math.sqrt(dx * dx + dy * dy)) / jumpSpeed;
                dAngle = node.moveState.orbitAngle + node.moveState.orbitSpeed * dtime;
                if (dAngle > Math.PI * 2)
                    dAngle -= Math.PI * 2;
                x2 = node.moveState.orbitNode.nodeData.x + Math.cos(dAngle) * node.moveState.orbitDist;
                y2 = node.moveState.orbitNode.nodeData.y + Math.sin(dAngle) * node.moveState.orbitDist;
                tx = x2 + x1;
                ty = y2 + y1 * 0.15;
                dx = tx - x;
                dy = ty - y;
                distance = Math.sqrt(dx * dx + dy * dy);
                jumpAngle = Math.atan2(dy, dx);
                targetDist = distance;
            }
            trail.rotation = 0;
            trailLength = 1;
            trail.width = trailLength;
            trail.alpha = 0.5;
            jumpDist = 0;
            if (state == 0) {
                image.scaleY = 1;
                image.scaleX = 1;
                resetChargeRate();
            }
            image.alpha = 1;
            state = 1;
            warping = false;
            if (!capture)
                GS.playJumpCharge(this.x);
        }

        // 传送至参数node指定天体
        public function warpTo(node:Node):void {
            this.preNode = this.node;
            this.node = node;
            orbitDist = (40 + rng.nextNumber() * 40) * node.nodeData.size * 2;
            orbitSpeed = rng.nextNumber() * 0.15 + 0.05;
            var _x:Number = Math.cos(orbitAngle) * orbitDist;
            var _y:Number = Math.sin(orbitAngle) * orbitDist;
            tx = node.nodeData.x + _x;
            ty = node.nodeData.y + _y * 0.15;
            var dx:Number = tx - x;
            var dy:Number = ty - y;
            jumpAngle = Math.atan2(dy, dx);
            trail.rotation = 0;
            trailLength = 1;
            trail.width = trailLength;
            trail.alpha = 0.5;
            jumpDist = 0;
            if (state == 0) {
                image.scaleY = 1;
                image.scaleX = 1;
                chargeRate = 6;
            }
            image.alpha = 1;
            state = 1;
            warping = true;
            GS.playJumpCharge(this.x);
        }

        /**改变飞船势力
         * 不建议使用
         * @param team
         */
        public function changeTeam(team:int):void {
            this.team = team;
            if (node.ships[team].indexOf(this) == -1)
                node.ships[team].push(this);
            image.color = Globals.teamColors[team];
            trail.color = image.color;
            pulse.color = image.color;
        }

        // 计算最近的天体（不含障碍，存在随机数
        public function closestNode():Node {
            var closestNode:Node = null;
            var dx:Number = NaN;
            var dy:Number = NaN;
            var distance:Number = NaN;
            var closestDist:Number = 99999;
            for each (var node:Node in EntityContainer.nodes) {
                if (!node.active)
                    continue;
                if (node.nodeData.isUntouchable)
                    continue;
                // 计算距离，结果带有0~32px的随机误差
                dx = node.nodeData.x - this.x;
                dy = node.nodeData.y - this.y;
                distance = Math.sqrt(dx * dx + dy * dy) + rng.nextNumber() * 32;
                if (distance < closestDist) {
                    closestDist = distance;
                    closestNode = node;
                }
            }
            return closestNode;
        }
        // #endregion
    }
}
