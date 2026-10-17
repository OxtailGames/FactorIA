package factoria.plugin.{{NAME}};

import com.google.android.play.core.integrity.IntegrityManagerFactory;
import com.google.android.play.core.integrity.IntegrityTokenRequest;

/**
 * Play Integrity, the classic request: the game's server makes a challenge, the device asks Google for a token that vouches for the
 * app and the device with that challenge inside, and the server sends the token to Google to decode (never trust it on the device).
 */
final class Integrity {
    private Integrity() {}

    static void token(Request r) {
        Failure f = Errors.noPlayServices(Backend.activity, r.doing());
        if (f != null) {
            r.reject(f);
            return;
        }
        String challenge = r.args.optString("challenge");
        IntegrityTokenRequest request = IntegrityTokenRequest.builder().setNonce(challenge).build();
        r.await(IntegrityManagerFactory.create(Backend.activity.getApplicationContext()).requestIntegrityToken(request), r.doing(),
                response -> r.resolve(Json.obj("token", response.token())));
    }
}
