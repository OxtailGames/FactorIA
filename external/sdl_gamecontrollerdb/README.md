# SDL_GameControllerDB (Linux lines)

The community database of gamepad mappings used by SDL, filtered to the lines whose `platform:` field is `Linux`.
FactorIA embeds `gamecontrollerdb_linux.txt` in the binary (engine/platform/CMakeLists.txt) so a Linux pad that is not
an Xbox pad works without the player writing an `SDL_GAMECONTROLLERCONFIG` line.

- Source: https://github.com/mdqinc/SDL_GameControllerDB, file `gamecontrollerdb.txt`
- Commit: `c1d5289a1f713b30a2c121e9fe6529d39360be0f` ("Remove ODROID Go 2 (default product id)", 2026-10-02)
- License: zlib, see `LICENSE` (copied from the repository root)
- Changes: only the two `#` comment lines at the top were added; the 744 `platform:Linux` lines are verbatim. 16 of them
  describe sticks driven by buttons or a hat (N64 and Joy-Con pads); FactorIA's parser reports those lines as
  unsupported instead of applying them, and the pad falls back to the next candidate or the Xbox layout. One line has
  the GUID `xinput` (it can never match a Linux pad) and is skipped.

To update, replace the file with the new filtered output and edit the commit above:

```
grep "platform:Linux" gamecontrollerdb.txt > gamecontrollerdb_linux.txt   # then re-add the two comment lines
```

`fa_test_platform` parses every line, so a new line the parser cannot read fails the test with the line's message.
