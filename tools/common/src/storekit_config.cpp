// Products.storekit: the catalog's products as an Xcode StoreKit configuration file (format version 3.0, which every Xcode
// since 14 reads and may rewrite in its newer one).
#include "fa/tooling/storekit_config.h"

#include <cmath>
#include <cstdint>
#include <cstdio>

namespace fa {

namespace {

// Stable 8-digit hex identifiers: the same seed and name always give the same one.
std::string stable_id(const std::string& seed, const std::string& name) {
    std::uint32_t h = 2166136261u;  // FNV-1a
    for (char c : seed + "/" + name) h = (h ^ static_cast<unsigned char>(c)) * 16777619u;
    char buf[16];
    std::snprintf(buf, sizeof buf, "%08X", h);
    return buf;
}

// "0.99": two decimals, as the App Store shows a price tier.
std::string display_price(double price) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "%.2f", std::isfinite(price) && price > 0 ? price : 0.0);
    return buf;
}

struct Storefront {
    const char* currency;
    const char* storefront;  // ISO 3166 alpha-3, as Xcode names them
    const char* locale;
};

// The storefront whose currency is the catalog's, so that prices look as the game's author wrote them.
Storefront storefront_for(const std::string& currency) {
    static const Storefront kTable[] = {
        {"USD", "USA", "en_US"}, {"EUR", "DEU", "de_DE"}, {"GBP", "GBR", "en_GB"}, {"JPY", "JPN", "ja_JP"},
        {"CAD", "CAN", "en_CA"}, {"AUD", "AUS", "en_AU"}, {"MXN", "MEX", "es_MX"}, {"BRL", "BRA", "pt_BR"},
        {"CHF", "CHE", "de_CH"}, {"SEK", "SWE", "sv_SE"}, {"NOK", "NOR", "nb_NO"}, {"DKK", "DNK", "da_DK"},
        {"PLN", "POL", "pl_PL"}, {"CNY", "CHN", "zh_CN"}, {"KRW", "KOR", "ko_KR"}, {"INR", "IND", "en_IN"}};
    for (const Storefront& s : kTable)
        if (currency == s.currency) return s;
    return kTable[0];
}

std::string text_in(const StoreKitLanguage& lang, const std::string& key, const std::string& plain) {
    if (!key.empty())
        if (auto it = lang.strings.find(key); it != lang.strings.end() && !it->second.empty()) return it->second;
    return plain;
}

Json localizations(const PlatformProduct& p, const std::string& locale, const std::vector<StoreKitLanguage>& languages) {
    const std::string fallbackName = p.title.empty() ? p.id : p.title;
    if (languages.empty())
        return Json::array({Json::object({{"description", p.description.empty() ? fallbackName : p.description},
                                          {"displayName", fallbackName},
                                          {"locale", locale}})});
    Json out = Json::array();
    for (const StoreKitLanguage& lang : languages) {
        const std::string name = text_in(lang, p.titleKey, fallbackName);
        const std::string description = text_in(lang, p.descriptionKey, p.description.empty() ? name : p.description);
        std::string tag = lang.tag;
        for (char& c : tag)
            if (c == '-') c = '_';
        out.push_back(Json::object({{"description", description}, {"displayName", name}, {"locale", tag}}));
    }
    return out;
}

}  // namespace

Json storekit_configuration(const PlatformCatalog& catalog, const std::string& backend, const std::string& groupName,
                            const std::string& seed, const std::vector<StoreKitLanguage>& languages) {
    const Storefront store = storefront_for(catalog.products.empty() ? "USD" : catalog.products.front().currency);
    Json products = Json::array();
    Json subscriptions = Json::array();
    const std::string groupId = stable_id(seed, "group/" + groupName);
    int level = 0;
    for (const PlatformProduct& p : catalog.products) {
        const std::string productId = p.store_id(backend);
        const std::string name = p.title.empty() ? p.id : p.title;
        if (p.type == "subscription") {
            subscriptions.push_back(Json::object({{"adHocOffers", Json::array()},
                                                  {"codeOffers", Json::array()},
                                                  {"displayPrice", display_price(p.price)},
                                                  {"familyShareable", false},
                                                  {"groupNumber", ++level},
                                                  {"internalID", stable_id(seed, productId)},
                                                  {"introductoryOffer", nullptr},
                                                  {"localizations", localizations(p, store.locale, languages)},
                                                  {"productID", productId},
                                                  {"recurringSubscriptionPeriod", "P1M"},
                                                  {"referenceName", name},
                                                  {"subscriptionGroupID", groupId},
                                                  {"type", "RecurringSubscription"},
                                                  {"winbackOffers", Json::array()}}));
        } else {
            products.push_back(Json::object({{"displayPrice", display_price(p.price)},
                                             {"familyShareable", false},
                                             {"internalID", stable_id(seed, productId)},
                                             {"localizations", localizations(p, store.locale, languages)},
                                             {"productID", productId},
                                             {"referenceName", name},
                                             {"type", p.type == "consumable" ? "Consumable" : "NonConsumable"}}));
        }
    }
    Json groups = Json::array();
    if (!subscriptions.empty())
        groups.push_back(Json::object({{"id", groupId},
                                       {"localizations", Json::array()},
                                       {"name", groupName.empty() ? std::string("Subscriptions") : groupName},
                                       {"subscriptions", subscriptions}}));
    return Json::object({{"identifier", stable_id(seed, "configuration")},
                         {"nonRenewingSubscriptions", Json::array()},
                         {"products", products},
                         {"settings", Json::object({{"_failTransactionsEnabled", false},
                                                    {"_locale", store.locale},
                                                    {"_storefront", store.storefront}})},
                         {"subscriptionGroups", groups},
                         {"version", Json::object({{"major", 3}, {"minor", 0}})}});
}

}  // namespace fa
