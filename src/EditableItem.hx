package;

import haxe.ui.toolkit.containers.HBox;
import haxe.ui.toolkit.controls.TextInput;
import haxe.ui.toolkit.controls.Button;
import haxe.ui.toolkit.events.UIEvent;

/** EditableItem Class
 *  @author  Timothy Foster
 *  @version 0.00.150802
 *
 *  An item that can be edited or removed from a list of items.  To be used
 *  within a VBox located inside a ScrollView.  The button is set to remove
 *  this item from the VBox that contains it.
 *  **************************************************************************/
class EditableItem extends HBox {

/*  Constructor
 *  =========================================================================*/
/**
 *  Constructs a blank EditableItem.  Use item.text to access its contents.
 */
    public function new() {
        super();
        
        textinput = new TextInput();
        removeButton = new Button();
        removeButton.text = "X";
        textinput.width = 200;
        
        removeButton.addEventListener(UIEvent.MOUSE_UP, function(e) {
            this.parent.removeChild(this);
        });
        
        addChild(textinput);
        addChild(removeButton);
    }
    
/*  Class Methods
 *  =========================================================================*/
    
 
/*  Public Methods
 *  =========================================================================*/
 
/*  Private Members
 *  =========================================================================*/
    private var textinput:TextInput;
    private var removeButton:Button;
 
/*  Private Methods
 *  =========================================================================*/
    override private function get_text():String {
		return textinput.text;
	}
	
	override private function set_text(value:String):String {
		if (value != null)
			textinput.text = value;
		return value;
	}
}