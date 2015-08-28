package;

import openfl.Lib;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;

import haxe.ui.toolkit.controls.Button;
import haxe.ui.toolkit.core.XMLController;
import haxe.ui.toolkit.core.Component;
import haxe.ui.toolkit.core.PopupManager;
import haxe.ui.toolkit.controls.TextInput;
import haxe.ui.toolkit.containers.ListView;
import haxe.ui.toolkit.containers.ScrollView;
import haxe.ui.toolkit.containers.VBox;
import haxe.ui.toolkit.events.UIEvent;

import systools.Clipboard;

/** MainController Class
 *  @author  Timothy Foster
 *  @version 0.01.150823
 *
 *  The entirety of the UI interface is located here.  There should only be
 *  one MainController ever created, so behavior is undefined if more than
 *  one is intantiated or opened.
 * 
 *  Merely creating this is sufficient for the application to run.  Note that
 *  it requires a reference to the app itself in order to attain access to
 *  the database.
 *  **************************************************************************/
class MainController extends XMLController {
    public static inline var UNKNOWN_UIN = "NOT DISCLOSED";

/*  Constructor
 *  =========================================================================*/
/**
 *  Create the UI.
 *  @param app Reference to the app so that it can access the database.
 */
    public function new(app:PTWebBuilder) {
        super("xml/layout.xml");
        this.app = app;
        
    //  Button Events
        attachEvent(ID.LOAD, UIEvent.MOUSE_UP, loadUIN);
        attachEvent(ID.SUBMIT, UIEvent.MOUSE_UP, submit);
        attachEvent(ID.LOAD_NAME, UIEvent.MOUSE_UP, loadName.bind(_, false));
        attachEvent(ID.LOAD_FULLNAME, UIEvent.MOUSE_UP, loadName.bind(_, true));
        attachEvent(ID.PASTE_EMAIL, UIEvent.MOUSE_DOWN, pasteTo.bind(_, getComponent(ID.EMAIL)));
        attachEvent(ID.PASTE_IMAGE, UIEvent.MOUSE_DOWN, pasteTo.bind(_, getComponent(ID.IMAGE)));
        attachEvent(ID.REMOVE, UIEvent.MOUSE_UP, remove);
        attachEvent(ID.CLEAR, UIEvent.MOUSE_UP, clearFields);
        attachEvent(ID.GENERATE, UIEvent.MOUSE_UP, generateHTML);
        attachEvent(ID.ADD_COURSE, UIEvent.MOUSE_UP, addCourse);
        attachEvent(ID.ADD_HOURS, UIEvent.MOUSE_UP, addHours);
		
	//  Added in 0.01.150823
		attachEnterEvent(getComponent(ID.UIN), loadUIN);
		attachEnterEvent(getComponent(ID.LASTNAME), loadName.bind(_, false));
		attachEnterEvent(getComponent(ID.FIRSTNAME), loadName.bind(_, true));
	//  End added
        
        attachEvent(ID.NAME_LIST, UIEvent.CHANGE, function(e) {
            var listview = getComponentAs(ID.NAME_LIST, ListView);
            var name = listview.getItem(listview.selectedIndex).text;
            if (curPTList == null)
                PTWebBuilder.error("List of names was never initialized.");
            else {
                var pt = curPTList[listview.selectedIndex];
                getComponent(ID.UIN).text = UNKNOWN_UIN;
                dispPT(pt);
            }
        });
        
        refreshNameList();
    }
    
/*  Class Methods
 *  =========================================================================*/
    
/*  Public Methods
 *  =========================================================================*/
 
/*  Private Members
 *  =========================================================================*/
    private var app:PTWebBuilder;
    private var curPTList:Array<PeerTeacher>; // For PT access via list; infinitely faster than app.ptsByAlpha()
	private var ctrlDown:Bool;
 
/*  Private Methods
 *  =========================================================================*/
    private function attachEnterEvent(c:Component, f:Dynamic):Void {
		c.addEventListener(KeyboardEvent.KEY_DOWN, function(e:KeyboardEvent) {
			if (e.keyCode == Keyboard.ENTER)
				f(e);
		});
	}
    
/**
 *  @private
 *  Loads the PT based on the UIN field.
 *  @param e
 */
    private function loadUIN(e:UIEvent):Void {
        var uin = getComponent(ID.UIN).text;
        if (~/^\d\d\d00\d\d\d\d$/.match(uin)) {
            var pt = app.getByUIN(uin);
            if (pt != null) {
                dispPT(pt);
            }
            else
                PTWebBuilder.error('No peer teacher with UIN $uin found');
        }
        else
            PTWebBuilder.error('$uin is not a valid UIN');
    }
    
/**
 *  @private
 *  Loads the PT based on the First and Last name fields.
 *  @param e
 *  @param useFirst
 */
    private function loadName(e:UIEvent, ?useFirst:Bool = false):Void {
        var lastname = getComponent(ID.LASTNAME).text;
        var firstname = "";
        if(useFirst)
            firstname = getComponent(ID.FIRSTNAME).text;
        
        if (lastname.length > 0 || firstname.length > 0) {
            var pt = app.getByName(lastname, firstname);
            if (pt != null) {
                getComponent(ID.UIN).text = UNKNOWN_UIN;
                dispPT(pt);
            }
            else
                PTWebBuilder.error('No peer teacher with last name $lastname found');
        }
        else
            PTWebBuilder.error("Name field is blank.");
    }
    
/**
 *  @private
 *  Pastes the clipboard to the given component
 *  @param e
 *  @param c
 */
    private function pasteTo(e:UIEvent, c:Component):Void {
        c.text = Clipboard.getText();
    }
    
/**
 *  @private
 *  Submits the current PT's information, updating it if necessary and creating a new entry if one did not already exist.
 *  @param e
 */
    private function submit(e:UIEvent):Void {
        var pt = getPT();
        if (pt != null) {
            writePT(pt);
            app.save();
        }
        else if(~/^\d\d\d00\d\d\d\d$/.match(getComponent(ID.UIN).text)) {
        //  Create a popup asking for permision to create a new peer teacher
            pt = new PeerTeacher(getComponent(ID.UIN).text);
            writePT(pt);
            PopupManager.instance.showSimple('${pt.firstname} ${pt.lastname} does not exist yet.  Create?', "Create new PT?", {
                buttons: [PopupButton.CONFIRM, PopupButton.CANCEL]
            }, function(btn:Dynamic) {
                if (Std.is(btn, Int)) {
                    switch(btn) {
                        case PopupButton.CONFIRM:
                            app.addPT(pt);
                            app.save();
                            this.refreshNameList();
                        case PopupButton.CANCEL:
                            // do nothing
                    }
                }
            });
        }
        else
            PTWebBuilder.error("A UIN must be provided to create a new entry.");
    }
    
/**
 *  @private
 *  Removes the current PT loaded if applicable
 *  @param e
 */
    private function remove(e:UIEvent):Void {
        var pt = getPT();
        if (pt != null) {
        //  Need to confirm removal
            PopupManager.instance.showSimple('Are you sure you wish to remove ${pt.firstname} ${pt.lastname}?', "Confirm?", {
                buttons: [PopupButton.CONFIRM, PopupButton.CANCEL]
            }, function(btn:Dynamic) {
                if (Std.is(btn, Int)) {
                    switch(btn) {
                        case PopupButton.CONFIRM:
                            app.removePT(pt);
                            app.save();
                            this.clearFields();
                            this.refreshNameList();
                        case PopupButton.CANCEL:
                            // do nothing
                    }
                }
            });
        }
        else
            PTWebBuilder.error("Peer teacher was not found and cannot be removed");
    }
    
/**
 *  @private
 *  Puts the HTML for the PT list into the Clipboard.
 * 
 *  In development, it tried to put the HTML to a text file, but for some reason OpenFL textfields do not allow Ctrl+A Ctrl+C on system builds.
 *  @param e
 */
    private function generateHTML(e:UIEvent):Void {
    //  getComponent(ID.HTML).text = app.generateHTML();  // lol this fails...
        Clipboard.setText(app.generateHTML());
        PopupManager.instance.showSimple("The HTML has been copied to the clipboard.  You may paste it where you need it.", "Success");
    }
    
/**
 *  @private
 *  Makes a new course entry
 *  @param e
 */
    private function addCourse(e:UIEvent):Void {
        var courses = getComponent(ID.COURSES);
        courses.addChild(new EditableItem());
    }
    
/**
 *  @private
 *  Makes a new hours entry; probably redundant but it was easier to copy-paste than create good code
 *  @param e
 */
    private function addHours(e:UIEvent):Void {
        var hours = getComponent(ID.HOURS);
        hours.addChild(new EditableItem());
    }
    
/**
 *  @private
 *  Retrieves the PeerTeacher from the app's database given the information in the fields
 *  @return
 */
    private function getPT():PeerTeacher {
        var uin = getComponent(ID.UIN).text;
        if (uin == UNKNOWN_UIN || ~/^\d\d\d00\d\d\d\d$/.match(uin)) {
            var pt:PeerTeacher;
            if (uin == UNKNOWN_UIN)
                return app.getByName(getComponent(ID.LASTNAME).text);
            else
                return app.getByUIN(uin);
        }
        else {
            PTWebBuilder.error('$uin is not a valid UIN');
            return null;
        }
    }
    
/**
 *  @private
 *  Display's a PT's information into the fields
 *  @param pt
 */
    private function dispPT(pt:PeerTeacher):Void {
        getComponent(ID.FIRSTNAME).text = pt.firstname;
        getComponent(ID.LASTNAME).text = pt.lastname;
        getComponent(ID.EMAIL).text = pt.email;
        getComponent(ID.IMAGE).text = pt.image;
        
        var courses = getComponent(ID.COURSES);
        courses.removeAllChildren();
        for (course in pt.courses) {
            var t = new EditableItem();
            t.text = course;
            courses.addChild(t);
        }
        
        var hours = getComponent(ID.HOURS);
        hours.removeAllChildren();
        for (hour in pt.hours) {
            var t = new EditableItem();
            t.text = '${hour.days} ${hour.hours}';
            hours.addChild(t);
        }
    }
    
/**
 *  @private
 *  Modifies a PeerTeacher object using the information in the fields.  Because of references, this also changes the database.
 *  @param pt
 *  @return
 */
    private function writePT(pt:PeerTeacher):PeerTeacher {
        pt.firstname = getComponent(ID.FIRSTNAME).text;
        pt.lastname = getComponent(ID.LASTNAME).text;
        pt.email = getComponent(ID.EMAIL).text;
        pt.image = getComponent(ID.IMAGE).text;
        
        var courses = getComponent(ID.COURSES);
        pt.courses.splice(0, pt.courses.length);
        for (course in courses.children)
            pt.courses.push(cast(course, Component).text);
            
        var hours = getComponent(ID.HOURS);
        pt.hours.splice(0, pt.hours.length);
        for (hour in hours.children) {
            var txt = cast(hour, Component).text;
            var patt = ~/([MTWRFSu]+)\s(.*)/;
            patt.match(txt);
            pt.hours.push({
                days: patt.matched(1),
                hours: patt.matched(2)
            });
        }
        
        return pt;
    }
    
/**
 *  @private
 *  Clears the fields
 *  @param e
 */
    private function clearFields(?e:UIEvent):Void {
        getComponent(ID.UIN).text = "";
        getComponent(ID.FIRSTNAME).text = "";
        getComponent(ID.LASTNAME).text = "";
        getComponent(ID.EMAIL).text = "";
        getComponent(ID.IMAGE).text = "";
        
        getComponent(ID.COURSES).removeAllChildren();
        getComponent(ID.HOURS).removeAllChildren();
    }
    
/**
 *  @private
 *  Refreshes the list of names.  Should be called anytime an entry is removed or added.
 *  Not necessary to call if merely updating an existing entry.
 */
    private function refreshNameList():Void {
        curPTList = app.ptsByAlpha();
        var listview = getComponentAs(ID.NAME_LIST, ListView);
        listview.dataSource.removeAll();
        for (pt in curPTList)
            listview.dataSource.add({ text: '${pt.firstname} ${pt.lastname}' });
    }
 
}

@:enum private abstract ID(String) from String to String {
    var SUBMIT = "submit-button";
    var GENERATE = "generate-button";
    var LOAD = "load-button";
    var LOAD_NAME = "load-last-button";
    var LOAD_FULLNAME = "load-first-button";
    var PASTE_EMAIL = "paste-email-button";
    var PASTE_IMAGE = "paste-image-button";
    var REMOVE = "remove-button";
    var CLEAR = "clear-button";
    var ADD_COURSE = "add-course-button";
    var ADD_HOURS = "add-hours-button";
    
    var UIN = "uin-input";
    var FIRSTNAME = "first-name-input";
    var LASTNAME = "last-name-input";
    var EMAIL = "email-input";
    var IMAGE = "image-input";
    
    var HTML = "html-output";
    
    var COURSES = "courses-scrollview";
    var HOURS = "hours-scrollview";
    
    var NAME_LIST = "name-listview";
}