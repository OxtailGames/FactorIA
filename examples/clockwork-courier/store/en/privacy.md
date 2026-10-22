# Privacy answers (Clockwork Courier 1.0.0)

Facts to build the store forms from (the engine's own statements are in MOBILE.md of the FactorIA docs, "Store privacy forms"). Check each store's current form: they change.

## What the game does
- No accounts, no analytics, no advertising id, no network connection of its own.
- Saves (best results, settings, the "intro seen" flag) are files in the app's private folder. Nothing sends them anywhere.
- Optional platform services: Game Center / iCloud key-value (iOS, macOS), Play Games (Android) for achievements, leaderboards and the cloud copy of the save. They are used only when the player is signed in to the platform; the game receives no name or e-mail from them.
- In-app purchases go through the store (StoreKit, Play Billing). The game never sees a payment detail.
- The rewarded "more time" ad is a stub in this build. A real ad SDK would collect data (device identifiers, approximate location, usage data) and must be added to the answers below.

## Apple App Store (App Privacy)
- Data types collected: none. ("Data Not Collected.")
- Tracking: no. `NSPrivacyTracking` is false (set in factoria.json, `export.ios.privacy.tracking`).
- Required-reason APIs: declared automatically in PrivacyInfo.xcprivacy by `factoria export --platform ios` (FileTimestamp C617.1, SystemBootTime 35F9.1).
- Export compliance: `usesNonExemptEncryption` false (no own cryptography; the system's HTTPS only, when a platform service uses it).
- Privacy policy URL: required (see urls.txt).

## Google Play (Data safety)
- Does the app collect or share user data: No, with the stub ad. With a real ad SDK: Yes, device or other IDs, and app activity, for advertising; fill it from the SDK's own disclosure.
- Is all data encrypted in transit: Yes (the platform services use TLS; the game sends nothing itself).
- Can users ask to delete their data: the game keeps no data on a server of ours. Local data goes with uninstalling; the cloud save is the player's own Play Games or iCloud storage.
- Target audience: not children (Families policy does not apply).
- Ads declaration: tick "contains ads" only when a real ad network is connected.

## Steam and itch.io
- Steam: no data collected by the game. The Steamworks plugin only talks to the Steam client.
- itch.io: no data collected.

## Privacy policy
All stores want a URL. A short policy can say: the game collects no personal data, stores progress on the device, uses the platform's own services only when you sign in to them, and lists the contact e-mail. Write and host it yourself (see urls.txt).
