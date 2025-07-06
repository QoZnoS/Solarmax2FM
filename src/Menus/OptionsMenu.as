// 该类管理整个设置界面
package Menus
{
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   import utils.Component.MenuButton;
   import utils.Component.OptionButton;
   import Menus.StartMenus.IMenu;
   import Menus.StartMenus.SettingMenu;

   public class OptionsMenu extends Sprite
   {
      public var lineHeight:Number;
      public var COLOR:uint;

      public var title:TitleMenu; // 接入标题类
      public var menuBtn:MenuButton;
      public var prevBtn:MenuButton; // 上一页按钮
      public var nextBtn:MenuButton; // 下一页按钮
      public var page:int = 0;
      public var pages:Array; // 选项页面数组
      public var pageLayers:Array; // 页面层数组
      public var page1:Sprite;
      public var page2:Sprite;
      public var divStrings:Array;

      public var mapPage:int = 0; // 地图页面索引

      private var nicobtn:OptionButton;

      private var settingMenu:SettingMenu;

      private var menus:Vector.<IMenu>;

      public function OptionsMenu(_titleMenu:TitleMenu)
      {
         super();
         divStrings = [["ORIGINAL", "Downlink18"], ["DESIGN, ART, CODE:", "Downlink12"], ["NICO TUASON", "Downlink12"], ["MUSIC:", "Downlink12"], ["JOHN CAMARA", "Downlink12"], ["PLAYTESTING:", "Downlink12"], ["TERRY TUASON", "Downlink12"], ["MODIFIED", "Downlink18"], ["CODE:", "Downlink12"], ["QoZnoS", "Downlink12"], ["SPECIAL THANKS:", "Downlink18"], ["Solarmax23333", "Downlink12"], ["supercluster", "Downlink12"], ["Solarmax33", "Downlink12"], ["Thirdsister", "Downlink12"], ["Tuetiedove", "Downlink12"]];
         lineHeight = 36;
         COLOR = 0xFF9DBB;
         this.title = _titleMenu;
         var bg:Quad = new Quad(1024, 768, 0);
         bg.alpha = 0.65;
         addChild(bg);
         page = 0;
         pages = [[], [[], []], []];
         pageLayers = [];
         settingMenu = new SettingMenu(title);
         page1 = new Sprite();
         page2 = new Sprite();
         pageLayers.push(settingMenu);
         pageLayers.push(page1);
         pageLayers.push(page2);
         for (var i:int = 0; i < pages.length; i++)
         {
            pageLayers[i].x = pageLayers[i].pivotX = 512;
            pageLayers[i].y = pageLayers[i].pivotY = 384;
            addChild(pageLayers[i]);
         }
         // #region 左上角四个按钮
         menuBtn = new MenuButton("btn_menu");
         menuBtn.x = 15 + Globals.margin;
         menuBtn.y = 124;
         menuBtn.blendMode = "add";
         addChild(menuBtn);
         prevBtn = new MenuButton("tutorial_arrow");
         prevBtn.x = 85 + Globals.margin;
         prevBtn.y = 146;
         prevBtn.image.rotation = Math.PI;
         prevBtn.blendMode = "add";
         prevBtn.setImage("tutorial_arrow", 0.75);
         addChild(prevBtn);
         nextBtn = new MenuButton("tutorial_arrow");
         nextBtn.x = 95 + Globals.margin;
         nextBtn.y = 124;
         nextBtn.blendMode = "add";
         nextBtn.setImage("tutorial_arrow", 0.75);
         addChild(nextBtn);
         // #endregion
         createPage1();
         createPage2();
         menuBtn.init();
         menuBtn.addEventListener("clicked", on_menu);
         prevBtn.init();
         prevBtn.addEventListener("clicked", on_prev);
         nextBtn.init();
         nextBtn.addEventListener("clicked", on_next);
         on_refresh();
      }

      public function createPage1():void
      {
         var _text:TextField = new TextField(200, 40, "MAP MANAGER", "Downlink18", -1, COLOR);
         pages[1][0].push(_text);
         addLabel(_text, 412, 122, 1, "center");
         var _btn:MenuButton = new MenuButton("btn_restart");
         _btn.x = 604;
         _btn.y = 124;
         _btn.init();
         _btn.addEventListener("clicked", on_refresh);
         pages[1][0].push(_btn);
         pageLayers[1].addChild(_btn);
         _btn = new MenuButton("tutorial_arrow");
         _btn.x = 670;
         _btn.y = 146;
         _btn.image.rotation = Math.PI;
         _btn.init();
         _btn.setImage("tutorial_arrow", 0.75);
         _btn.addEventListener("clicked", on_page1_prev);
         pages[1][0].push(_btn);
         pageLayers[1].addChild(_btn);
         _btn = new MenuButton("tutorial_arrow");
         _btn.x = 680;
         _btn.y = 124;
         _btn.init();
         _btn.setImage("tutorial_arrow", 0.75);
         _btn.addEventListener("clicked", on_page1_next);
         pages[1][0].push(_btn);
         pageLayers[1].addChild(_btn);
      }

      public function createPage2():void
      {
         // #region 添加文本
         for each (var _string:Array in divStrings)
         {
            pages[2].push(new TextField(400, 40, _string[0], _string[1], -1, COLOR));
         }
         // #endregion
         // #region 添加实例化对象
         var _y:Number = 120;
         var _side:int = 0;
         for (var i:int = 0; i < pages[2].length; i++)
         {
            if (pages[2][i].fontName == "Downlink18")
            {
               addLabel(pages[2][i], 312, _y, 2, "center");
               _y += lineHeight * 1.6;
            }
            else
            {
               if (_side == 0)
               {
                  addLabel(pages[2][i], 100, _y, 2, "right");
                  _side = 1;
                  _y += lineHeight;
               }
               else
               {
                  addLabel(pages[2][i], 520, _y, 2, "left");
                  _side = 0;
               }
            }
            pages[2][i].y = _y;
            if (pages[2][i].text == "NICO TUASON")
            {
                nicobtn = new OptionButton("NICO TUASON", COLOR, null)
                nicobtn.x = pages[2][i].x
                nicobtn.y = pages[2][i].y
                pages[2][i].visible = false
                nicobtn.addEventListener("clicked", invisibleMode)
                pageLayers[2].addChild(nicobtn)
            }
         }
         // #endregion
      }

      private function addLabel(_label:TextField, _x:Number, _y:Number, _page:int = 0, _hAlign:String = "right"):void
      {
         _label.hAlign = _hAlign;
         _label.vAlign = "top";
         _label.x = _x;
         _label.y = _y;
         pageLayers[_page].addChild(_label);
      }

      public function animateIn():void
      {
         this.alpha = 0;
         this.visible = true;
         Starling.juggler.removeTweens(this);
         Starling.juggler.tween(this, 0.15, {"alpha": 1});
         settingMenu.animateIn()
         Globals.textSize == 2 ?
            menuBtn.setImage("btn_menu2x", 0.75) :
            menuBtn.setImage("btn_menu");
         addEventListener("enterFrame", update);
      }

      public function animateOut():void
      {
         Starling.juggler.removeTweens(this);
         Starling.juggler.tween(this, 0.15, {
                  "alpha": 0,
                  "onComplete": hide
               });
         removeEventListener("enterFrame", update);
      }

      public function hide():void
      {
         this.visible = false;
      }
      // #region 界面按钮
      public function on_menu(_click:Event):void
      {
         Globals.save();
         animateOut();
      }

      public function on_prev(_click:Event):void
      {
         if (page > 0)
            page--;
      }

      public function on_next(_click:Event):void
      {
         if (page < pages.length - 1)
            page++;
      }
      // #endregion

      // #region page1按钮
      public function on_refresh():void
      {
         LevelData.init();
         title.getBarrierData();
         title.getOrbitData();
         title.levels.updateLevels();
         var _dataQuad:OptionButton;
         if (pages[1][1].length != 0)
         {
            for each (_dataQuad in pages[1][1])
            {
               _dataQuad.removeEventListener("clicked", on_choose_map);
               pageLayers[1].removeChild(_dataQuad);
            }
            pages[1][1] = [];
         }
         var _y:Number = 160;
         var _data:Array;
         for (var i:int = 0; i < LevelData.data.length; i++)
         {
            _data = LevelData.data[i];
            _dataQuad = new OptionButton(LevelData.extensions.data.(@id == i).@name, COLOR, pages[1][1]);
            _dataQuad.label.fontName = "Downlink18";
            _dataQuad.label.width = 700;
            _dataQuad.label.x += 40;
            _dataQuad.addLabel(new TextField(40, 40, "#" + LevelData.data.indexOf(_data), "Downlink18", -1, COLOR), 0, 0);
            _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe1, "Downlink12", -1, COLOR), 40, 25);
            if (LevelData.extensions.data.(@id == i).@describe2 != undefined)
               _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe2, "Downlink12", -1, COLOR), 40, 40);
            if (LevelData.extensions.data.(@id == i).@describe3 != undefined)
               _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe3, "Downlink12", -1, COLOR), 40, 55);
            if (LevelData.extensions.data.(@id == i).@describe4 != undefined)
               _dataQuad.addLabel(new TextField(600, 40, LevelData.extensions.data.(@id == i).@describe4, "Downlink12", -1, COLOR), 40, 70);
            _dataQuad.addLabel(new TextField(600, 40, "MAPPER: " + _data[1][0], "Downlink12", -1, COLOR), 40, 90);
            _dataQuad.addImage(new Image(Root.assets.getTexture(LevelData.extensions.data.(@id == i).@icon)));
            _dataQuad.quad.color = 0x000000;
            _dataQuad.quad.alpha = 0.5;
            _dataQuad.quad.width = _dataQuad.labelBG.width = 768;
            _dataQuad.quad.height = _dataQuad.labelBG.height = 120;
            _dataQuad.x = 128;
            _dataQuad.y = _y;
            _dataQuad.addEventListener("clicked", on_choose_map);
            pages[1][1].push(_dataQuad);
            pageLayers[1].addChild(_dataQuad);
            _y += 125;
            if (_y > 600)
               _y -= 500;
         }
         pages[1][1][Globals.currentData].toggle();
      }

      public function on_choose_map(_click:Event):void
      {
         Globals.currentData = pages[1][1].indexOf(_click.target);
         Globals.save();
         LevelData.init();
         title.getBarrierData();
         title.getOrbitData();
         title.levels.updateLevels();
         animateOut();
      }

      public function on_page1_prev(_click:Event):void
      {
         if (mapPage > 0)
            mapPage--;
      }

      public function on_page1_next(_click:Event):void
      {
         if (mapPage < pages[1][1].length - 1)
            mapPage++;
      }
      // #endregion
        private var nicoClickTime:int = 0
        private function invisibleMode(_click:Event):void
        {
            if (title.currentIndex == 0)
                return
            nicoClickTime += 1;
            nicobtn.label.color = uint(Math.random()*256*256*256)
            GS.playClick()
            if (nicoClickTime == 5)
            {
                nicoClickTime = 0;
                nicobtn.label.color = COLOR;
                on_menu(null);
                // 以隐形模式进入关卡...
                title.loadMap();
                title.scene.gameScene.invisibleMode();
            }
        }

      public function update(e:EnterFrameEvent):void
      {
         GS.updateTransforms();
         for (var i:int = 0; i < pageLayers.length; i++)
         {
            pageLayers[i].visible = false;
         }
         pageLayers[page].visible = true;
         page == 0 ?
            prevBtn.visible = false :
            prevBtn.visible = true;
         page == pages.length - 1 ?
            nextBtn.visible = false :
            nextBtn.visible = true;
         mapPage == 0 ?
            pages[1][0][2].visible = false :
            pages[1][0][2].visible = true;
         mapPage == Math.floor(pages[1][1].length / 4) ?
            pages[1][0][3].visible = false :
            pages[1][0][3].visible = true;
         for (i = 0; i < pages[1][1].length; i++)
         {
            mapPage * 4 <= i && i < mapPage * 4 + 4 ?
               pages[1][1][i].visible = true :
               pages[1][1][i].visible = false;
         }
      }
   }
}
