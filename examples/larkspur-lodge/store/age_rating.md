# Age rating answers (IARC and the App Store questionnaire)

Answers for Larkspur Lodge 0.1.0, written from the game's own text and scenes (`locales/en.json`, `data/`,
`scenes/`). The questionnaires are filled in by hand, in the store consoles: this file is what to tick. Re-read it
if the story changes. The rating the stores compute is theirs; the expected result is the lowest tier in every
system (ESRB E, PEGI 3, USK 0, ACB G).

What the game is: a 3D narrative mystery in a snowed-in lodge. The mystery is a missing page of a land record
(page forty), not a death; people argue, lie and keep secrets, and nobody is hurt on screen.

| Question | Answer | Why |
|---|---|---|
| Violence (cartoon, fantasy, realistic) | None | no fight, weapon use, injury or death is shown or the aim of any puzzle |
| Blood and gore | None | |
| Sexual content, nudity | None | |
| Profanity or crude humour | None | searching `locales/en.json` finds no profanity |
| Alcohol, tobacco, drugs | Mention only, infrequent | wine is served at dinner and found in the cellar, as set dressing and a clue; nobody is shown drinking to excess |
| Fear, horror | None to mild | a storm at night, a dark cellar and a stopped power supply; no monsters, jump scares or threats to the player |
| Gambling (real or simulated) | None | |
| Contests, loot boxes, random paid rewards | None | |
| In-app purchases, ads | None | the game has no purchases and no ad SDK |
| User-generated content, chat, social features | None | there is no online connection and the player types no text |
| Location sharing, personal data collected | None | nothing is collected or sent; `factoria.json` has no `network.hosts` and no analytics |
| Unrestricted web access | No | no web view or link opens from the game |
| Accounts, sign-in | No | |
| Requires a connection | No | |
| Medical or wellness content | None | |

Other declarations that go with the rating:

- **Apple (App Privacy)**: Data Not Collected. The export writes `PrivacyInfo.xcprivacy` (no tracking, no collected data)
  and `ITSAppUsesNonExemptEncryption` false (`export.ios.usesNonExemptEncryption`).
- **Microsoft Store**: no data collected, no in-app purchases, no ads; the privacy policy URL is still needed by hand
  (see `SHIPPING.md`).
- **Steam**: the content survey (Store Presence > Content Survey) is answered "no" to every adult-content question; the
  language section lists English until package P8 adds the others.
- **Accessibility (App Store label)**: captions on every spoken line, text size, reduced motion, colour filters, full
  rebinding. VoiceOver is not claimed: the menus can be read aloud by the game's own speech option, which is not the
  system screen reader.
