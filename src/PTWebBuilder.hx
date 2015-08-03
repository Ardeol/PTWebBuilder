package;

import haxe.Json;
import sys.io.File;

import openfl.Assets;

import haxe.ui.toolkit.core.Component;
import haxe.ui.toolkit.core.Toolkit;
import haxe.ui.toolkit.core.PopupManager;

//import systools.Dialogs;

/** PTWebBuilder Class
 *  @author  Timothy Foster
 *  @version 0.00.150802
 *
 *  The app.  It also contains the database, and hence it can be interacted
 *  with in order to obtain entries or write to them.
 *  **************************************************************************/
class PTWebBuilder {

/*  Constructor
 *  =========================================================================*/
/**
 *  Create and start the app.
 */
    public function new() {
        initDatabase();
        initUI("xml/layout.xml");
    }
    
/*  Class Methods
 *  =========================================================================*/
/**
 *  Master error method.
 *  @param msg
 */
    public static inline function error(msg:String):Void {
        PopupManager.instance.showSimple(msg, "Error");
    }
 
/*  Public Methods
 *  =========================================================================*/
/**
 *  Returns the peer teacher with the given real UIN.
 *  @param uin Actual UIN, not an encoded version.
 *  @return
 */
    public function getByUIN(uin:String):PeerTeacher {
        return peerteachers.get(Crypto.encode(uin));
    }
    
/**
 *  Accesses peer teachers given either last name, first name, or both.  Warns if multiple entries are found.
 * 
 *  In the case of multiple entries, search by UIN ought to be used instead.
 *  @param last
 *  @param first
 *  @return
 */
    public function getByName(last:String, ?first:String = ""):PeerTeacher {
    //  Cannot search for nothing...
        if (last.length == 0 && first.length == 0) 
            return null;
        var count = 0;
        var found:PeerTeacher = null;
        for (pt in peerteachers) {
            if ((last.length == 0 || pt.lastname == last) && (first.length == 0 || pt.firstname == first)) {
                ++count;
                found = pt;
            }
        }
        if (count > 1)
            error('$count matches were found');
        return found;
    }
    
/**
 *  Adds the PT to the database
 *  @param pt
 */
    public function addPT(pt:PeerTeacher) {
        peerteachers.set(pt.uin, pt);
    }
    
/**
 *  Removes the PT given its reference
 *  @param pt
 */
    public function removePT(pt:PeerTeacher) {
        peerteachers.remove(pt.uin);
    }
    
/**
 *  Saves the database file in its current state.
 */
    public function save():Void {
        var ofs = File.write(datafile);
        var pts = new Array<PeerTeacher>();
        for (pt in peerteachers)
            pts.push(pt);
        ofs.writeString(Json.stringify({ peerteachers: pts }));
        ofs.close();
    }
    
/**
 *  Generates the HTML string given the template .html files and the database.
 *  @return
 */
    public function generateHTML():String {
        var html = new StringBuf();
    //  Write head
        html.add(Assets.getText("data/head.html"));
        
    //  Get template information
        var numBodies = Std.parseInt(Assets.getText("data/numbodies.txt"));
        var bodies = new Array<String>();
        for (i in 0...numBodies)
            bodies.push(Assets.getText('data/body$i.html'));
            
    //  Write body using templates
        var index = 0;
        for (pt in ptsByAlpha()) {
            html.add(replaceWithPT(bodies[index], pt));
            index = index == numBodies - 1 ? 0 : index + 1;
        }
        
    //  Write foot and return
        html.add(Assets.getText("data/foot.html"));
        return html.toString();
    }
    
/**
 *  List of PTs in alphabetical order, last->first->uin precedence
 *  @return
 */
    public function ptsByAlpha():Array<PeerTeacher> {
        var pts = new Array<PeerTeacher>();
        for (pt in peerteachers) 
            pts.push(pt);
            
        pts.sort(function(lhs, rhs) {
            if (lhs.lastname < rhs.lastname)
                return -1;
            else if (lhs.lastname == rhs.lastname) {
                if (lhs.firstname < rhs.firstname)
                    return -1;
                else if (lhs.firstname == rhs.firstname) {
                    if (lhs.uin < rhs.uin)
                        return -1;
                    else
                        return 1;
                }
            }
            return 1;
        });
        
        return pts;
    }
 
/*  Private Members
 *  =========================================================================*/
    private var peerteachers:PTDatabase;  // uin->data
    private var datafile:String;
 
/*  Private Methods
 *  =========================================================================*/
    private function initUI(path:String):Void {
        Toolkit.openFullscreen(function(root) {
            root.addChild(new MainController(this).view);
        });
    }
    
    private function initDatabase():Void {
        peerteachers = new PTDatabase();
    /*
        datafile = Dialogs.openFile("Load Database File", "", {
            count: 1,
            descriptions: ["JSON"],
            extensions: ["*.json"]
        })[0];
    /*  */
        datafile = "data/peerteachers.json";
        var pts:PeerTeacher.PeerTeachers = Json.parse(getFileContents());
        for (pt in pts.peerteachers)
            peerteachers.set(pt.uin, pt);
    }
    
    private function getFileContents():String {
        var ifs = File.read(datafile);
        var s = ifs.readAll().toString();
        ifs.close();
        return s;
    }
    
/**
 *  @private
 *  Used with generateHTML.  Replaces the template string with the pt's information.
 *  @param template
 *  @param pt
 *  @return
 */
    private function replaceWithPT(template:String, pt:PeerTeacher):String {
        var s = StringTools.replace(template, "${firstname}", pt.firstname);
        s = StringTools.replace(s, "${lastname}", pt.lastname);
        s = StringTools.replace(s, "${email}", pt.email);
        s = StringTools.replace(s, "${image}", pt.image);
        
        var courses = new StringBuf();
        for (course in pt.courses)
            courses.add('<p>$course</p>\n');
        s = StringTools.replace(s, "${courses}", courses.toString());
        
        var hours = new StringBuf();
        hours.add("<table>");
        for (hour in pt.hours)
            hours.add('<tr><td>${hour.days}</td><td>${hour.hours}</td></tr>\n');
        hours.add("</table>");
        s = StringTools.replace(s, "${hours}", hours.toString());
        
        return s;
    }

}

typedef Crypto = haxe.crypto.Sha256