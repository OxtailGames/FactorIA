// The Steam methods about the store: purchases (Steam's in-game purchases are DLC), the overlay and rich presence
// (docs/PLATFORM.md lists every method with its arguments and result).
#include <algorithm>

#include "backend.h"

namespace steam_plugin {

namespace {

struct Dlc {
    u32 appId = 0;
    bool available = false;
    std::string name;
};

// Every DLC Steam lists for the game.
std::vector<Dlc> dlc_list() {
    SteamApi& s = steam();
    std::vector<Dlc> out;
    const int count = s.SteamAPI_ISteamApps_GetDLCCount(s.apps);
    for (int i = 0; i < count; ++i) {
        Dlc d;
        char name[256] = {0};
        if (!s.SteamAPI_ISteamApps_BGetDLCDataByIndex(s.apps, i, &d.appId, &d.available, name, static_cast<int>(sizeof name))) continue;
        d.name = name;
        out.push_back(d);
    }
    return out;
}

const Dlc* find_dlc(const std::vector<Dlc>& list, u32 appId) {
    for (const Dlc& d : list)
        if (d.appId == appId) return &d;
    return nullptr;
}

struct Product {
    std::string id, storeId, type;
    u32 dlc = 0;  // the DLC's app id, 0 when the product has no numeric Steam id
};

std::vector<Product> products_of(const Json& args) {
    std::vector<Product> out;
    if (const Json* list = args.find("products"); list && list->is_array())
        for (const Json& e : list->items()) {
            Product p{e.string_or("id"), e.string_or("storeId", e.string_or("id")), e.string_or("type", "nonConsumable"), 0};
            parse_app_id(p.storeId, p.dlc);
            out.push_back(p);
        }
    return out;
}

Product product_of(const Json& args) {
    Product p{args.string_or("id"), args.string_or("storeId", args.string_or("id")), args.string_or("type", "nonConsumable"), 0};
    parse_app_id(p.storeId, p.dlc);
    return p;
}

std::string dlc_help(const Product& p) {
    return "Set ids.steam of the product " + quoted(p.id) + " in factoria.json platform.products to the app id of its DLC (the number in "
           "the DLC's store page URL, store.steampowered.com/app/<id>).";
}

std::string transaction_of(u32 appId) { return "dlc-" + std::to_string(appId); }

void purchases_products(FaRequest* r, const Json& a) {
    const std::vector<Dlc> dlc = dlc_list();
    Json out = Json::array();
    for (const Product& p : products_of(a)) {
        const Dlc* d = p.dlc ? find_dlc(dlc, p.dlc) : nullptr;
        if (!d) {
            warn_once("product:" + p.id, "The product " + quoted(p.id) + " is not a DLC of " + app_text() + " (ids.steam is " + quoted(p.storeId) +
                                             "): platform.purchases.products() leaves it out. " + dlc_help(p));
            continue;
        }
        // Steam gives a DLC's name, not a price: the game shows its own price text or none.
        out.push(Json::object()
                     .set("id", p.id)
                     .set("title", d->name)
                     .set("description", "")
                     .set("price", "")
                     .set("priceValue", Json())
                     .set("currency", "")
                     .set("type", p.type));
    }
    resolve(r, out);
}

void purchases_buy(FaRequest* r, const Json& a) {
    const Product p = product_of(a);
    if (p.type != "nonConsumable") {
        reject(r, "unavailable",
               "Steam cannot sell the " + std::string(p.type == "subscription" ? "subscription " : "consumable ") + quoted(p.id) +
                   " from the game: Steam's in-game purchases are DLC (a non-consumable product)",
               "Consumables and subscriptions on Steam are microtransactions (ISteamMicroTxn), which need the game's own server and "
               "Valve's web API, and this plugin does not do them. Sell a DLC instead: declare the product as \"nonConsumable\" and set "
               "ids.steam to the DLC's app id.");
        return;
    }
    if (!p.dlc) {
        reject(r, "unknownId", "The product " + quoted(p.id) + " has no DLC app id for Steam (ids.steam is " + quoted(p.storeId) + ")", dlc_help(p));
        return;
    }
    SteamApi& s = steam();
    if (s.SteamAPI_ISteamApps_BIsDlcInstalled(s.apps, p.dlc)) {  // already owned: nothing to buy
        resolve(r, Json::object().set("status", "purchased").set("productId", p.id).set("transactionId", transaction_of(p.dlc)));
        return;
    }
    if (!find_dlc(dlc_list(), p.dlc)) {
        reject(r, "unknownId", "Steam lists no DLC " + std::to_string(p.dlc) + " for " + app_text() + " (the product is " + quoted(p.id) + ")",
               "Check the DLC's app id, and that the DLC is added to the game's DLC list in the Steamworks partner site (App Admin > "
               "DLC) and published.");
        return;
    }
    // The purchase happens in the Steam overlay, outside the game: answer "pending". When the player owns the DLC, Steam sends
    // DlcInstalled and the game gets a "purchase" event (platform.on("purchase")).
    s.SteamAPI_ISteamFriends_ActivateGameOverlayToStore(s.friends, p.dlc, kOverlayToStoreAddToCartAndShow);
    resolve(r, Json::object().set("status", "pending").set("productId", p.id));
}

void purchases_restore(FaRequest* r, const Json& a) {
    SteamApi& s = steam();
    Json out = Json::array();
    for (const Product& p : products_of(a))
        if (p.type == "nonConsumable" && p.dlc && s.SteamAPI_ISteamApps_BIsDlcInstalled(s.apps, p.dlc))
            out.push(Json::object().set("productId", p.id).set("transactionId", transaction_of(p.dlc)));
    resolve(r, out);
}

void purchases_finish(FaRequest* r, const Json&) { resolve(r, Json::object()); }  // Steam has no transactions to finish

// ---------------------------------------------------------------------------------------------------------- overlay --
void overlay_open(FaRequest* r, const Json& a) {
    SteamApi& s = steam();
    if (!s.SteamAPI_ISteamUtils_IsOverlayEnabled(s.utils)) {
        reject(r, "unavailable", "The Steam overlay is not available",
               "The overlay needs Steam > Settings > In Game > \"Enable the Steam Overlay while in-game\", and the game started from the "
               "Steam client (or, in development, Steam running with a steam_appid.txt); it takes a few seconds to load after the game "
               "starts. On macOS it needs the game to be started by Steam.");
        return;
    }
    const std::string page = a.string_or("page");
    if (page == "achievements") {
        s.SteamAPI_ISteamFriends_ActivateGameOverlay(s.friends, "Achievements");
    } else if (page == "friends") {
        s.SteamAPI_ISteamFriends_ActivateGameOverlay(s.friends, "Friends");
    } else if (page == "leaderboards") {  // there is no overlay dialog for them: the game's leaderboards on the Community
        const std::string url = "https://steamcommunity.com/stats/" + std::to_string(backend().appId) + "/leaderboards/";
        s.SteamAPI_ISteamFriends_ActivateGameOverlayToWebPage(s.friends, url.c_str(), kWebPageDefault);
    } else {  // "store": the game's own page, or the DLC of a product
        u32 dlc = 0;
        if (!parse_app_id(a.string_or("storeId"), dlc)) dlc = backend().appId;
        s.SteamAPI_ISteamFriends_ActivateGameOverlayToStore(s.friends, dlc, kOverlayToStoreNone);
    }
    resolve(r, Json::object());
}

// ---------------------------------------------------------------------------------------------------------- presence --
void presence_set(FaRequest* r, const Json& a) {
    SteamApi& s = steam();
    std::vector<std::pair<std::string, std::string>> entries;
    const std::string text = a.string_or("text");
    if (!text.empty()) entries.emplace_back("status", text);
    if (const Json* data = a.find("data"); data && data->is_object())
        for (const auto& m : data->members())
            if (m.second.is_string() && !m.second.str().empty()) entries.emplace_back(m.first, m.second.str());
    // Steam's limits (isteamfriends.h): 30 keys, keys of 64 bytes, values of 256. Check them all before changing anything.
    if (entries.size() > 30) {
        reject(r, "failed", "Steam rich presence holds 30 keys at most, but " + std::to_string(entries.size()) + " were given",
               "Send fewer keys in platform.presence.set(text, data).");
        return;
    }
    for (const auto& e : entries)
        if (e.first.size() > 64 || e.second.size() > 256) {
            reject(r, "failed", "The rich presence key " + quoted(e.first) + " is too long for Steam: keys hold 64 bytes, values 256",
                   "Shorten it. Use steam_display with a localization token (\"#Status_InMatch\") for text that is long or translated.");
            return;
        }
    s.SteamAPI_ISteamFriends_ClearRichPresence(s.friends);  // set() replaces what was shown
    for (const auto& e : entries)
        if (!s.SteamAPI_ISteamFriends_SetRichPresence(s.friends, e.first.c_str(), e.second.c_str())) {
            reject(r, "failed", "Steam refused the rich presence key " + quoted(e.first),
                   "Rich presence holds 30 keys of 64 bytes with values of 256 bytes; \"status\", \"connect\" and \"steam_display\" have a "
                   "meaning for Steam (docs/PLATFORM.md, \"Steam\").");
            return;
        }
    resolve(r, Json::object());
}

}  // namespace

const std::map<std::string, Handler>& store_methods() {
    static const std::map<std::string, Handler> methods = {
        {"purchases.products", purchases_products},
        {"purchases.buy", purchases_buy},
        {"purchases.restore", purchases_restore},
        {"purchases.finish", purchases_finish},
        {"overlay.open", overlay_open},
        {"presence.set", presence_set},
    };
    return methods;
}

}  // namespace steam_plugin
