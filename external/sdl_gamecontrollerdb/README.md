# SDL_GameControllerDB (Linux and Windows lines)

The community database of gamepad mappings used by SDL, filtered to the lines whose `platform:` field is `Linux`
(`gamecontrollerdb_linux.txt`) and to those whose `platform:` field is `Windows` (`gamecontrollerdb_windows.txt`).
FactorIA embeds both files (engine/platform/CMakeLists.txt) so a Linux pad that is not an Xbox pad, and a Windows HID pad
that XInput does not serve, work without the player writing an `SDL_GAMECONTROLLERCONFIG` line. The Windows lines are
in their own object of `fa_platform` (gamepad_hid_db.cpp), which only the Windows backend and the tests reference, so
the players of the other platforms do not carry them.

- Source: https://github.com/mdqinc/SDL_GameControllerDB, file `gamecontrollerdb.txt`
- Commit: `c1d5289a1f713b30a2c121e9fe6529d39360be0f` ("Remove ODROID Go 2 (default product id)", 2026-10-02)
- License: zlib, see `LICENSE` (copied from the repository root)
- Changes: only the two `#` comment lines at the top of each file were added; the 744 `platform:Linux` lines and the
  869 `platform:Windows` lines are verbatim. 16 lines of each file describe sticks driven by buttons or a hat (N64 and
  Joy-Con pads); FactorIA's parser reports those lines as unsupported instead of applying them, and the pad falls back to
  the next candidate or the default layout. One line of each has the GUID `xinput` (it can never match a pad by its ids)
  and is skipped.

To update, replace the files with the new filtered output and edit the commit above:

```
grep "platform:Linux" gamecontrollerdb.txt > gamecontrollerdb_linux.txt       # then re-add the two comment lines
grep "platform:Windows" gamecontrollerdb.txt > gamecontrollerdb_windows.txt   # likewise
```

`fa_test_platform` parses every line, so a new line the parser cannot read fails the test with the line's message.
