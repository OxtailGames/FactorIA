# Legal templates: privacy policy and EULA for a game you ship

Templates and facts for the two documents most stores ask a game maker for: a **privacy policy** and, sometimes, an
**end-user license agreement (EULA)**. Store rules in this page are **as of 2026-10**; confirm them on the store's own
page before you submit.

> **This is not legal advice.** These are plain-words templates to adapt, written by an engine team, not by a lawyer.
> Ask a lawyer when you sell to children, collect personal data (accounts, e-mail, analytics tied to a person), sell in
> many countries, or take payments yourself. Rules differ by country and change.

## What the engine itself collects and sends

Checked against the code of this repository:

- **An exported game sends nothing by itself.** The engine has no analytics, advertising id, accounts or crash upload,
  and no request leaves a game unless its own scripts call `http.fetch` ([NETWORKING.md](NETWORKING.md)). That call
  uses the HTTP stack the operating system already has (WinHTTP, `NSURLSession`, libcurl on Linux, `HttpURLConnection` on
  Android, the browser's `fetch`): the player links no network library, and only to the hosts the game declares in
  `factoria.json` `"network"`. A game without that section cannot make a request. The AI client `fa_ai`
  (`tools/ai/src/http.cpp`) is linked into the `factoria` CLI, the MCP server and the editor
  (`tools/cli`, `tools/mcp`, `tools/editor`), never into a game. The web build downloads its own game files from the
  site that hosts it, nothing more.
- **Speech uses the system's voices.** `ui.speak` hands the text to the operating system's or browser's text to speech.
  Most voices run on the device, but some are online (Chrome's "Google" voices, some Android speech engines) and then
  the system sends the spoken text to its provider. The web build picks a voice on the device when the browser has one
  for the language. If your game reads out what players type (names, chat), say so in the policy.
- **Saves are local.** `storage` writes files in the game's save folder on the device; on the web the save folder is the
  browser's IndexedDB for the site ([FINISHING.md](FINISHING.md)).
- **`log.txt` and crash reports stay on the device**, in the save folder (`crashes/` next to `log.txt`). Nothing uploads
  them: there is no upload URL ([EXPORTING.md](EXPORTING.md), "Crash reports"). A player who wants help sends the files
  to you.
- **The editor's AI features are the developer's tool, not the shipped game.** When you use the built-in AI with an API,
  your prompts and project context go to the AI provider you chose, under that provider's terms
  ([AI_PROVIDERS.md](AI_PROVIDERS.md)). Nothing of this is in the exported game.
- **Store plugins bring the store's data collection.** Steam, Apple (StoreKit, Game Center, iCloud) and Google Play
  (Billing, Play Games Services) process purchases, achievements, leaderboards and cloud saves in the store's own
  services under the store's privacy policy ([PLATFORM.md](PLATFORM.md); what to answer in the store forms:
  [MOBILE.md](MOBILE.md#store-privacy-forms)).

Anything else the game does (an ads or analytics SDK, accounts, what your server does with the requests `http.fetch`
sends) is yours to declare. A game that declares `"network"` hosts must say so in its privacy policy: see "A game that
connects to your server" below. If you add something else, add the matching paragraph.

## Privacy policy

### Where to host it

A privacy policy is a plain public web page at a stable `https://` URL. Your itch.io page, GitHub Pages or any
website works; a PDF or a page behind a login does not. Link the same URL in every store and inside the game (a
credits or settings screen). As of 2026-10: Google Play asks for the URL on every app, the App Store asks for it for
every app, the Microsoft Store asks for it in Partner Center ([PUBLISHING.md](PUBLISHING.md)), and Steam and Epic want
one when the game collects data. Keep the policy true: it must match the store privacy forms
([MOBILE.md](MOBILE.md#store-privacy-forms)).

### Template: a game that collects nothing

Replace the placeholders `[GAME NAME]`, `[STUDIO]`, `[CONTACT EMAIL]` and `[DATE]`.

```
Privacy policy for [GAME NAME]
Last updated: [DATE]

[GAME NAME] is made by [STUDIO] ("we").

We do not collect, store or share any personal data about you. The game does not connect to our servers, has no
accounts, no advertising and no analytics.

What stays on your device. The game saves your progress and settings in files on your device (in a web browser: in the
browser's storage for this site). It also writes a log file and, if the game crashes, a crash report in the same
folder. We never receive these files. If you ask us for support you may choose to send them to us; we use them only to
find the problem.

Stores. If you got the game from a store (for example Steam, the App Store or Google Play), the store collects data
about your purchase and play under its own privacy policy. We do not control it.

Children. The game does not ask for personal data from anyone, including children.

Changes. If this changes we will update this page and the date above.

Contact: [CONTACT EMAIL]
```

### Paragraphs to add

Add the paragraph that matches what your game does, and remove the sentences of the template that are no longer true
("does not connect to our servers", "no analytics", ...). Name the real provider, the real data and a real retention
period.

- **A game that connects to your server (`http.fetch`).** "While you play, the game connects to [HOST, e.g.
  api.example.com], run by [STUDIO / PROVIDER], to [PURPOSE, e.g. fetch the daily challenge and send your score to the
  online leaderboard]. The server receives [DATA: what the game sends, e.g. your player name and score] and, as with
  every connection, your IP address. We keep it for [PERIOD]." List every host of `"network"` `"hosts"` in
  `factoria.json` and use `"purpose"` as the sentence about why ([NETWORKING.md](NETWORKING.md)). Remove "does not
  connect to our servers" from the template. Store forms: declare what your server receives ("data collected").
- **Analytics.** "We use [PROVIDER] to count how many people play and which features they use. It receives [DATA, e.g.
  an anonymous install id, device model, country, session length]. We keep it for [PERIOD]. The legal basis is [consent
  / legitimate interest]. You can turn it off in [WHERE IN THE GAME]." In the EU/UK ask for consent before the first
  event is sent. Store forms: declare the data (Analytics purpose).
- **Ads.** "The game shows ads from [AD NETWORK]. The network may use your device's advertising id to show ads and
  measure them, under [AD NETWORK]'s privacy policy [LINK]. You can reset or limit the advertising id in your device
  settings." Needs the advertising declarations in the stores and, on iOS, the tracking prompt if it tracks.
- **Accounts or sign-in.** "To create an account we ask for [E-MAIL / NAME / USERNAME]. We use it to [SIGN YOU IN, SYNC
  YOUR PROGRESS]. We keep it until you delete your account. You can ask us to delete or export it at [CONTACT EMAIL]."
  Both app stores require an in-app way to delete the account when the app has accounts.
- **Cloud saves through a store (`platform.cloud`).** "If you turn on cloud saves, your progress is stored by [STEAM /
  APPLE iCLOUD / GOOGLE PLAY GAMES] in your account there, under their privacy policy. We do not receive it." Say "we
  receive it" instead if your own server does.
- **Achievements and leaderboards through a store.** "Achievements and leaderboard scores are sent to [STEAM / GAME
  CENTER / GOOGLE PLAY GAMES]. Your public name and scores may be visible to other players there, under their privacy
  policy."
- **A crash upload.** The engine uploads nothing; if you add it: "If the game crashes it can send a crash report to
  [SERVICE]. It contains [GAME VERSION, DEVICE, OS, THE ERROR]. We keep it for [PERIOD] and use it only to fix bugs."
  Ask first, or offer a setting to turn it off.
- **Children (COPPA, GDPR-K).** If the game is meant for children or you know children play it, laws apply even if you
  collect almost nothing. In the US, COPPA covers collecting personal data from children under 13 and needs verifiable
  parental consent. In the EU, GDPR sets the age of digital consent between 13 and 16 depending on the country (each
  country picks), and the UK sets 13. Under those ages a parent must consent. The simplest safe route is to collect
  nothing and show no personalized ads; otherwise ask a lawyer. Say plainly in the policy: "We do not knowingly collect
  data from children under [AGE]. If you think a child gave us data, write to [CONTACT EMAIL] and we will delete it."
  Google Play's Families policy and Apple's Kids category add their own rules.

## EULA

A EULA is the license between you and the player: they may play the game, not copy or resell it, and you are not liable
beyond the law.

### When you do not need your own

For the usual case the store's terms already cover it:

- **Steam**: the Steam Subscriber Agreement.
- **App Store**: Apple's standard (Licensed Application) EULA, which applies unless you upload your own.
- **Google Play**: Google Play's terms of service.
- Microsoft Store, Epic and GOG have their own store terms too; check them.

### When you do

- You sell directly from your own site or itch.io (the store does not give players a license for your game).
- The game has multiplayer, chat, accounts or **user-generated content**: add rules of conduct, what you may remove
  and who owns what players make.
- You allow or support **mods**: say what is allowed and who owns a mod.
- You want terms the store's do not give you (subscriptions, refunds you offer, regional limits).

### Template: direct sale

Replace the placeholders `[GAME NAME]`, `[STUDIO]`, `[CONTACT EMAIL]`, `[DATE]` and `[COUNTRY]`.

```
End-user license agreement for [GAME NAME]
Last updated: [DATE]

By installing or playing [GAME NAME] you accept this agreement with [STUDIO] ("we").

1. License. We give you a personal, non-exclusive, non-transferable license to install and play the game on your own
   devices. We keep all rights in the game, its art, music and code.
2. What you may not do. Copy or resell the game, remove its protection, or use it for anything unlawful. Where the
   law lets you do something despite this (for example, to repair or to interoperate), the law wins.
3. Your content and mods (if the game has them). You keep the rights in what you make. You give us a license to host and
   show it in the game. We may remove content that breaks the rules of the game or the law.
4. Updates. We may update the game or stop supporting it.
5. Refunds. [DESCRIBE, e.g. "Within 14 days of purchase, write to [CONTACT EMAIL]"]. Your legal consumer rights are
   not affected.
6. No warranty and liability. The game is provided "as is". To the extent the law allows, we are not liable for
   indirect damages. Nothing here limits liability that the law does not allow to be limited.
7. Privacy. See our privacy policy at [URL].
8. Law. This agreement is governed by the law of [COUNTRY]; consumer protection rules of your country still apply.

Contact: [CONTACT EMAIL]
```

## Checklist

- [ ] I know what my game sends: the engine alone sends nothing; plugins, SDKs and the hosts of `"network"` in
      `factoria.json` (my own servers) are listed.
- [ ] The privacy policy is a public `https://` page with the template adapted, the paragraphs for what I added, and no
      leftover placeholders (`[GAME NAME]`, `[DATE]`, ...).
- [ ] The same URL is in the store forms (Google Play, App Store, Microsoft Store; Steam and Epic when the game collects
      data) and inside the game.
- [ ] The store privacy forms say the same as the policy ([MOBILE.md](MOBILE.md#store-privacy-forms)).
- [ ] Accounts, if any: players can delete their account from inside the app.
- [ ] Children: I decided whether the game is for them, set the age rating and target audience to match, and asked a
      lawyer if it is.
- [ ] EULA: the store's covers me, or I added my own (direct sales, multiplayer, user content, mods).
- [ ] A contact e-mail that works is in the policy and on the store page.
- [ ] I will update the policy and the forms when I add an SDK, plugin or server.
