Part of [EDITOR.md](../EDITOR.md): Updates, exporting, Play on Phone, setting up the computer, platform settings, the program icon and scene files rebuilt on disk.

# Editor: setup

## Updates

The downloaded editor checks GitHub Releases when it opens. When a newer version is out, the **FactorIA update**
window shows the release notes of every version newer than yours and blocks the editor until you choose: **Update**
downloads it, replaces the files next to `factoria` and reopens the editor on the open project; **Not now** keeps this
version until the next start. Builds from source never check (they have no `FA_UPDATE_REPO`), and neither does the
Linux AppImage (a read-only mount: download the newer one). Details:
[GETTING_STARTED.md, Updates](../GETTING_STARTED.md#updates).

**Updated on disk.** Files copied over the installation without the updater leave the running editor on the old code. The
editor looks at its own `factoria` file (size and modification time) every 5 seconds and when its window gets focus, and
once the file has changed it reads the build identity (version and commit fingerprint) written in it. If that is another
build than the one running, a notice appears at the bottom of the window, and the editor stays usable:

> FactorIA was updated on disk (0.3.0 build f530fda3e543 -> 0.4.0 build 1a2b3c4d5e6f). Restart the editor to use it.

**Restart** quits (the unsaved-changes dialog still asks) and reopens the editor on the same project, the way the updater
does; the chats of the AI Assistant (`.factoria/ai/chats/`) come back with their tabs. **Not now** hides the notice until the
file changes again. Restart is off, with the reason in its tooltip, while an AI run is in progress (or a worker still runs),
a play session runs, an export or a Set Up This Computer install runs, or a keystore is being created: nothing is stopped
silently. The editor starts again through the launcher you pinned, so the Dock or taskbar keeps one FactorIA icon: on macOS
a helper waits until the old editor has quit and then runs `open ~/Applications/FactorIA.app --args <project>` (no `--args` on
the start screen), so the new editor takes the pinned Dock icon (a second instance started while the old one is still
quitting would get an icon of its own), when that app is the launcher of this `factoria`
(`factoria setup launcher`; the editor rewrites an older one at start), also when a newer FactorIA installed over the running editor wrote it, on Windows `FactorIA-Editor.exe` next to
`factoria.exe` (also with no project open); on Linux the `.desktop` entry's `StartupWMClass=FactorIA` groups the new window with it. With no such
launcher (a development build, a launcher of another `factoria`) or if starting it fails, it runs `factoria editor <project>`
directly. A rebuild of the same commit, a file with no identity (a build outside git) or an unreadable file never shows the
notice. The AI can ask with the read-only command `engine.update_status` (`running`, `onDisk`, `restartDue`, and under `editor`
whether the notice shows and what blocks Restart). While the updater above installs a release, this notice stays quiet.

## Exporting the game

**Export Game** in the menu bar (next to the Help menu; on macOS the **Export** menu, Cmd+E; or File > Export Game...) opens the **Export game** window: a button per platform (Windows,
macOS, Linux, Android, iOS, Web) that runs the same export as `factoria export` and the `project.export` command. Each
platform's row says what the export writes, or why it cannot run on this machine (no player built for that OS, no
mobile players or engine checkout, a missing `id`, an output folder that already holds a folder of that name no
export wrote) and how to fix it; for another OS's desktop export, **Choose
player...** picks a `factoria_player` built there. Pick the output folder (default `<project>/build/export`), press a
platform, and the report shows the output folder (**Show in Finder** / Explorer), warnings and next steps. Android and
iOS exports are a Gradle / Xcode project (or, with the Android format APK / AAB, a built app) and the next steps say
how to finish them.

- **Platform settings...** at the top of the window, and a small **Settings...** button on each platform's row, open the
  Platform settings window (below) on that platform's tab.
- **Set up buttons**: a row that cannot run because this computer lacks something FactorIA can install shows the button
  that installs it: **Install Android build tools**, **Download Windows player** (or macOS / Linux: the other OS's
  player), **Download mobile libraries**, **Install CMake**, **Open App Store (Xcode)**. Details:
  [Setting up this computer](#setting-up-this-computer).
- **Android format**: the Android row has a **Format** menu (APK, Android App Bundle, Gradle project only). It saves
  `export.android.format` in `factoria.json` right away, like the AI would, and leaves any other unsaved edit of the
  Platform settings window alone.
- **While it runs**, the window shows the export's progress line and a **Cancel** button; the build output (Gradle can
  take minutes) scrolls below it. A cancelled export says so in the report.
- **The report** names the **Format** and, when the export produced a single file (an APK or AAB), the **Artifact** with
  **Show in Finder** (the file selected in Finder / Explorer) and **Copy path**.
- **Release** makes a release build; hover it to see what changes for each platform (for Android, an APK or AAB signed
  with the keystore of the Android tab).

- **Web row**: **One HTML file** exports the web build as ONE page that opens from a double click (`singleFile`; refused over
  64 MB or with a threaded web player, with the reason in the report), and **Play on phone...** opens the window below.

Details: [EXPORTING.md, From the editor](../EXPORTING.md#from-the-editor).

## Play on Phone

File > Play on Phone... (also the **Play on phone...** button of the Export window's Web row) opens the **Play on phone**
window, the editor's front for `project.serve_web` ([EXPORTING.md](../exporting/EXPORTING_WEB.md#serving-the-web-build-projectserve_web)).
**Start** exports the web build (on a helper thread: the editor keeps working) and serves it on the local network under a
random port and token; the window shows the state in one line (exporting, ready, the export failed and why), the address
as a **QR code** drawn by the engine (point the phone's camera at it; a menu picks the address when this computer has
several; none when it has no private network address, since a code of `127.0.0.1` would open the phone's own localhost),
**Copy address**, **Open on this computer**, **Stop** and the checklist for a phone that cannot open it (same Wi-Fi, the
firewall prompt on Windows and macOS, guest networks that isolate devices, a VPN; [MOBILE.md](../mobile/MOBILE_DEVICE.md#play-on-a-phone)).
A changed script or asset exports again and the phone's page reloads; what the page logs comes to the Console with the
category `phone`. The scene on disk is what the phone gets: the window warns about unsaved changes and has **Save scene**.
Without the web player the window says how to install it (**Open Set Up This Computer...**). The server stops with **Stop**,
when you switch project and when the editor quits. The window fits a 1024x642 display; the autotest section T2 covers it with
a stand-in player.

## Setting up this computer

An export needs things that are not part of FactorIA: a JDK and the Android SDK, the players of the other operating
systems, CMake, Xcode. You never install them by hand: File > Set Up This Computer... opens the **Set up this computer**
window, the editor's front for `factoria setup` ([EXPORTING.md, Setting up this computer](../exporting/EXPORTING_SETUP.md#setting-up-this-computer)).
It runs the very same code (`fa::setup_install`), so what a button installs is what `factoria setup` and the `setup.install`
command install.

- **The window** lists the components (the AppImage tools of a Linux export and the shader compiler, which the downloads carry and a source build gets, are installed with `factoria setup appimage` and `factoria setup shaders`, not from here yet; **Visual Studio Code debugger** copies the FactorIA extension into VS Code in one click, so F5 in a project debugs its scripts: [DEBUGGING.md](../DEBUGGING.md)), each with its state (**Installed**, **Partly installed**, **Not installed**,
  **Not needed here**), what was found, the paths, what is missing and how big the download is, and one button:
  **Install** (or **Reinstall** when it is installed already), or **Open App Store** for Xcode, which a program cannot
  install. **Show in Finder** opens the folder everything is installed into (`~/.factoria`, or `$FACTORIA_HOME`); **Check
  again** looks at the computer again (it never downloads anything). Nothing is downloaded until you press a button, and
  nothing needs an administrator password, `PATH` or the registry.
- **While it runs** (on its own thread; the editor keeps working) the window shows what it is doing, a progress bar with the
  percentage of the download, **Cancel** (it stops the download and installs nothing half-way) and a collapsible **Log**.
  When it finishes you get a toast, and the window shows the report: what was installed, warnings, the numbered next steps
  (**Copy report** copies it), or the error and how to fix it. The Export window's rows and this window read the computer
  again by themselves.
- **Set up buttons where the problem shows up**: the Export window's rows and the Platform settings tabs offer the setup
  that fixes what the row says is missing, in plain words: **Install Android build tools** (no JDK 17+ or Android SDK),
  **Download Windows / macOS / Linux player** (another OS's player), **Download mobile libraries** (prebuilt Android/iOS
  without the engine source), **Install CMake** and **Open App Store (Xcode)** (the iOS row, also when it is ready: the
  Xcode project it writes needs both). A row that is ready, or not ready for a reason a setup cannot fix (a missing `id`,
  a folder in the way), shows none. Platform settings > General has **Set Up This Computer...**.
- **The Android SDK license** is a legal agreement between you and Google, so **Install Android build tools** (here and in
  the window) first opens a dialog with the full license text in a scrollable box. **I accept** stays disabled until you
  tick **I have read the license above and I accept it**; **Decline** closes the dialog and installs nothing. Only
  **I accept** starts the install (with the license accepted); FactorIA never accepts it for you, and nothing is
  downloaded before. If the text cannot be loaded (no network) the dialog says so and offers **Try again**.
- **The home folder is also yours to inspect**: `~/.factoria/android`, `players/<version>`, `tools/cmake`; remove a
  folder to uninstall it.

## Platform settings

File > Platform Settings... opens the window that edits what an export needs besides the game: the icon and, per
platform, the fields of its app (see [EXPORTING.md, Platform settings](../exporting/EXPORTING_SETUP.md#platform-settings) for what each
field does). It is a form over exactly what `factoria.json` holds in `icon` and `export` (and `~/.factoria/export.json`
for This computer), checked by the same code `factoria validate` and the export use, so what you can enter here is what
the AI can write in the file and the reverse.

- **Tabs**: **General** (the game icon, and the game's own name, id, version, orientation and resolution, read-only:
  ask the AI or edit `factoria.json` to change those), **Windows**, **macOS** (category menu, minimum macOS version,
  copyright), **Linux** (the `.desktop` categories, added from a menu or typed), **Android** (format, version code,
  minSdk / targetSdk, permissions, adaptive icon, signing, and This computer) and **iOS** (icon background colour,
  Team ID, build number). A field left empty uses the default, and its box shows what that default is.
- **Icons** have a preview next to the path, **Choose...** and **Clear**, and a line that says what the file is
  (`1024 x 1024 px`) or what is wrong with it (not found, not an image, not square, too small, in a folder the export
  does not ship such as `build/`). A platform's own icon falls back to the game icon and says so. A picture chosen from
  outside the project is copied into `<project>/assets/` (icons must be inside the project) and the setting names the
  copy; a different file that already has that name gets `-2`, `-3`... and nothing is overwritten.
- **Save / Revert**: the window edits a working copy. **Save** writes `factoria.json` (only `icon` and `export`: every
  other key, the order and the formatting stay as they are) and, if you changed it, `~/.factoria/export.json`. **Revert**
  reads both files again. Fields with a wrong value are marked in red with the error and the fix; Save waits until they
  are fixed. Closing the window with unsaved edits asks: **Save and close**, **Discard** or **Keep editing**; opening
  another project drops them. If `factoria.json` changes on disk (the AI wrote it, or you did), the window reads it again by
  itself, or, when you have unsaved edits, asks whether to **Reload** or **Keep my edits**. A hand-edited file with wrong
  values still opens: the errors are listed at the top and the fields show what could be read.
- **Android signing**: the keystore file (project-relative or absolute) with **Choose...**, the key alias, and the
  passwords' status (set by the `FACTORIA_ANDROID_KEYSTORE_PASSWORD` / `FACTORIA_ANDROID_KEY_PASSWORD` environment
  variables, saved on this computer, or not set: the password itself is never shown). A release build without a
  keystore fails (an app signed with the debug key is one Google Play rejects); to try one on a phone with the debug key,
  export from the command line with `--allow-debug-key`.
- **Create keystore...** makes a signing key with the JDK's `keytool` (a PKCS12 keystore with one key valid for about 27
  years; the password is handed to `keytool` through its environment, never as an argument): choose the file (default
  `keys/upload.keystore`), alias, password, your name or studio, and optionally organization and country. It can keep
  the password on this computer and add the keystore to `.gitignore`. The new keystore fills the signing fields (press
  **Save** to keep them). Back up the file and its password: Google Play needs the same key for every update of the app.
- **This computer** (Android tab; saved in `~/.factoria/export.json`, never in the project): the JDK and Android SDK
  folders (empty = look for them), what was found or what is missing and how to install it (**Check again** after
  installing; or **Install Android build tools**, which installs them for you), and **Remember them on this computer** for the signing passwords. Without it the passwords are not kept
  anywhere: set the environment variables when you build a release.

## The program icon

The editor's window icon (Windows, Linux) and its macOS Dock icon are the PNGs in `tools/editor/icon/`, embedded in the
editor; `factoria.exe` and `FactorIA-Editor.exe` carry the same sizes in `tools/cli/windows/factoria.ico`. They are made from
the sources in `tools/editor/icon/src/`: the artwork (`factoria_art.png`, 1024 px) for 32 px and up, and a simplified
drawing (`factoria_small.svg`, rendered to `factoria_small.png`) for 16 and 24 px, where the artwork turns into a blur. After
changing a source run `python3 tools/editor/icon/make_icons.py` (needs Pillow) and commit what it writes (it also
writes the AppImage's `platforms/linux/factoria.png`).

The program's name is FactorIA everywhere the system shows one: the editor renames itself in the macOS Dock (the
`factoria` executable is not an app bundle, so macOS would show its file name), the Windows exes carry it in their
version resource (`tools/cli/windows/factoria.rc`), and the editor window's Linux `WM_CLASS` (`AppDesc::appName`) is
`FactorIA`, as the AppImage's `StartupWMClass`.

The icon of a game is its own (`factoria.json` `icon`, docs/EXPORTING.md), not this one.

## Scene files rebuilt on disk

A command that rebuilds the scene file that is open (`scene.import_ascii` with `path` set to it, or `scene.ascii_edit` on the level
file that builds it, from the AI or the Console) is followed by a reload, so the viewport shows the result. Whatever was on screen
before is one Ctrl+Z away, and commands that only write files (`prefab.save`, `scene.format`, `scene.ascii_edit`,
`scene.import_ascii` with `path`) neither take an undo step nor mark the scene as changed.

The undo and redo stacks hold `UndoEntry` values (`tools/editor/src/undo_stack.h`), each with a kind. A `snapshot` entry is the whole
scene before an edit (`begin_edit`, as always), a `special` entry is a `$clip`, `$image`, `$sound`, ... step that a document panel
undoes itself, and a `command` entry holds a list of forward commands and a list of inverse commands (`{cmd, args}`) and no scene:
undo runs the inverse list, redo the forward list. `push_command_entry(key, forward, inverse)` records one and coalesces like
`begin_edit` (the same key within 0.8 s merges into the newest entry when that is a command entry; `Replace` keeps its inverse and
takes the new forward, `Chain` appends both); no editor action records command entries yet. Every entry knows its approximate memory
(an estimate of the JSON in memory, not the file size), and the stack drops the oldest entries when it holds more than 100 or more
than 256 MiB by that estimate; the newest entry always stays. A new edit clears the redo stack.
