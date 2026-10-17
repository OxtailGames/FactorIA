package factoria.plugin.{{NAME}};

import com.android.billingclient.api.BillingClient;
import com.android.billingclient.api.BillingClient.BillingResponseCode;
import com.android.billingclient.api.BillingClient.ProductType;
import com.android.billingclient.api.BillingClientStateListener;
import com.android.billingclient.api.BillingFlowParams;
import com.android.billingclient.api.BillingResult;
import com.android.billingclient.api.ConsumeParams;
import com.android.billingclient.api.AcknowledgePurchaseParams;
import com.android.billingclient.api.PendingPurchasesParams;
import com.android.billingclient.api.ProductDetails;
import com.android.billingclient.api.Purchase;
import com.android.billingclient.api.PurchasesUpdatedListener;
import com.android.billingclient.api.QueryProductDetailsParams;
import com.android.billingclient.api.QueryPurchasesParams;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Google Play Billing. One BillingClient for the whole run; every call waits for the connection first. A purchase is "finished" when
 * the game says so: a consumable is consumed, a non-consumable or a subscription is acknowledged (Google refunds a purchase that is
 * not acknowledged within three days). Everything here runs on the main thread.
 */
final class Purchases implements PurchasesUpdatedListener {
    private final BillingClient client;
    private final List<Runnable> waiting = new ArrayList<>();
    private final Set<String> announced = new HashSet<>();
    private boolean connecting;
    private BillingResult setup;
    private Request buying;
    private String buyingId = "";

    Purchases() {
        client = BillingClient.newBuilder(Backend.activity.getApplicationContext())
                .setListener(this)
                .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
                .enableAutoServiceReconnection()
                .build();
    }

    /** For the status command: where the Billing connection stands. */
    String state() {
        if (client.isReady()) return "ready";
        if (connecting) return "connecting";
        if (setup == null) return "not connected yet";
        return "not available: " + Errors.billingName(setup.getResponseCode()) + (setup.getDebugMessage().isEmpty() ? "" : " (" + setup.getDebugMessage() + ")");
    }

    // ------------------------------------------------------------------------------------------------ connection ----
    private void connect() {
        if (connecting) return;
        connecting = true;
        client.startConnection(new BillingClientStateListener() {
            @Override public void onBillingSetupFinished(BillingResult result) {
                connecting = false;
                setup = result;
                if (result.getResponseCode() != BillingResponseCode.OK) {
                    Backend.warn("Google Play Billing could not connect: " + state() + ". Purchases answer unavailable until it can; "
                            + Backend.plugin + ".status says what to fix (usually: no Play Store on this device, or no Google account).");
                }
                List<Runnable> run = new ArrayList<>(waiting);
                waiting.clear();
                for (Runnable w : run) w.run();
            }

            @Override public void onBillingServiceDisconnected() {} // enableAutoServiceReconnection(): the next call reconnects
        });
    }

    /** Runs {@code then} when Billing is connected; rejects the request when it cannot be. */
    private void ready(Request r, Runnable then) {
        if (client.isReady()) {
            then.run();
            return;
        }
        waiting.add(() -> {
            if (client.isReady()) r.run(x -> then.run(), null);
            else r.reject(Errors.billing(setup, r.doing()));
        });
        connect();
    }

    // -------------------------------------------------------------------------------------------------- helpers ----
    private static String productType(String catalogType) {
        return "subscription".equals(catalogType) ? ProductType.SUBS : ProductType.INAPP;
    }

    private static String firstProduct(Purchase p) {
        return p.getProducts().isEmpty() ? "" : p.getProducts().get(0);
    }

    /** A purchase as the game sees it: {status?, productId, transactionId, receipt}. The transaction id is Google's purchase token. */
    static JSONObject entry(Purchase p, boolean withStatus) {
        boolean paid = p.getPurchaseState() == Purchase.PurchaseState.PURCHASED;
        // The receipt carries what a server needs: the signed JSON (package, product, token, order) and its signature, which the Play
        // Console licence key verifies. The purchase token also works with the Google Play Developer API (purchases.products.get).
        String receipt = paid ? Json.obj("signedData", p.getOriginalJson(), "signature", p.getSignature()).toString() : null;
        return Json.obj("status", withStatus ? (paid ? "purchased" : "pending") : null, "productId", firstProduct(p),
                "transactionId", paid ? p.getPurchaseToken() : null, "receipt", receipt);
    }

    /** The offer a subscription is bought with: its base plan (no offer id), else the first one Google shows. */
    private static ProductDetails.SubscriptionOfferDetails offer(ProductDetails d) {
        List<ProductDetails.SubscriptionOfferDetails> offers = d.getSubscriptionOfferDetails();
        if (offers == null || offers.isEmpty()) return null;
        for (ProductDetails.SubscriptionOfferDetails o : offers) if (o.getOfferId() == null) return o;
        return offers.get(0);
    }

    private static JSONObject product(ProductDetails d, String catalogType) {
        String price = "";
        long micros = 0;
        String currency = "";
        if (ProductType.SUBS.equals(d.getProductType())) {
            ProductDetails.SubscriptionOfferDetails o = offer(d);
            if (o != null) { // the last phase is the one that renews: the earlier ones are trials and introductory prices
                List<ProductDetails.PricingPhase> phases = o.getPricingPhases().getPricingPhaseList();
                ProductDetails.PricingPhase last = phases.get(phases.size() - 1);
                price = last.getFormattedPrice();
                micros = last.getPriceAmountMicros();
                currency = last.getPriceCurrencyCode();
            }
        } else {
            List<ProductDetails.OneTimePurchaseOfferDetails> offers = d.getOneTimePurchaseOfferDetailsList();
            ProductDetails.OneTimePurchaseOfferDetails o = offers != null && !offers.isEmpty() ? offers.get(0) : d.getOneTimePurchaseOfferDetails();
            if (o != null) {
                price = o.getFormattedPrice();
                micros = o.getPriceAmountMicros();
                currency = o.getPriceCurrencyCode();
            }
        }
        return Json.obj("id", d.getProductId(), "title", d.getName(), "description", d.getDescription(), "price", price,
                "priceValue", micros / 1e6, "currency", currency, "type", catalogType);
    }

    /** Asks Google for one product; rejects the request when it is unknown. */
    private void details(Request r, String storeId, String type, Request.Step<ProductDetails> then) {
        QueryProductDetailsParams.Product wanted = QueryProductDetailsParams.Product.newBuilder().setProductId(storeId).setProductType(type).build();
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(Collections.singletonList(wanted)).build(), (result, found) -> {
            if (result.getResponseCode() != BillingResponseCode.OK) {
                r.reject(Errors.billing(result, r.doing()));
            } else if (found.getProductDetailsList().isEmpty()) {
                r.reject(new Failure(Failure.UNKNOWN_ID, r.doing() + " failed: Google Play does not know the product " + JSONObject.quote(storeId), Errors.PRODUCT_HINT));
            } else {
                r.run(then, found.getProductDetailsList().get(0));
            }
        });
    }

    private void owned(Request r, String type, Request.Step<List<Purchase>> then) {
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(type).build(), (result, list) -> {
            if (result.getResponseCode() == BillingResponseCode.OK) r.run(then, list);
            else r.reject(Errors.billing(result, r.doing()));
        });
    }

    // ------------------------------------------------------------------------------------------------------ events ----
    /** Tells the game about purchases that no buy() is waiting for and that it has not finished: at start and on every resume. */
    void resume() {
        Runnable ask = () -> {
            for (String type : new String[] {ProductType.INAPP, ProductType.SUBS}) {
                client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(type).build(), (result, list) -> {
                    if (result.getResponseCode() == BillingResponseCode.OK) for (Purchase p : list) announce(p);
                });
            }
        };
        if (client.isReady()) {
            ask.run();
        } else {
            waiting.add(() -> { if (client.isReady()) ask.run(); });
            connect();
        }
    }

    /** One `purchase` event per purchase and state: a pending one, and later its purchased state. A finished purchase is not an event. */
    private void announce(Purchase p) {
        int state = p.getPurchaseState();
        if (state == Purchase.PurchaseState.UNSPECIFIED_STATE) return;
        if (state == Purchase.PurchaseState.PURCHASED && p.isAcknowledged()) return;
        if (announced.add(p.getPurchaseToken() + ":" + state)) Backend.emit("purchase", entry(p, true).toString());
    }

    @Override public void onPurchasesUpdated(BillingResult result, List<Purchase> list) {
        Request r = buying;
        String id = buyingId;
        boolean mine = r != null && !r.isAnswered();
        if (result.getResponseCode() == BillingResponseCode.OK && list != null) {
            for (Purchase p : list) {
                if (mine && p.getProducts().contains(id)) {
                    announced.add(p.getPurchaseToken() + ":" + p.getPurchaseState());
                    buying = null;
                    r.resolve(entry(p, true));
                } else {
                    announce(p);
                }
            }
        } else if (mine) {
            buying = null;
            if (result.getResponseCode() == BillingResponseCode.USER_CANCELED) r.resolve(Json.obj("status", "cancelled", "productId", id));
            else r.reject(Errors.billing(result, r.doing()));
        }
    }

    // ------------------------------------------------------------------------------------------------------ calls ----
    void products(Request r) {
        JSONArray wanted = r.args.optJSONArray("products");
        if (wanted == null || wanted.length() == 0) {
            r.resolve(new JSONArray());
            return;
        }
        ready(r, () -> {
            JSONArray out = new JSONArray();
            query(r, wanted, ProductType.INAPP, out, () -> query(r, wanted, ProductType.SUBS, out, () -> r.resolve(out)));
        });
    }

    /** One Billing query per product type (Billing allows no mixed list). Products Google does not know are left out, with a log line. */
    private void query(Request r, JSONArray wanted, String type, JSONArray out, Runnable next) {
        Map<String, String> catalogTypes = new LinkedHashMap<>(); // store id -> the catalog's type
        List<QueryProductDetailsParams.Product> list = new ArrayList<>();
        for (int i = 0; i < wanted.length(); i++) {
            JSONObject p = wanted.optJSONObject(i);
            if (p == null || !productType(p.optString("type")).equals(type)) continue;
            String storeId = p.optString("storeId", p.optString("id"));
            catalogTypes.put(storeId, p.optString("type"));
            list.add(QueryProductDetailsParams.Product.newBuilder().setProductId(storeId).setProductType(type).build());
        }
        if (list.isEmpty()) {
            next.run();
            return;
        }
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(list).build(), (result, found) -> {
            if (result.getResponseCode() != BillingResponseCode.OK) {
                r.reject(Errors.billing(result, r.doing()));
                return;
            }
            r.run(x -> {
                for (ProductDetails d : found.getProductDetailsList()) {
                    out.put(product(d, catalogTypes.remove(d.getProductId())));
                }
                for (String missing : catalogTypes.keySet()) {
                    Backend.warn("Google Play does not know the product " + JSONObject.quote(missing) + ", so products() leaves it out. " + Errors.PRODUCT_HINT);
                }
                next.run();
            }, null);
        });
    }

    void buy(Request r) {
        String storeId = r.args.optString("storeId", r.args.optString("id"));
        String type = productType(r.args.optString("type"));
        if (buying != null && !buying.isAnswered()) {
            r.reject(new Failure(Failure.FAILED, r.doing() + " failed: another purchase is still on screen", "Wait for the first purchase to end before starting the next."));
            return;
        }
        ready(r, () -> details(r, storeId, type, d -> {
            BillingFlowParams.ProductDetailsParams.Builder item = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d);
            if (ProductType.SUBS.equals(type)) {
                ProductDetails.SubscriptionOfferDetails o = offer(d);
                if (o == null) {
                    r.reject(new Failure(Failure.FAILED, r.doing() + " failed: the subscription has no active base plan",
                            "Create a base plan in Play Console (Monetize with Play > Products > Subscriptions) and activate it."));
                    return;
                }
                item.setOfferToken(o.getOfferToken());
            }
            buying = r;
            buyingId = storeId;
            BillingResult launched = client.launchBillingFlow(Backend.activity,
                    BillingFlowParams.newBuilder().setProductDetailsParamsList(Collections.singletonList(item.build())).build());
            if (launched.getResponseCode() != BillingResponseCode.OK) {
                buying = null;
                r.reject(Errors.billing(launched, r.doing()));
            } else {
                r.beginInteraction(); // Google's screen is up: the player takes as long as they need
            }
        }));
    }

    void finish(Request r) {
        String token = r.args.optString("transactionId");
        boolean consumable = "consumable".equals(r.args.optString("type"));
        ready(r, () -> owned(r, productType(r.args.optString("type")), list -> {
            Purchase found = null;
            for (Purchase p : list) if (p.getPurchaseToken().equals(token)) found = p;
            if (found == null) {
                r.reject(new Failure(Failure.UNKNOWN_ID, r.doing() + " failed: Google Play has no purchase with this transactionId",
                        "Finish a purchase with the transactionId of a buy() result, a purchase event or a restore() entry of this run. If it was finished "
                                + "already, or refunded, there is nothing left to do."));
            } else if (found.getPurchaseState() != Purchase.PurchaseState.PURCHASED) {
                r.reject(new Failure(Failure.FAILED, r.doing() + " failed: the payment is still pending",
                        "Grant and finish it when the purchase event arrives with status \"purchased\"."));
            } else if (consumable) {
                client.consumeAsync(ConsumeParams.newBuilder().setPurchaseToken(token).build(), (result, t) -> answer(r, result));
            } else if (found.isAcknowledged()) {
                r.resolve(Json.obj());
            } else {
                client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build(), result -> answer(r, result));
            }
        }));
    }

    private static void answer(Request r, BillingResult result) {
        if (result.getResponseCode() == BillingResponseCode.OK) r.resolve(Json.obj());
        else r.reject(Errors.billing(result, r.doing()));
    }

    /** What the player owns that is not used up: non-consumables and active subscriptions of the catalog. */
    void restore(Request r) {
        JSONArray wanted = r.args.optJSONArray("products");
        ready(r, () -> owned(r, ProductType.INAPP, inapp -> owned(r, ProductType.SUBS, subs -> {
            JSONArray out = new JSONArray();
            List<Purchase> all = new ArrayList<>(inapp);
            all.addAll(subs);
            for (Purchase p : all) {
                if (p.getPurchaseState() == Purchase.PurchaseState.PURCHASED && keeps(wanted, firstProduct(p))) out.put(entry(p, false));
            }
            r.resolve(out);
        })));
    }

    private static boolean keeps(JSONArray wanted, String storeId) {
        if (wanted == null) return true;
        for (int i = 0; i < wanted.length(); i++) {
            JSONObject p = wanted.optJSONObject(i);
            if (p != null && storeId.equals(p.optString("storeId", p.optString("id"))) && !"consumable".equals(p.optString("type"))) return true;
        }
        return false;
    }
}
