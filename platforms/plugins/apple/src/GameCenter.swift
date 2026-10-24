// Game Center: sign-in, achievements, leaderboards and the dashboard overlay (docs/PLATFORM.md, "Apple").
import Foundation
import GameKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class GameCenter: @unchecked Sendable {
    private let lock = NSLock()
    private var waiters: [Request] = []       // signIn() calls waiting for the answer of Game Center
    private var handlerInstalled = false
    private var lastSignedIn: Bool?           // what the last `player` event said (nil: none yet)
    private var presentAttempts = 0
    private var sheetShown = false            // Game Center asked for its sign-in sheet: the player is busy, do not time out

    // ------------------------------------------------------------------------------------------------- sign in ----
    func playerJSON() -> JSONObject {
        let local = GKLocalPlayer.local
        guard local.isAuthenticated else { return ["id": "", "name": "", "signedIn": false] }
        return ["id": local.gamePlayerID, "name": local.displayName, "signedIn": true]
    }

    /// player.signIn: the Game Center sign-in (a sheet the first time), then `{id, name, signedIn}`.
    func signIn(_ request: Request) {
        DispatchQueue.main.async { [self] in
            let local = GKLocalPlayer.local
            if local.isAuthenticated {
                request.resolve(self.playerJSON())
                return
            }
            self.lock.lock()
            self.waiters.append(request)
            let first = !self.handlerInstalled
            self.handlerInstalled = true
            self.lock.unlock()
            if first {
                NotificationCenter.default.addObserver(forName: .GKPlayerAuthenticationDidChangeNotificationName, object: nil, queue: .main) { [weak self] _ in
                    self?.announceIfChanged()
                }
            }
            // Setting the handler starts the authentication; setting it again retries after a failure.
            self.install(local)
            // A Game Center that neither signs in, fails nor shows its sheet (an unsigned process, no network) is silent:
            // answer after a while so the game does not wait forever. A sheet on screen means the player is busy: wait.
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [self] in
                lock.lock()
                let stuck = !sheetShown && waiters.contains { $0 === request }
                lock.unlock()
                if stuck { finishSignIn(error: nil, silent: true) }
            }
        }
    }

    private func install(_ local: GKLocalPlayer) {
        local.authenticateHandler = { [weak self] viewController, error in
            self?.authentication(viewController: viewController, error: error)
        }
    }

    #if canImport(UIKit)
    private func authentication(viewController: UIViewController?, error: Error?) {
        if let viewController = viewController {
            noteSheet()
            present(viewController)
            return
        }
        finishSignIn(error: error)
    }

    /// The Game Center sign-in sheet goes on the app's key window (the view controller that sokol_app made the root).
    private func present(_ viewController: UIViewController) {
        if let top = GameCenter.topViewController() {
            presentAttempts = 0
            top.present(viewController, animated: true)
            return
        }
        presentAttempts += 1
        if presentAttempts > 20 {
            presentAttempts = 0
            Host.shared.log(2, "Game Center wants to show its sign-in sheet but the app has no window to show it on")
            finishSignIn(error: Failure(.notSignedIn, "the app has no window for the Game Center sign-in sheet"))
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in self?.present(viewController) }
    }

    static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windows = scenes.sorted { $0.activationState.rawValue < $1.activationState.rawValue }.flatMap { $0.windows }
        let window = windows.first(where: { $0.isKeyWindow }) ?? windows.first(where: { $0.rootViewController != nil })
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
    #else
    private func authentication(viewController: NSViewController?, error: Error?) {
        if let viewController = viewController {
            // The sign-in window needs a running application: a tool or a test process cannot show it, and would wait for ever.
            if NSApp == nil {
                finishSignIn(error: Failure(.notSignedIn, "Game Center wants to show its sign-in window, but this process has no application window to show it on",
                                            hint: "Sign in under System Settings > Game Center, then run the game as an application. " + gameCenterHint))
                return
            }
            noteSheet()
            DispatchQueue.main.async {
                if let dialog = viewController as? (NSViewController & GKViewController) {
                    GKDialogController.shared().parentWindow = NSApp.keyWindow ?? NSApp.mainWindow
                    GKDialogController.shared().present(dialog)
                } else {
                    Host.shared.log(2, "Game Center gave a sign-in view controller that the dialog controller cannot show")
                }
            }
            return
        }
        finishSignIn(error: error)
    }
    #endif

    private func noteSheet() {
        lock.lock()
        sheetShown = true
        lock.unlock()
    }

    private func finishSignIn(error: Error?, silent: Bool = false) {
        let local = GKLocalPlayer.local
        lock.lock()
        let waiting = waiters
        waiters = []
        sheetShown = false
        lock.unlock()
        if local.isAuthenticated {
            let player = playerJSON()
            for request in waiting { request.resolve(player) }
        } else {
            let detail = silent ? "Game Center did not answer within 20 seconds" : error.map { ($0 as NSError).localizedDescription }
            let failure = (error as? Failure) ?? notSignedIn(detail, fromSignIn: true)
            for request in waiting { request.reject(failure) }
        }
        announceIfChanged()
    }

    /// The `player` event: only when the sign-in state differs from the last one told.
    private func announceIfChanged() {
        let player = playerJSON()
        let signedIn = player["signedIn"] as? Bool ?? false
        lock.lock()
        let changed = lastSignedIn != signedIn && !(lastSignedIn == nil && !signedIn)
        lastSignedIn = signedIn
        lock.unlock()
        if changed { Host.shared.emit("player", player) }
    }

    /// Every method but signIn needs a signed-in player.
    func requireSignedIn() throws {
        guard GKLocalPlayer.local.isAuthenticated else { throw notSignedIn() }
    }

    // --------------------------------------------------------------------------------------------- achievements ----
    private func loaded() async throws -> [String: GKAchievement] {
        do {
            let all = try await GKAchievement.loadAchievements()
            var byId: [String: GKAchievement] = [:]
            for a in all { byId[a.identifier] = a }
            return byId
        } catch {
            throw foundationFailure(error, doing: "reading the achievements")
        }
    }

    /// Game Center tells "no such achievement" with a generic error: find out whether the id exists at all.
    private func explainReportFailure(_ error: Error, id: String, storeId: String) async -> Failure {
        if let descriptions = try? await GKAchievementDescription.loadAchievementDescriptions(),
           !descriptions.contains(where: { $0.identifier == storeId }) {
            let known = descriptions.map { $0.identifier }.sorted().joined(separator: ", ")
            return Failure(.unknownId, "Game Center has no achievement \"\(storeId)\" for this app (known: \(known.isEmpty ? "none" : known))",
                           hint: "Create it in App Store Connect > your app > Services > Game Center > Achievements with exactly this id, "
                               + "or set platform.achievements[].ids.apple for \"\(id)\" in factoria.json.")
        }
        return foundationFailure(error, doing: "reporting the achievement \"\(storeId)\"")
    }

    func unlock(id: String, storeId: String) async throws -> JSONObject {
        try requireSignedIn()
        let existing = try await loaded()[storeId]
        if existing?.isCompleted == true { return ["id": id, "unlocked": true, "newly": false] }
        let achievement = existing ?? GKAchievement(identifier: storeId)
        achievement.percentComplete = 100
        achievement.showsCompletionBanner = true
        do {
            try await GKAchievement.report([achievement])
        } catch {
            throw await explainReportFailure(error, id: id, storeId: storeId)
        }
        return ["id": id, "unlocked": true, "newly": true]
    }

    func progress(id: String, storeId: String, fraction: Double) async throws -> JSONObject {
        try requireSignedIn()
        let existing = try await loaded()[storeId]
        let before = existing?.isCompleted == true ? 100 : (existing?.percentComplete ?? 0)
        let percent = min(100, max(before, fraction * 100))
        if percent > before {
            let achievement = existing ?? GKAchievement(identifier: storeId)
            achievement.percentComplete = percent
            achievement.showsCompletionBanner = true
            do {
                try await GKAchievement.report([achievement])
            } catch {
                throw await explainReportFailure(error, id: id, storeId: storeId)
            }
        }
        return ["id": id, "progress": percent / 100, "unlocked": percent >= 100]
    }

    func list(_ entries: [CatalogEntry]) async throws -> [JSONObject] {
        try requireSignedIn()
        let byId = try await loaded()
        return entries.map { entry in
            let a = byId[entry.storeId]
            let unlocked = a?.isCompleted ?? false
            return ["id": entry.id, "unlocked": unlocked, "progress": unlocked ? 1.0 : (a?.percentComplete ?? 0) / 100]
        }
    }

    func resetAchievements() async throws -> JSONObject {
        try requireSignedIn()
        do {
            try await GKAchievement.resetAchievements()
        } catch {
            throw foundationFailure(error, doing: "resetting the achievements")
        }
        return [:]
    }

    // ---------------------------------------------------------------------------------------------- leaderboards ----
    private func leaderboard(id: String, storeId: String) async throws -> GKLeaderboard {
        let boards: [GKLeaderboard]
        do {
            boards = try await GKLeaderboard.loadLeaderboards(IDs: [storeId])
        } catch {
            throw foundationFailure(error, doing: "loading the leaderboard \"\(storeId)\"")
        }
        guard let board = boards.first else {
            throw Failure(.unknownId, "Game Center has no leaderboard \"\(storeId)\" for this app",
                          hint: "Create it in App Store Connect > your app > Services > Game Center > Leaderboards with exactly this id, "
                              + "or set platform.leaderboards[].ids.apple for \"\(id)\" in factoria.json.")
        }
        return board
    }

    /// The period of a leaderboard request: `period` ("allTime", "daily" or "weekly") from the catalog.
    ///
    /// Game Center's own recurring boards (set up in App Store Connect) are used as they are, at their current occurrence:
    /// the app does not pick the occurrence and the request's `periodKey` is not used. A classic board is read with the
    /// `.today` or `.week` time scope of the same board. Both start periods at Apple's times (a recurring board's start date,
    /// from App Store Connect; `.today` and `.week` are Game Center's own days and weeks), not at the player's midnight.
    struct Period {
        let scope: GKLeaderboard.TimeScope
        /// The current occurrence of a recurring board, when Apple says: ISO 8601 UTC text.
        let start: String?
        let end: String?

        var json: JSONObject {
            var out: JSONObject = [:]
            if let start = start { out["periodStart"] = start }
            if let end = end { out["periodEnd"] = end }
            return out
        }
    }

    private static func iso(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    static func period(of board: GKLeaderboard, requested: String) -> Period {
        if board.type == .recurring {
            // The board is the period: its occurrence is the current one, read with any scope.
            var start: String? = nil, end: String? = nil
            if let startDate = board.startDate {
                start = iso(startDate)
                if board.duration > 0 { end = iso(startDate.addingTimeInterval(board.duration)) }
            }
            if end == nil, let next = board.nextStartDate { end = iso(next) }
            return Period(scope: .allTime, start: start, end: end)
        }
        switch requested {
        case "daily": return Period(scope: .today, start: nil, end: nil)
        case "weekly": return Period(scope: .week, start: nil, end: nil)
        default: return Period(scope: .allTime, start: nil, end: nil)
        }
    }

    func submit(id: String, storeId: String, order: String, period requested: String, score: Int) async throws -> JSONObject {
        try requireSignedIn()
        let board = try await leaderboard(id: id, storeId: storeId)
        let period = GameCenter.period(of: board, requested: requested)
        do {
            try await board.submitScore(score, context: 0, player: GKLocalPlayer.local)
        } catch {
            throw foundationFailure(error, doing: "submitting the score to \"\(storeId)\"")
        }
        // The player's best after this one: the server's entry for the player, combined with the score just sent (the
        // server may not have counted it yet).
        var best = score
        if let (mine, _, _) = try? await board.loadEntries(for: .global, timeScope: period.scope, range: NSRange(location: 1, length: 1)),
           let entry = mine {
            best = order == "ascending" ? min(entry.score, score) : max(entry.score, score)
        }
        var out: JSONObject = ["id": id, "score": score, "best": best]
        out.merge(period.json) { _, new in new }
        return out
    }

    private func entryJSON(_ entry: GKLeaderboard.Entry) -> JSONObject {
        let player = entry.player
        return ["rank": entry.rank, "name": player.displayName, "score": entry.score, "playerId": player.gamePlayerID,
                "isPlayer": player.gamePlayerID == GKLocalPlayer.local.gamePlayerID]
    }

    /// The entries as the list the contract wants; of a recurring board, `{entries, periodStart, periodEnd}` (the engine gives
    /// the game the list with the two as properties).
    private func answer(_ entries: [GKLeaderboard.Entry], _ period: Period) -> Any {
        let list = entries.map(entryJSON)
        if period.start == nil && period.end == nil { return list }
        var out: JSONObject = ["entries": list]
        out.merge(period.json) { _, new in new }
        return out
    }

    func entries(id: String, storeId: String, range: String, period requested: String, count: Int) async throws -> Any {
        try requireSignedIn()
        let board = try await leaderboard(id: id, storeId: storeId)
        let period = GameCenter.period(of: board, requested: requested)
        let action = "reading the leaderboard \"\(storeId)\""
        do {
            switch range {
            case "friends":
                let (_, entries, _) = try await board.loadEntries(for: .friendsOnly, timeScope: period.scope, range: NSRange(location: 1, length: count))
                return answer(entries, period)
            case "around":
                let (mine, _, _) = try await board.loadEntries(for: .global, timeScope: period.scope, range: NSRange(location: 1, length: 1))
                guard let me = mine else { return answer([], period) }  // no score yet: nobody is "around" the player
                let start = max(1, me.rank - count / 2)
                let (_, entries, _) = try await board.loadEntries(for: .global, timeScope: period.scope, range: NSRange(location: start, length: count))
                return answer(entries, period)
            default:
                let (_, entries, _) = try await board.loadEntries(for: .global, timeScope: period.scope, range: NSRange(location: 1, length: count))
                return answer(entries, period)
            }
        } catch {
            throw foundationFailure(error, doing: action)
        }
    }

    // --------------------------------------------------------------------------------------------------- overlay ----
    /// overlay.open: the Game Center dashboard on the page asked for. Answers once it is on screen; the `overlay` events
    /// say when it opened and closed.
    func openOverlay(page: String, id: String?, storeId: String?) async throws -> JSONObject {
        if page == "store" {
            throw Failure(.unavailable, "the App Store has no overlay for an app's own products",
                          hint: "platform.purchases.buy(id) shows the purchase sheet; there is nothing to open for \"store\".")
        }
        try requireSignedIn()
        await MainActor.run { GameCenter.trigger(page: page, storeId: storeId) }
        return [:]
    }

    @MainActor
    private static func trigger(page: String, storeId: String?) {
        let access = GKAccessPoint.shared
        let closed: () -> Void = { Host.shared.emit("overlay", ["open": false]) }
        Host.shared.emit("overlay", ["open": true])
        if #available(iOS 18.0, macOS 15.0, *), let storeId = storeId {
            if page == "achievements" {
                access.trigger(achievementID: storeId, handler: closed)
                return
            }
            if page == "leaderboards" {
                access.trigger(leaderboardID: storeId, playerScope: .global, timeScope: .allTime, handler: closed)
                return
            }
        }
        switch page {
        case "achievements":
            access.trigger(state: .achievements, handler: closed)
        case "leaderboards":
            access.trigger(state: .leaderboards, handler: closed)
        default:  // "friends"
            if #available(iOS 15.0, macOS 12.0, *) {
                access.trigger(state: .localPlayerFriendsList, handler: closed)
            } else {
                access.trigger(state: .dashboard, handler: closed)
            }
        }
    }
}
