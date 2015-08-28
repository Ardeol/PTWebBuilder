package;

import openfl.Lib;
import openfl.display.Sprite;

import haxe.ui.toolkit.core.Toolkit;
import haxe.ui.toolkit.core.ClassManager;
import haxe.ui.toolkit.controls.popups.Popup;
import haxe.ui.toolkit.themes.GradientTheme;

class Main extends Sprite {
    
    public var app:PTWebBuilder;

	public function new() {
		super();
        
        Toolkit.theme = new GradientTheme();
		ClassManager.instance.registerComponentClass(SmartTextInput, "smarttextinput");
        Toolkit.init();
        Toolkit.setTransitionForClass(Popup, "none");
        
        app = new PTWebBuilder();
	}

}
