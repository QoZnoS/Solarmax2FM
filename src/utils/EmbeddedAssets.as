package utils{
    public class EmbeddedAssets {
        [Embed(source = "/_assets/paused.png")]
        public static const paused_png:Class;
        [Embed(source = "/_assets/startup.png")]
        public static const startup_png:Class;
        [Embed(source = "/_assets/downlink.ttf", fontName="downlink", embedAsCFF="false")]
        private static const downlink:Class;
        [Embed(source = "/_assets/MFYueHei.otf", fontName="mfYueHei", embedAsCFF="false")]
        private static const mfYueHei:Class;
    }
}
