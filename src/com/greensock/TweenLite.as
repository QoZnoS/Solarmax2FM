/* 参考文件信息
 * VERSION: 12.1.5
 * DATE: 2014-07-19
 * AS3 (AS2 version is also available)
 * UPDATES AND DOCS AT: http://www.greensock.com
 * 忽略了原文件大段注释，只保留了带 @ 字段的短注释
 * 函数内部的注释还请参照原文件
 */
package com.greensock
{
   import com.greensock.core.Animation;
   import com.greensock.core.PropTween;
   import com.greensock.core.SimpleTimeline;
   import com.greensock.easing.Ease;
   import flash.display.Shape;
   import flash.events.Event;
   import flash.utils.Dictionary;
   
   public class TweenLite extends Animation
   {
      /** @private **/
      public static const version:String = "12.1.4"; // 参考版本 12.1.5

      /** Provides An easy way to change the default easing equation. Choose from any of the GreenSock eases in the <code>com.greensock.easing</code> package. @default Power1.easeOut **/
      public static var defaultEase:Ease = new Ease(null,null,1,1);

		/** Provides An easy way to change the default overwrite mode. Choose from any of the following: <code>"auto", "all", "none", "allOnStart", "concurrent", "preexisting"</code>. @default "auto" **/
      public static var defaultOverwrite:String = "auto";

      public static var ticker:Shape = Animation.ticker;

		/** @private When plugins are activated, the class is added (named based on the special property) to this object so that we can quickly look it up in the <code>_initProps()</code> method.**/
      public static var _plugins:Object = {};

		/** @private For notifying plugins of significant events like when the tween finishes initializing or when it is disabled/enabled (some plugins need to take actions when those events occur). TweenPlugin sets this (in order to keep file size small, avoiding dependencies on that or other classes) **/
      public static var _onPluginEvent:Function;

		/** @private Holds references to all our tween instances organized by target for quick lookups (for overwriting). **/
      protected static var _tweenLookup:Dictionary = new Dictionary(false);
      
		/** @private Lookup for all of the reserved "special property" keywords (excluding plugins).**/
      protected static var _reservedProps:Object = {
         "ease":1,
         "delay":1,
         "overwrite":1,
         "onComplete":1,
         "onCompleteParams":1,
         "onCompleteScope":1,
         "useFrames":1,
         "runBackwards":1,
         "startAt":1,
         "onUpdate":1,
         "onUpdateParams":1,
         "onUpdateScope":1,
         "onStart":1,
         "onStartParams":1,
         "onStartScope":1,
         "onReverseComplete":1,
         "onReverseCompleteParams":1,
         "onReverseCompleteScope":1,
         "onRepeat":1,
         "onRepeatParams":1,
         "onRepeatScope":1,
         "easeParams":1,
         "yoyo":1,
         "onCompleteListener":1,
         "onUpdateListener":1,
         "onStartListener":1,
         "onReverseCompleteListener":1,
         "onRepeatListener":1,
         "orientToBezier":1,
         "immediateRender":1,
         "repeat":1,
         "repeatDelay":1,
         "data":1,
         "paused":1,
         "reversed":1
      };
       
		/** @private An object for associating String overwrite modes with their corresponding integers (faster) **/
      protected static var _overwriteLookup:Object;
      

		/** [READ-ONLY] Target object (or array of objects) whose properties the tween affects. **/
      public var target:Object;

		/** @private The result of feeding the tween's current progress (0-1) into the easing equation - typically between 0 and 1 but not always (like with <code>ElasticOut.ease</code>). **/
      public var ratio:Number;

		/** @private Lookup object for PropTween objects. For example, if this tween is handling the "x" and "y" properties of the target, the _propLookup object will have an "x" and "y" property, each pointing to the associated PropTween object (for tweens with targets that are arrays, _propTween will be an Array with corresponding objects). This can be very helpful for speeding up overwriting. **/
      public var _propLookup:Object;

		/** @private First PropTween instance in the linked list. **/
      public var _firstPT:PropTween;

		/** @private Only used for tweens whose target is an array. **/
      protected var _targets:Array;
      		
      /** @private Ease to use which determines the rate of change during the animation. Examples are <code>ElasticOut.ease</code>, <code>StrongIn.ease</code>, etc. (all in the <code>com.greensock.easing package</code>) **/
      public var _ease:Ease;
      
		/** @private To speed the handling of the ease, we store the type here (1 = easeOut, 2 = easeIn, 3 = easeInOut, and 0 = none of these) **/
      protected var _easeType:int;

		/** @private To speed handling of the ease, we store its strength here (Linear is 0, Quad is 1, Cubic is 2, Quart is 3, Quint (and Strong) is 4, etc.) **/
      protected var _easePower:int;

		/** @private The array that stores the tweens of the same target (or targets) for the purpose of speeding overwrites. **/
      protected var _siblings:Array;

		/** @private Overwrite mode (0 = none, 1 = all, 2 = auto, 3 = concurrent, 4 = allOnStart, 5 = preexisting) **/
      protected var _overwrite:int;
      
		/** @private When properties are overwritten in this tween, the properties get added to this object because sometimes properties are overwritten <strong>BEFORE</strong> the tween inits. **/
      protected var _overwrittenProps:Object;
      
		/** @private If this tween has any TweenPlugins that need to be notified of a change in the "enabled" status, this will be true. (speeds things up in the _enable() setter) **/
      protected var _notifyPluginsOfEnabled:Boolean;
      
		/** @private Only used in tweens where a startAt is defined (like fromTo() tweens) so that we can record the pre-tween starting values and revert to them properly if/when the playhead on the timeline moves backwards, before this tween started. In other words, if alpha is at 1 and then someone does a fromTo() tween that makes it go from 0 to 1 and then the playhead moves BEFORE that tween, alpha should jump back to 1 instead of reverting to 0. **/
      protected var _startAt:TweenLite;
      

		/**
		 * Constructor
		 *  
		 * @param target Target object (or array of objects) whose properties this tween affects 
		 * @param duration Duration in seconds (or frames if <code>useFrames:true</code> is set in the <code>vars</code> parameter)
		 * @param vars An object defining the end value for each property that should be tweened as well as any special properties like <code>onComplete</code>, <code>ease</code>, etc. For example, to tween <code>mc.x</code> to 100 and <code>mc.y</code> to 200 and then call <code>myFunction</code>, do this: <code>new TweenLite(mc, 1, {x:100, y:200, onComplete:myFunction})</code>.
		 */
      public function TweenLite(target:Object, duration:Number, vars:Object)
      {
         super(duration,vars);

         if(target == null)
            throw new Error("Cannot tween a null object. Duration: " + duration + ", data: " + this.data);
         if(!_overwriteLookup)
         {
            _overwriteLookup = {
               "none":0,
               "all":1,
               "auto":2,
               "concurrent":3,
               "allOnStart":4,
               "preexisting":5,
               "true":1,
               "false":0
            };
            ticker.addEventListener("enterFrame",_dumpGarbage,false,-1,true);
         }

         ratio = 0;
         this.target = target;
         _ease = defaultEase;

         _overwrite = !("overwrite" in this.vars) ? int(_overwriteLookup[defaultOverwrite]) : (typeof this.vars.overwrite === "number" ? this.vars.overwrite >> 0 : int(_overwriteLookup[this.vars.overwrite]));

         if(this.target is Array && typeof this.target[0] === "object")
         {
            _targets = this.target.concat();
            _propLookup = [];
            _siblings = [];
            var i:int = _targets.length;
            while(--i > -1)
            {
               _siblings[i] = _register(_targets[i],this,false);
               if(_overwrite == 1 && _siblings[i].length > 1)
                  _applyOverwrite(_targets[i],this,null,1,_siblings[i]);
            }
         }
         else
         {
            _propLookup = {};
            _siblings = _tweenLookup[target];
            if(_siblings == null)
               _siblings = _tweenLookup[target] = [this];
            else
            {
               _siblings[_siblings.length] = this;
               if(_overwrite == 1)
                  _applyOverwrite(target,this,null,1,_siblings);
            }
         }
         if(Boolean(this.vars.immediateRender) || duration == 0 && _delay == 0 && this.vars.immediateRender != false)
            render(-_delay,false,true);
      }

		/**
		 * @private
		 * Initializes the tween
		 */
      protected function _init() : void
      {
         var immediate:Boolean = Boolean(vars.immediateRender);
         var i:int = 0;
         var initPlugins:Boolean = false;
         var pt:PropTween = null;
         var p:String = null;
         var copy:Object = null;
         if(vars.startAt)
         {
            if(_startAt != null)
               _startAt.render(-1,true);
            vars.startAt.overwrite = 0;
            vars.startAt.immediateRender = true;
            _startAt = new TweenLite(target,0,vars.startAt);
            if(immediate)
            {
               if(_time > 0)
                  _startAt = null;
               else if(_duration !== 0)
                  return;
            }
         }
         else if(Boolean(vars.runBackwards) && _duration !== 0)
         {
            if(_startAt != null)
            {
               _startAt.render(-1,true);
               _startAt = null;
            }
            else
            {
               copy = {};
               for(p in vars)
               {
                  if(!(p in _reservedProps))
                     copy[p] = vars[p];
               }
               copy.overwrite = 0;
               copy.data = "isFromStart";
               _startAt = TweenLite.to(target,0,copy);
               if(!immediate)
                  _startAt.render(-1,true);
               else if(_time === 0)
                  return;
            }
         }

         if(vars.ease is Ease)
            _ease = vars.easeParams is Array ? vars.ease.config.apply(vars.ease,vars.easeParams) : vars.ease;
         else if(typeof vars.ease === "function")
            _ease = new Ease(vars.ease,vars.easeParams);
         else
            _ease = defaultEase;
         _easeType = _ease._type;
         _easePower = _ease._power;
         _firstPT = null;

         if(_targets)
         {
            i = int(_targets.length);
            while(--i > -1)
            {
               if(_initProps(_targets[i],_propLookup[i] = {},_siblings[i],_overwrittenProps ? _overwrittenProps[i] : null))
                  initPlugins = true;
            }
         }
         else
            initPlugins = _initProps(target,_propLookup,_siblings,_overwrittenProps);
         
         if(initPlugins)
            _onPluginEvent("_onInitAllProps",this);
         if(_overwrittenProps)
            if(_firstPT == null)
               if(typeof target !== "function")
                  _enabled(false,false);
         if(vars.runBackwards)
         {
            pt = _firstPT;
            while(pt)
            {
               pt.s += pt.c;
               pt.c = -pt.c;
               pt = pt._next;
            }
         }
         _onUpdate = vars.onUpdate;
         _initted = true;
      }   
         
		/** @private Loops through the <code>vars</code> properties, captures starting values, triggers overwriting if necessary, etc. **/
      protected function _initProps(target:Object, propLookup:Object, siblings:Array, overwrittenProps:Object) : Boolean
      {
         var p:String = null;
         var i:int = 0;
         var initPlugins:Boolean = false;
         var plugin:Object = null;
         var val:Object = null;
         var vars:Object = this.vars;
         if(target == null)
            return false;
         for(p in vars)
         {
            val = vars[p];
            if(p in _reservedProps)
               if(val is Array)
                  if(val.join("").indexOf("{self}") !== -1)
                     vars[p] = _swapSelfInParams(val as Array);
            else if(p in _plugins && Boolean((plugin = new _plugins[p]())._onInitTween(target,val,this)))
            {
               _firstPT = new PropTween(plugin,"setRatio",0,1,p,true,_firstPT,plugin._priority);
               i = int(plugin._overwriteProps.length);
               while(--i > -1)
               {
                  propLookup[plugin._overwriteProps[i]] = _firstPT;
               }
               if(Boolean(plugin._priority) || "_onInitAllProps" in plugin)
                  initPlugins = true;
               if("_onDisable" in plugin || "_onEnable" in plugin)
                  _notifyPluginsOfEnabled = true;
            }
            else
            {
               _firstPT = propLookup[p] = new PropTween(target,p,0,1,p,false,_firstPT);
               _firstPT.s = !_firstPT.f ? Number(target[p]) : Number(target[Boolean(p.indexOf("set")) || !("get" + p.substr(3) in target) ? p : "get" + p.substr(3)]());
               _firstPT.c = typeof val === "number" ? Number(val) - _firstPT.s : (typeof val === "string" && val.charAt(1) === "=" ? int(val.charAt(0) + "1") * Number(val.substr(2)) : Number(val) || 0);
            }
         }
         if(overwrittenProps)
            if(_kill(overwrittenProps,target))
               return _initProps(target,propLookup,siblings,overwrittenProps);
         if(_overwrite > 1 && _firstPT != null && siblings.length > 1)
         {
            if(_applyOverwrite(target,this,propLookup,_overwrite,siblings))
            {
               _kill(propLookup,target);
               return _initProps(target,propLookup,siblings,overwrittenProps);
            }
         }
         return initPlugins;
      }



		/** @private (see Animation.render() for notes) **/
      override public function render(time:Number, suppressEvents:Boolean = false, force:Boolean = false) : void
      {
         var isComplete:Boolean = false;
         var callback:String = null;
         var pt:PropTween = null;
         var rawPrevTime:Number = NaN;
         var prevTime:Number = _time;
         if(time >= _duration)
         {
            _totalTime = _time = _duration;
            ratio = _ease._calcEnd ? _ease.getRatio(1) : 1;
            if(!_reversed)
            {
               isComplete = true;
               callback = "onComplete";
            }
            if(_duration == 0)
            {
               rawPrevTime = _rawPrevTime;
               if(_startTime === _timeline._duration)
                  time = 0;
               if(time === 0 || rawPrevTime < 0 || rawPrevTime === _tinyNum)
               {
                  if(rawPrevTime !== time)
                  {
                     force = true;
                     if(rawPrevTime > 0 && rawPrevTime !== _tinyNum)
                        callback = "onReverseComplete";
                  }
               }
               _rawPrevTime = rawPrevTime = !suppressEvents || time !== 0 || _rawPrevTime === time ? time : _tinyNum;
            }
         }
         else if(time < 1e-7)
         {
            _totalTime = _time = 0;
            ratio = _ease._calcEnd ? _ease.getRatio(0) : 0;
            if(prevTime !== 0 || _duration === 0 && _rawPrevTime > 0 && _rawPrevTime !== _tinyNum)
            {
               callback = "onReverseComplete";
               isComplete = _reversed;
            }
            if(time < 0)
            {
               _active = false;
               if(_duration == 0)
               {
                  if(_rawPrevTime >= 0)
                     force = true;
                  _rawPrevTime = rawPrevTime = !suppressEvents || time !== 0 || _rawPrevTime === time ? time : _tinyNum;
               }
            }
            else if(!_initted)
               force = true;
         }
         else
         {
            _totalTime = _time = time;
            if(_easeType)
            {
               var r:Number = time / _duration;
               if(_easeType == 1 || _easeType == 3 && r >= 0.5)
                  r = 1 - r;
               if(_easeType == 3)
                  r *= 2;
               if(_easePower == 1)
                  r *= r;
               else if(_easePower == 2)
                  r *= r * r;
               else if(_easePower == 3)
                  r *= r * r * r;
               else if(_easePower == 4)
                  r *= r * r * r * r;
               if(_easeType == 1)
                  ratio = 1 - r;
               else if(_easeType == 2)
                  ratio = r;
               else if(time / _duration < 0.5)
                  ratio = r / 2;
               else
                  ratio = 1 - r / 2;
            }
            else
               ratio = _ease.getRatio(time / _duration);
         }
         if(_time == prevTime && !force)
            return;
         if(!_initted)
         {
            _init();
            if(!_initted || _gc)
               return;
            if(Boolean(_time) && !isComplete)
               ratio = _ease.getRatio(_time / _duration);
            else if(isComplete && _ease._calcEnd)
               ratio = _ease.getRatio(_time === 0 ? 0 : 1);
         }
         if(!_active)
            if(!_paused && _time !== prevTime && time >= 0)
               _active = true;
         if(prevTime == 0)
         {
            if(_startAt != null)
            {
               if(time >= 0)
                  _startAt.render(time,suppressEvents,force);
               else if(!callback)
                  callback = "_dummyGS";
            }
            if(vars.onStart)
               if(_time != 0 || _duration == 0)
                  if(!suppressEvents)
                     vars.onStart.apply(null,vars.onStartParams);
         }
         pt = _firstPT;
         while(pt)
         {
            if(pt.f)
               pt.t[pt.p](pt.c * ratio + pt.s);
            else
               pt.t[pt.p] = pt.c * ratio + pt.s;
            pt = pt._next;
         }
         if(_onUpdate != null)
         {
            if(time < 0 && _startAt != null && _startTime != 0)
               _startAt.render(time,suppressEvents,force);
            if(!suppressEvents)
               if(_time !== prevTime || isComplete)
                  _onUpdate.apply(null,vars.onUpdateParams);
         }
         if(callback)
         {
            if(!_gc)
            {
               if(time < 0 && _startAt != null && _onUpdate == null && _startTime != 0)
                  _startAt.render(time,suppressEvents,force);
               if(isComplete)
               {
                  if(_timeline.autoRemoveChildren)
                     _enabled(false,false)
                  _active = false;
               }
               if(!suppressEvents)
                  if(vars[callback])
                     vars[callback].apply(null,vars[callback + "Params"]);
               if(_duration === 0 && _rawPrevTime === _tinyNum && rawPrevTime !== _tinyNum)
                  _rawPrevTime = 0;
            }
         }
      }

		/** @private Same as <code>kill()</code> except that it returns a Boolean indicating if any significant properties were changed (some plugins like MotionBlurPlugin may perform cleanup tasks that alter alpha, etc.). **/
      override public function _kill(vars:Object = null, target:Object = null) : Boolean
      {
         if(vars === "all")
            vars = null;
         if(vars == null)
            if(target == null || target == this.target)
               return _enabled(false,false);
         target = target || _targets || this.target;
         var i:int = 0;
         var overwrittenProps:Object = null;
         var p:String = null;
         var pt:PropTween = null;
         var propLookup:Object = null;
         var changed:Boolean = false;
         var killProps:Object = null;
         var record:Boolean = false;
         if(target is Array && typeof target[0] === "object")
         {
            i = int(target.length);
            while(--i > -1)
            {
               if(_kill(vars,target[i]))
                  changed = true;
            }
         }
         else
         {
            if(_targets)
            {
               i = int(_targets.length);
               while(--i > -1)
               {
                  if(target === _targets[i])
                  {
                     propLookup = _propLookup[i] || {};
                     _overwrittenProps = _overwrittenProps || [];
                     overwrittenProps = _overwrittenProps[i] = vars ? _overwrittenProps[i] || {} : "all";
                     break;
                  }
               }
            }
            else
            {
               if(target !== this.target)
                  return false;
               propLookup = _propLookup;
               overwrittenProps = _overwrittenProps = vars ? _overwrittenProps || {} : "all";
            }
            if(propLookup)
            {
               killProps = vars || propLookup;
               record = vars != overwrittenProps && overwrittenProps != "all" && vars != propLookup && (typeof vars != "object" || vars._tempKill != true);
               for(p in killProps)
               {
                  if((pt = propLookup[p]) != null)
                  {
                     if(pt.pg && Boolean(pt.t._kill(killProps)))
                        changed = true;
                     if(!pt.pg || pt.t._overwriteProps.length === 0)
                     {
                        if(pt._prev)
                           pt._prev._next = pt._next;
                        else if(pt == _firstPT)
                           _firstPT = pt._next;
                        if(pt._next)
                           pt._next._prev = pt._prev;
                        pt._prev = null;
                        pt._next = null;
                     }
                     delete propLookup[p];
                  }
                  if(record)
                     overwrittenProps[p] = 1;
               }
               if(_firstPT == null && _initted)
                  _enabled(false,false);
            }
         }
         return changed;
      }

		/** @inheritDoc **/
      override public function invalidate() : *
      {
         if(_notifyPluginsOfEnabled)
            _onPluginEvent("_onDisable",this);
         _firstPT = null;
         _overwrittenProps = null;
         _onUpdate = null;
         _startAt = null;
         _initted = _active = _notifyPluginsOfEnabled = false;
         _propLookup = _targets ? {} : [];
         return this;
      }

		/** @private (see Animation._enabled() for notes) **/
      override public function _enabled(enabled:Boolean, ignoreTimeline:Boolean = false) : Boolean
      {
         if(enabled && _gc)
         {
            if(_targets)
            {
               var i:int = int(_targets.length);
               while(--i > -1)
               {
                  _siblings[i] = _register(_targets[i],this,true);
               }
            }
            else
               _siblings = _register(target,this,true);
         }
         super._enabled(enabled,ignoreTimeline);
         if(_notifyPluginsOfEnabled)
            if(_firstPT != null)
               return _onPluginEvent(enabled ? "_onEnable" : "_onDisable",this);
         return false;
      }

      public static function to(target:Object, duration:Number, vars:Object) : TweenLite
      {
         return new TweenLite(target,duration,vars);
      }

      public static function from(target:Object, duration:Number, vars:Object) : TweenLite
      {
         vars = _prepVars(vars,true);
         vars.runBackwards = true;
         return new TweenLite(target,duration,vars);
      }

      public static function fromTo(target:Object, duration:Number, fromVars:Object, toVars:Object) : TweenLite
      {
         toVars = _prepVars(toVars,true);
         fromVars = _prepVars(fromVars);
         toVars.startAt = fromVars;
         toVars.immediateRender = toVars.immediateRender != false && fromVars.immediateRender != false;
         return new TweenLite(target,duration,toVars);
      }

		/** @private Accommodates TweenLiteVars instances for strong data typing and code hinting **/
      protected static function _prepVars(vars:Object, immediateRender:Boolean = false) : Object
      {
         if(vars._isGSVars)
            vars = vars.vars;
         if(immediateRender && !("immediateRender" in vars))
            vars.immediateRender = true;
         return vars;
      }

      public static function delayedCall(delay:Number, callback:Function, param:Array = null, useFrames:Boolean = false) : TweenLite
      {
         return new TweenLite(callback,0,{
            "delay":delay,
            "onComplete":callback,
            "onCompleteParams":param,
            "onReverseComplete":callback,
            "onReverseCompleteParams":param,
            "immediateRender":false,
            "useFrames":useFrames,
            "overwrite":0
         });
      }

      public static function set(target:Object, vars:Object) : TweenLite
      {
         return new TweenLite(target,0,vars);
      }
      
		/** @private **/
      private static function _dumpGarbage(event:Event) : void
      {
         if(_rootFrame / 60 >> 0 === _rootFrame / 60)
         {
            var i:int = 0;
            var a:Array = null;
            var tgt:Object = null;
            for(tgt in _tweenLookup)
            {
               a = _tweenLookup[tgt];
               i = int(a.length);
               while(--i > -1)
               {
                  if(a[i]._gc)
                     a.splice(i,1);
               }
               if(a.length === 0)
                  delete _tweenLookup[tgt];
            }
         }
      }

      public static function killTweensOf(target:*, onlyActive:* = false, vars:Object = null) : void
      {
         if(typeof onlyActive === "object")
         {
            vars = onlyActive;
            onlyActive = false;
         }
         var a:Array = TweenLite.getTweensOf(target,onlyActive);
         var i:int = a.length;
         while(--i > -1)
         {
            a[i]._kill(vars,target);
         }
      }

      public static function killDelayedCallsTo(func:Function) : void
      {
         killTweensOf(func);
      }
      
      public static function getTweensOf(target:*, onlyActive:Boolean = false) : Array
      {
         var i:int = 0;
         var a:Array = null;
         var j:int = 0;
         var t:TweenLite = null;
         if(target is Array && typeof target[0] != "string" && typeof target[0] != "number")
         {
            i = int(target.length);
            a = [];
            while(--i > -1)
            {
               a = a.concat(getTweensOf(target[i],onlyActive));
            }
            i = int(a.length);
            while(--i > -1)
            {
               t = a[i];
               j = i;
               while(--j > -1)
               {
                  if(t === a[j])
                     a.splice(i,1);
               }
            }
         }
         else
         {
            a = _register(target).concat();
            i = int(a.length);
            while(--i > -1)
            {
               if(Boolean(a[i]._gc) || onlyActive && !a[i].isActive())
                  a.splice(i,1);
            }
         }
         return a;
      }
      
      protected static function _register(target:Object, tween:TweenLite = null, scrub:Boolean = false) : Array
      {
         var i:int = 0;
         var a:Array = _tweenLookup[target];
         if(a == null)
            a = _tweenLookup[target] = [];
         if(tween)
         {
            i = int(a.length);
            a[i] = tween;
            if(scrub)
            {
               while(--i > -1)
               {
                  if(a[i] === tween)
                     a.splice(i,1);
               }
            }
         }
         return a;
      }
      
		/** @private Performs overwriting **/
      protected static function _applyOverwrite(target:Object, tween:TweenLite, props:Object, mode:int, sibling:Array) : Boolean
      {
         var i:int = 0;
         var changed:Boolean = false;
         var curTween:TweenLite = null;
         if(mode == 1 || mode >= 4)
         {
            var l:int = sibling.length;
            i = 0;
            for (i = 0; i < l; i++)
            {
               curTween = sibling[i]
               if(curTween != tween)
                  if(!curTween._gc)
                     if(curTween._enabled(false,false))
                        changed = true;
               else if(mode == 5)
                  break;
            }
            return changed;
         }

         var globalStart:Number = NaN;
         var startTime:Number = tween._startTime + 1e-10;
         var overlaps:Array = [];
         var oCount:int = 0;
         var zeroDur:Boolean = (tween._duration == 0);
         i = int(sibling.length);
         while(--i > -1)
         {
            curTween = sibling[i];
            if(curTween === tween || curTween._gc || curTween._paused)
            {}//ignore
            else if(curTween._timeline != tween._timeline)
            {
               globalStart = globalStart || _checkOverlap(tween, 0, zeroDur);
               if(_checkOverlap(curTween,globalStart,zeroDur) === 0)
                  overlaps[oCount++] = curTween;
            }
            else if(curTween._startTime <= startTime)
            {
               if(curTween._startTime + curTween.totalDuration() / curTween._timeScale > startTime)
                  if(!((zeroDur || !curTween._initted) && startTime - curTween._startTime <= 2e-10))
                     overlaps[oCount++] = curTween;
            }
         }

         i = oCount;
         while(--i > -1)
         {
            curTween = overlaps[i];
            if(mode == 2)
               if(curTween._kill(props,target))
                  changed = true;
            if(mode !== 2 || !curTween._firstPT && curTween._initted)
               if(curTween._enabled(false,false))
                  changed = true;
         }
         return changed;
      }
      
      private static function _checkOverlap(tween:Animation, reference:Number, zeroDur:Boolean) : Number
      {
         var tl:SimpleTimeline = tween._timeline;
         var ts:Number = tl._timeScale;
         var t:Number = tween._startTime;
         while(tl._timeline)
         {
            t += tl._startTime;
            ts *= tl._timeScale;
            if(tl._paused)
               return -100;
            tl = tl._timeline;
         }
         t /= ts;
         return (t > reference) ? t - reference : (zeroDur && t == reference || !tween._initted && t - reference < 2e-10 ? 1e-10 : ((t += tween.totalDuration() / tween._timeScale / ts) > reference + 1e-10 ? 0 : t - reference - 1e-10));
      }
   }
}
