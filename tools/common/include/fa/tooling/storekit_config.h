// The StoreKit configuration file of a game: Products.storekit, generated from the products of factoria.json's `platform`
// catalog (docs/PLATFORM.md, section Apple, "Testing purchases without App Store Connect"). Xcode sells the products
// of this file to a game run from Xcode, with no App Store Connect, sandbox account or network, and lets the developer
// edit them and fail or approve transactions at will (Debug > StoreKit > Manage Transactions).
//
// Pure text: it works the same on every host.
#pragma once

#include <string>

#include "fa/core/json.h"
#include "fa/services/platform.h"

namespace fa {

// The configuration for `catalog`'s products as the backend `backend` ("apple") sells them: the product ids are the
// catalog's `ids.apple`, else `id`. consumable and nonConsumable become the matching products, a subscription an
// auto-renewable one (monthly) in a single subscription group named `groupName`; the prices and titles come from the catalog;
// the storefront follows the currency of the first product (USD: United States). `seed` (the bundle id) makes the
// identifiers inside the file stable, so exporting twice writes the same file.
Json storekit_configuration(const PlatformCatalog& catalog, const std::string& backend, const std::string& groupName,
                            const std::string& seed);

// The file name the exports write, next to the Xcode project.
inline constexpr const char* kStoreKitFileName = "Products.storekit";

}  // namespace fa
