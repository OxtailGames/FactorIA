package factoria.plugin.{{NAME}};

/**
 * A failure that teaches: one of the error codes of docs/PLATFORM.md (section 2), what went wrong, and how to fix it. It becomes
 * {@code reject(code, message, hint)} for the request that failed.
 */
final class Failure extends Exception {
    static final String UNAVAILABLE = "unavailable";
    static final String NOT_SIGNED_IN = "notSignedIn";
    static final String NOT_ALLOWED = "notAllowed";
    static final String UNKNOWN_ID = "unknownId";
    static final String NETWORK = "network";
    static final String FAILED = "failed";

    final String code;
    final String hint;

    Failure(String code, String message, String hint) {
        super(message);
        this.code = code;
        this.hint = hint;
    }
}
