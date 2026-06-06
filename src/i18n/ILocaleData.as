package i18n {
    public interface ILocaleData {
        /** 语言代码，如 "en", "zh_cn", "ja" */
        function get code():String;
        /** 语言显示名，如 "English", "简体中文" */
        function get displayName():String;
        /** 获取所有翻译键值对 */
        function get strings():Object;
    }
}