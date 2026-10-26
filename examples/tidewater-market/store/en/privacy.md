# Privacy answers (Tidewater Market 0.1.0)

Facts to build the store forms from. Check each store's current form: they change.

## What the game does
- No accounts, no analytics, no advertising id, no network connection of its own (factoria.json declares no `network` hosts).
- Saves (three slots with autosaves, options, achievements) are files in the app's private folder; on the web build they live in the browser's own storage. Nothing sends them anywhere.
- Optional platform services (Steam achievements and cloud save, when a plugin for them is added) work only when the player is signed in to the platform; the game receives no name or e-mail from them.
- No purchases and no ads.

## Steam and itch.io
- Steam: no data collected by the game.
- itch.io: no data collected. The web build keeps its saves in the browser's local storage on the player's own machine.

## Apple App Store / Google Play (only if the game is ever shipped there)
- Data types collected: none. Tracking: no. Privacy policy URL: required (see urls.txt).
- Google Play data safety: collects or shares no user data; target audience not children.
