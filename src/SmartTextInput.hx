package;

import haxe.Timer;

import openfl.Lib;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;

import haxe.ui.toolkit.controls.TextInput;

import systools.Clipboard;

/** SmartTextInput Class
 *  @author  Timothy Foster
 *  @version 0.00.150823
 *
 *  The TextInput class with some minor support for Ctrl commands.
 * 
 *  Currently, copying and pasting replaces entire text.  Text selection does
 *  nothing since OpenFL does not support it easily.
 *  **************************************************************************/
class SmartTextInput extends TextInput {
	private static var initialized:Bool = false;
	private static var ctrlDown:Bool = false;

/**
 *  Create a new instance
 */
	public function new() {
		super();
		initClass();
		this.addEventListener(KeyboardEvent.KEY_DOWN, performPress);
	}
	
/**
 *  Initialize the class.  This will be called each time a SmartTextInput is created.
 */
	public static function initClass():Void {
		if (!initialized) {
			initialized = true;
			Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent):Void {
				if (isCtrl(e.keyCode))
					ctrlDown = true;
			});
			Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent):Void {
				if (isCtrl(e.keyCode))
					ctrlDown = false;
			});
		}
	}
	
/**
 *  @private
 *  The press action, depending on the key.
 *  @param	e
 */
	private function performPress(e:KeyboardEvent):Void {
		if (ctrlDown) {
			switch(e.keyCode) {
				case Keyboard.C: copy();
				case Keyboard.V: paste();
			}
		}
	}
	
/**
 *  @private
 *  Copies the text to the clipboard
 */
	private function copy():Void {
		//var txt = this.text.substring(this.selectionBeginIndex, this.selectionEndIndex);
		var txt = this.text;
		Clipboard.setText(txt);
		preventStrayCharacter();
	}
	
/**
 *  @private
 *  Pastes from the clipboard to the field.  Newlines are removed if not multiline.
 */
	private function paste():Void {
		//this.replaceSelectedText(Clipboard.getText());
		var txt = Clipboard.getText();
		if (!this.multiline)
		    txt = ~/[\r\n]/g.replace(txt, "");
		this.text = txt;
		preventStrayCharacter();
	}
	
/**
 *  @private
 *  Without this function, Ctrl+letter will also input this letter.
 * 
 *  The letter is prevented with a millisecond delay that resets the text.
 */
	private function preventStrayCharacter():Void {
		var txt = this.text;
		Timer.delay(function() { this.text = txt; }, 1);
	}
	
/**
 *  @private
 *  Determines whether or not the key is a Ctrl key.  Note it is COMMAND on Macs.
 *  @param	code
 *  @return
 */
	private static inline function isCtrl(code:Int):Bool {
		return code == Keyboard.CONTROL || code == Keyboard.COMMAND;
	}
}