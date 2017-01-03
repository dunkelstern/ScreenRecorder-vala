using Json;

namespace ScreenRec {

    interface Config {
        public abstract void serialize();
        public abstract void deserialize(Json.Node json);
    }

}
