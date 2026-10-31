// Cloudflare Worker entry: binds the D1 database and the secrets (ADMIN_TOKEN, HMAC_SECRET) to the request handler.

import { createApp } from "./app.js";
import { D1Store } from "./store_d1.js";

export default {
    async fetch(request, env) {
        return createApp({ store: new D1Store(env.DB), env }).fetch(request);
    },
};
