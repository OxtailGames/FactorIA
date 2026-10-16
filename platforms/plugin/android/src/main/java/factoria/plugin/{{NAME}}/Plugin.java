package factoria.plugin.{{NAME}};

/** The Java side of the {{NAME}} native plugin. src/plugin.c calls add() through JNI; put the calls of your SDK here. */
public final class Plugin {
    private Plugin() {}

    public static double add(double a, double b) {
        return a + b;
    }
}
