package;

/** PeerTeacher Class
 *  @author  Timothy Foster
 *  @version 0.00.150802
 *
 *  Represents a peer teacher.  Basically just a struct of information.
 *  **************************************************************************/
@:forward
abstract PeerTeacher(PeerTeacherStruct) from PeerTeacherStruct {
/**
 *  Creates a PeerTeacher object.  Can be modified just by accessing its fields.
 *  @param uin The real UIN of the PT.
 */
    public inline function new(uin:String) {
        this = {
            firstname: "",
            lastname: "",
            uin: PTWebBuilder.Crypto.encode(uin),
            image: "",
            email: "",
            courses: [],
            hours: []
        };
    }
}
 
private typedef PeerTeacherStruct = {
    var firstname:String;
    var lastname:String;
    var uin:String;
    var image:String;
    var email:String;
    var courses:Array<String>;
    var hours:Array<OfficeHours>;
}

typedef OfficeHours = {
    var days:String;
    var hours:String;
}

typedef PeerTeachers = {
    var peerteachers:Array<PeerTeacher>;
}