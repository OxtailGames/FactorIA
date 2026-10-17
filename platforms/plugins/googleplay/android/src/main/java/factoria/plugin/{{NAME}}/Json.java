package factoria.plugin.{{NAME}};

import org.json.JSONException;
import org.json.JSONObject;

/** The few JSON helpers the plugin needs (org.json throws checked exceptions for what cannot go wrong here). */
final class Json {
    private Json() {}

    /** {@code obj("id", "x", "n", 3)} is {"id":"x","n":3}. A null value leaves the key out. */
    static JSONObject obj(Object... pairs) {
        JSONObject o = new JSONObject();
        try {
            for (int i = 0; i + 1 < pairs.length; i += 2) o.put((String) pairs[i], pairs[i + 1]);
        } catch (JSONException e) {
            throw new IllegalStateException(e);
        }
        return o;
    }

    /** The JSON text of a result: a JSONObject, a JSONArray, a string, a number, a boolean, or null. */
    static String text(Object value) {
        if (value == null || value == JSONObject.NULL) return "null";
        if (value instanceof String) return JSONObject.quote((String) value);
        return value.toString();
    }
}
