package utils{
    import com.greensock.TweenLite;
    import flash.media.SoundChannel;
    import flash.media.SoundMixer;
    import flash.media.SoundTransform;
    import starling.core.Starling;
    /**全局音频控制类 */
    public class GS {
        private static var st:SoundTransform;
        private static var mt:SoundTransform;
        private static var timers:Array = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        private static var gap:Number = 0.1;
        private static var musicChannel:SoundChannel;
        private static var lastSong:String = "";
        private static var lastLoop:String = "";
        private static var lastPosition:Number = 0;
        private static var musicPaused:Boolean = false;

        public static function init():void {
            st = new SoundTransform(Globals.soundVolume);
            mt = new SoundTransform(Globals.musicVolume);
        }

        public static function update(_dt:Number):void {
            for (var i:int = 0; i < timers.length; i++) {
                var _timer:Number = timers[i];
                if (_timer > 0)
                    _timer = Math.max(0, _timer - _dt);
                timers[i] = _timer;
            }
        }

        public static function updateTransforms():void {
            st.volume = Globals.soundVolume;
            mt.volume = Globals.musicVolume;
            if (musicChannel)
                musicChannel.soundTransform = mt;
        }

        public static function playMusic(_name:String, _loop:Boolean = true):void {
            var prevChannel:SoundChannel;
            var transform:SoundTransform;
            var transform2:SoundTransform;
            var name:String = _name;
            var loop:Boolean = _loop;
            var loopVal:int = 0;
            if (loop)
                loopVal = 2147483647;
            if (name != lastSong) {
                if (musicChannel) {
                    prevChannel = musicChannel;
                    transform = new SoundTransform(Globals.musicVolume, 0);
                    Starling.juggler.tween(transform, 1, {"volume": 0,
                            "onUpdate": function():void
                            {
                                if (prevChannel)
                                    prevChannel.soundTransform = transform;
                            },
                            "onComplete": prevChannel.stop});
                }
                lastSong = name;
                transform2 = new SoundTransform(0, 0);
                musicChannel = Root.assets.playSound(name, 0, loopVal, transform2);
                if (musicChannel) {
                    Starling.juggler.tween(transform2, 0.5, {"volume": Globals.musicVolume,
                            "onUpdate": function():void
                            {
                                if (musicChannel)
                                    musicChannel.soundTransform = transform2;
                            }});
                }
            } else if (!musicChannel) {
                lastSong = name;
                transform2 = new SoundTransform(0, 0);
                musicChannel = Root.assets.playSound(name, 0, loopVal, transform2);
                Starling.juggler.tween(transform2, 0.5, {"volume": Globals.musicVolume,
                        "onUpdate": function():void
                        {
                            if (musicChannel)
                                musicChannel.soundTransform = transform2;
                        }});
            }
        }

        public static function fadeOutMusic(_time:Number):void {
            var transform:SoundTransform;
            var time:Number = _time;
            if (musicChannel) {
                transform = new SoundTransform(Globals.musicVolume, 0);
                Starling.juggler.tween(transform, time, {"volume": 0,
                        "onUpdate": function():void
                        {
                            if (musicChannel)
                                musicChannel.soundTransform = transform;
                        },
                        "onComplete": function():void
                        {
                            if (musicChannel)
                                musicChannel.stop();
                        }});
                lastSong = "";
            }
        }

        public static function pauseMusic():void {
            var prevChannel:SoundChannel;
            var transform:SoundTransform;
            if (musicChannel) {
                musicPaused = true;
                if (lastSong == "")
                    return;
                prevChannel = musicChannel;
                transform = new SoundTransform(Globals.musicVolume, 0);
                lastPosition = prevChannel.position;
                TweenLite.to(transform, 1, {"volume": 0,
                        "onUpdate": function():void
                        {
                            prevChannel.soundTransform = transform;
                        },
                        "onComplete": function():void
                        {
                            prevChannel.stop();
                            if (musicPaused)
                            {
                                SoundMixer.stopAll();
                            }
                        }});
            }
        }

        public static function resumeMusic():void {
            var loop:int;
            var startPos:Number;
            var transform:SoundTransform;
            musicPaused = false;
            if (lastSong == "")
                return;
            loop = 2147483647;
            startPos = 0;
            if (lastSong == "bgm07" || lastSong == "bgm_dark") {
                loop = 0;
                startPos = lastPosition;
            }
            transform = new SoundTransform(0, 0);
            musicChannel = Root.assets.playSound(lastSong, startPos, loop, transform);
            Starling.juggler.tween(transform, 0.5, {"volume": Globals.musicVolume,
                    "onUpdate": function():void
                    {
                        if (musicChannel)
                            musicChannel.soundTransform = transform;
                    }});
        }

        public static function playSound(_name:String, _volume:Number = 1, _pan:Number = 0):void {
            st.volume = _volume * Globals.soundVolume;
            if (st.volume == 0)
                return;
            st.pan = _pan;
            Root.assets.playSound(_name, 0, 0, st);
        }

        public static function playSoundLikeMusic(_name:String, _volume:Number = 1, _pan:Number = 0):void {
            st.volume = _volume * Globals.musicVolume;
            st.pan = _pan;
            Root.assets.playSound(_name, 0, 0, st);
        }

        public static function playClick():void {
            playSound("click", 0.75);
        }

        public static function playClickUp():void {
            playSound("click_up");
        }

        public static function playClickDown():void {
            playSound("click_down");
        }

        public static function playExplosion(_x:Number):void {
            if (timers[0] > 0)
                return;
            timers[0] = gap;
            playSound("explosion0" + Math.floor(Math.random() * 8).toString(), 1, (_x - 512) / 512);
        }

        public static function playJumpCharge(_x:Number):void {
            if (timers[1] > 0)
                return;
            timers[1] = gap;
            playSound("jumpCharge", 0.5, (_x - 512) / 512);
        }

        public static function playJumpStart(_x:Number):void {
            if (timers[2] > 0)
                return;
            timers[2] = gap;
            playSound("jumpStart", 0.5, (_x - 512) / 512);
        }

        public static function playJumpEnd(_x:Number):void {
            if (timers[3] > 0)
                return;
            timers[3] = gap;
            playSound("jumpEnd", 0.5, (_x - 512) / 512);
        }

        public static function playLaser(_x:Number):void {
            if (timers[4] > 0)
                return;
            timers[4] = gap;
            playSound("laser", 1, (_x - 512) / 512);
        }

        public static function playCapture(_x:Number):void {
            if (timers[5] > 0)
                return;
            timers[5] = 0.05;
            playSound("capture", 1, (_x - 512) / 512);
        }

        public static function playWarp(_x:Number):void {
            if (timers[6] > 0)
                return;
            timers[6] = gap;
            playSound("warp", 0.6, (_x - 512) / 512);
        }

        public static function playWarpCharge(_x:Number):void {
            if (timers[7] > 0)
                return;
            timers[7] = gap;
            playSound("warp_charge", 0.6, (_x - 512) / 512);
        }
    }
}
