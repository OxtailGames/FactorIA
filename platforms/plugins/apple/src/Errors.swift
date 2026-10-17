// Turns what GameKit, StoreKit and Foundation throw into the error codes of docs/PLATFORM.md, with a message that says what
// went wrong and a hint that says how to fix it.
import Foundation
import GameKit
import StoreKit

let gameCenterHint = "Game Center needs the Game Center capability on the App ID (Certificates, Identifiers & Profiles), the "
    + "entitlement com.apple.developer.game-center in the signed app (the export writes it), and a player signed in to Game Center "
    + "(iOS: Settings > Game Center; macOS: System Settings > Game Center). In the simulator or with a test build, sign in with a "
    + "sandbox Apple Account. See docs/PLATFORM.md, section Apple."

/// `fromSignIn`: the error is the answer to platform.signIn() itself, so "call signIn first" would be no help.
func notSignedIn(_ detail: String? = nil, fromSignIn: Bool = false) -> Failure {
    Failure(.notSignedIn, "the player is not signed in to Game Center" + (detail.map { ": \($0)" } ?? ""),
            hint: (fromSignIn ? "" : "Call platform.signIn() first (it shows the Game Center sign-in when needed). ") + gameCenterHint)
}

/// A Game Center error number (GKError.Code raw values: the names differ between SDKs, the numbers do not).
func gameKitFailure(_ error: NSError, doing action: String) -> Failure {
    let detail = error.localizedDescription
    switch error.code {
    case 6:  // notAuthenticated
        return notSignedIn(detail)
    case 3, 33:  // communicationsFailure, connectionTimeout
        return Failure(.network, "\(action) failed: Game Center could not be reached (\(detail))",
                       hint: "Check the internet connection and try again.")
    case 4, 10, 14, 32:  // userDenied, parentalControlsBlocked, underage, notAuthorized
        return Failure(.notAllowed, "\(action) was refused: \(detail)",
                       hint: "Game Center or the player's restrictions (Screen Time, parental controls, privacy settings) do not allow it.")
    case 15:  // gameUnrecognized
        return Failure(.failed, "\(action) failed: Game Center does not know this app (\(detail))",
                       hint: "Create the app in App Store Connect with this bundle id, turn Game Center on for it, and test with a signed build (docs/PLATFORM.md, section Apple).")
    case 17:  // invalidParameter
        return Failure(.unknownId, "\(action) failed: Game Center refused the id (\(detail))",
                       hint: "Create the achievement or leaderboard in App Store Connect (Game Center) with exactly the id that factoria.json maps to \"apple\" (platform.<section>[].ids.apple, else its id).")
    case 35:  // iCloudUnavailable
        return Failure(.unavailable, "\(action) failed: iCloud is not available (\(detail))",
                       hint: "Sign in to iCloud on the device (Game Center stores its data there).")
    case 100:  // friendListDescriptionMissing
        return Failure(.failed, "\(action) failed: the app has no NSGKFriendListUsageDescription",
                       hint: "Reading friends needs that key in Info.plist, with the reason you ask for the friends list.")
    case 101, 102:  // friendListRestricted, friendListDenied
        return Failure(.notAllowed, "\(action) failed: the player does not share their friends list with this app (\(detail))",
                       hint: "Ask for the global leaderboard instead, or let the player allow friends access in Game Center settings.")
    default:
        return Failure(.failed, "\(action) failed: \(detail) (GameKit error \(error.code))",
                       hint: "GKError code \(error.code): see GKError.h in the GameKit headers.")
    }
}

func storeKitFailure(_ error: Error, doing action: String) -> Failure {
    if let failure = error as? Failure { return failure }
    if let kit = error as? StoreKitError {
        switch kit {
        case .networkError:
            return Failure(.network, "\(action) failed: the App Store could not be reached (\(kit.localizedDescription))",
                           hint: "Check the internet connection and try again.")
        case .notAvailableInStorefront:
            return Failure(.unavailable, "\(action) failed: the product is not sold in the player's country",
                           hint: "Add the country to the product's availability in App Store Connect.")
        case .notEntitled:
            return Failure(.notAllowed, "\(action) failed: the player is not entitled to it", hint: nil)
        case .userCancelled:
            return Failure(.notAllowed, "\(action) was cancelled by the player", hint: nil)
        case .unknown, .systemError:
            return Failure(.unavailable, "\(action) failed: the App Store gave this app no answer (\(kit.localizedDescription))",
                           hint: "This is what StoreKit says to an app it does not serve: one that is not signed with a development team, "
                               + "or a device with no Apple Account signed in to the App Store. Run the game from the Xcode project that "
                               + "`factoria export --platform ios` writes (it sells Products.storekit), or from TestFlight; the command "
                               + "apple.status (fa.call from a script) lists what is missing. See docs/PLATFORM.md, section Apple.")
        default:
            break
        }
    }
    if let purchase = error as? Product.PurchaseError {
        switch purchase {
        case .purchaseNotAllowed:
            return Failure(.notAllowed, "\(action) failed: purchases are not allowed for this account",
                           hint: "Screen Time restrictions (Settings > Screen Time > Content & Privacy Restrictions > iTunes & App Store Purchases) or a managed device can block in-app purchases.")
        case .productUnavailable:
            return Failure(.unknownId, "\(action) failed: the App Store says the product is unavailable",
                           hint: "Check the product in App Store Connect: it needs a price, a localization and an approved or Ready to Submit state, and the Paid Apps agreement must be active.")
        default:
            break
        }
    }
    return foundationFailure(error, doing: action)
}

func foundationFailure(_ error: Error, doing action: String) -> Failure {
    if let failure = error as? Failure { return failure }
    let ns = error as NSError
    if ns.domain == GKErrorDomain { return gameKitFailure(ns, doing: action) }
    if ns.domain == NSURLErrorDomain {
        return Failure(.network, "\(action) failed: \(ns.localizedDescription)", hint: "Check the internet connection and try again.")
    }
    return Failure(.failed, "\(action) failed: \(ns.localizedDescription) (\(ns.domain) \(ns.code))", hint: nil)
}
