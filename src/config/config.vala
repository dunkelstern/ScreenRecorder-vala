using Json;

namespace ScreenRec {

    errordomain ConfigParseError {
        WRONG_TYPE,
        MISSING_ELEMENT,
        INVALID_VALUE
    }

    interface Config : GLib.Object {
        public abstract Json.Object serialize();
        public abstract void deserialize(Json.Object object) throws ConfigParseError;
    }

}
