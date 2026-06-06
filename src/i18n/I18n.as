package i18n {

    import flash.utils.Dictionary;
    import managers.SaveManager;
    import i18n.languages.LocaleZH_CN;
    import i18n.languages.LocaleEN;
    import starling.events.Event;
    import starling.events.EventDispatcher;

    // 翻译兼静态工厂类
    public class I18n {
        public static const ZH_CN:String = "zh_cn";
        public static const EN:String = 'en';

        private static var _languages:Dictionary = new Dictionary();
        private static var _languageList:Array = [];
        private static var _ready:Boolean = false;
        private static var _dispatcher:EventDispatcher = new EventDispatcher();

        private static function _init():void {
            registerLanguage(new LocaleZH_CN());
            registerLanguage(new LocaleEN());
            _ready = true;
        }

        public static function registerLanguage(data:ILocaleData):void {
            _languages[data.code] = data;
            _languageList.push(data.code);
        }

        public static function get availableLanguages():Array {
            if (!_ready)
                _init();
            var names:Array = [];
            for each(var code:String in _languageList)
                names.push(ILocaleData(_languages[code]).displayName);
            return names;
        }

        /**
         * 获取翻译文本
         * @param key      键名
         * @param args     可选参数，用于替换 {0}, {1}, {2}...
         */
        public static function _(key:String, ...args):String {
            if (!_ready)
                _init();
            var str:String = null;
            var current:String = SaveManager.languages;
            if (!_languages[current])
                return "unknow language";
            var data:Object = _languages[current].strings;
            if (data && data[key])
                str = data[key];
            else if (_languages[EN]) {
                var fbData:Object = ILocaleData(_languages[EN]).strings;
                if (fbData && fbData[key])
                    str = fbData[key];
            }
            else
                str = key;
            // 替换参数 {0}, {1}, ...
            if (args && args.length > 0)
                for (var i:int = 0; i < args.length; i++)
                    str = str.replace("{" + i + "}", args[i]);
            return str;
        }

        public static function getLanguageCodeByRegisteID(id:int):String {
            if (id < 0 || id >= _languageList.length)
                return EN;
            return _languageList[id];
        }

        public static function getLanguageIDByRegisteCode(code:String):int {
            return _languageList.indexOf(code);
        }

        // ===== 运行时语言切换 =====

        /** 切换语言并通知所有监听者刷新 UI */
        public static function setLocale(code:String):Boolean {
            if (!_languages[code])
                return false;
            SaveManager.languages = code;
            _dispatcher.dispatchEvent(new Event(Event.CHANGE));
            return true;
        }

        /** 注册语言变更监听 */
        public static function addEventListener(type:String, listener:Function):void {
            _dispatcher.addEventListener(type, listener);
        }

        /** 移除语言变更监听 */
        public static function removeEventListener(type:String, listener:Function):void {
            _dispatcher.removeEventListener(type, listener);
        }
    }
}
