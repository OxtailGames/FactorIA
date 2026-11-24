# FactorIA architecture: files and block codecs

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page).

## Files: `fa::fs`
Everything the engine reads of a game (scenes, prefabs, textures, sounds, fonts, scripts, `factoria.json`) goes through
`fa::fs` (`core/fs.h`), by project-relative path (forward slashes, no `..`). The paths are answered from one of three
sources: the project folder on disk (`set_project_root`), the APK's assets on Android, or a **game pack**: one read-only
archive (`core/pack.h`) that `fa::fs::mount_pack` mounts, which is how a `--release` desktop export ships a game
([EXPORTING.md](../exporting/EXPORTING_DESKTOP.md#release-build-gamepak)). While a pack is mounted it answers every project-relative path alone
(`read_*`, `exists`, `is_directory`, `file_size`, `modified_time`, `list`); absolute paths and writes still go to the host.
So engine code must not open a game file with `std::ifstream` or `std::filesystem` on a path it built from the project
folder: use `fs::`, or the file will be missing from a packed game. A pack (format 2) holds each file in checksummed blocks of
256 KiB, each compressed with the file type's codec (`core/compress.h`: store, lz4, zstd, gdeflate). On 64-bit desktops it is
memory-mapped once; elsewhere (32-bit, web, `FA_PACK_MAP=0`) it reads positionally (no shared file offset), so it is safe from
any thread either way. `fs::read_view(path)` answers an `fs::FileView` instead of a vector: no copy for a file of a mapped
pack stored as it is (the view keeps the pack mapped while it lives, also after `unmount_pack`), a warm file or an Android
APK asset (`AAsset_getBuffer`), and an owned buffer otherwise; the background loader's texture, model and font reads use it,
and the other loaders still read vectors. A play session's `fa::LoadTrace` (`core/load_trace.h`) hooks into these reads to record each scene's
first-use order and the `loading` section of `play.report`; with no trace alive the hooks cost one atomic load. A trace
belongs to its engine, not to a thread: `Engine` marks its entry points with `LoadTrace::ReadingFor(this)`, so two engines in
one process (the editor's and an in-process `play.auto`) never record each other's reads, the editor's own reads (panels,
the asset browser, tools) are left out of a Play's trace, and work handed to another thread takes
`LoadTrace::current_owner()` with it (the music loader does; the M70.3 loader will, per job). `script/bytecode.h` compiles scripts
for the pack; the module loader reads a compiled script from the same `.js` path.

`fs::cache_dir()` / `fs::set_cache_dir()` is the per-user folder for files the engine can always rebuild (the shader
cache, [in the rendering page](ARCHITECTURE_RENDERING.md#start-up-order-and-the-shader-cache)); the game folder and the save folder never hold them.

**Paths a caller gives to a command that writes.** `fs::resolve(path)` accepts any absolute path, so a command that writes
a file named by its caller never uses it: it calls `fs::resolve_for_write(path, root, allowAnywhere, managed)`
(`core/fs.h`), the one place where such a path is confined. `root` is `WriteRoot::Project` (`project_root()`), `Save`
(`user_dir()`, the game's save folder) or `Export` (`fs::export_dir()`, `set_export_dir`; default
`<project>/build/export`, where `project.export` writes; created by the writer, not by the resolution). A relative path is
joined to the root: `a/../b` is fine, a `..` that leaves the root is `path_outside_root`, and after resolving symlinks
(`weakly_canonical`) the result must still be inside, so a link pointing out, or pointing nowhere, is refused too (for every caller, `allowAnywhere` included: a shared asset folder linked
into the project cannot be written through the link, only by its absolute path from the command line; `project_spelling` also
returns the symlink-resolved form of a path). An
absolute path (`/x`, `C:\x`, drive-relative `C:x`, UNC, `\\?\`, `~`) is `absolute_path_denied` unless `allowAnywhere`,
which only a caller that owns the machine (the command-line user) is given, never an agent. With `WriteRoot::Project` the
project's managed folders (`.git`, `.factoria/` except `.factoria/tmp/`: `check_writable`'s rule) are closed to a relative
path and to an absolute one alike (`managed_path_denied`): a path is refused when EITHER its normalized spelling OR its
canonical form (after symlinks) is managed, so a link `meta -> .factoria` and a link `.factoria -> data` both fail; names
are folded to lower case on every system (a case-insensitive volume makes `.GIT` the same folder on Linux too) and lose a
trailing dot or space (Windows strips it: `.git.` is `.git`); a command that picks such a target itself (selections,
previews, review files under `.factoria/`) passes `ManagedFolders::Allow`. A NUL byte, a drive in the first segment of a
relative path and, on Windows, a `:` in any segment are `invalid_path`; so is, on every system (a project must move
between them), a name Windows cannot create: a device name (`CON`, `PRN`, `AUX`, `NUL`, `CONIN$`, `CONOUT$`,
`COM1`-`COM9`, `LPT1`-`LPT9`, and `COM`/`LPT` with a superscript 1, 2 or 3, with or without an extension) or a name ending
in a dot or a space. That rule is about CREATING a name: on Linux and macOS it applies to every segment that is not an
existing regular file, folder or link, so a file that already has such a name (made on Linux) can still be read, and
deleted. On Windows it applies to every segment, as such a file cannot be there (`NUL` exists in every folder, with an
extension too, and `scenes.` is `scenes`). Other names compare without regard to case on Windows and macOS; on Linux they
compare byte for byte, so a name that is not UTF-8 stays what it is. Errors say which form was given, what the root
accepts, the root's real path and the fix, and end with `(code: ...)` (`fs::path_error_code`). In tooling there are three
entry points: `resolve_write_path(projectDir, path, root, managed)` for a path the caller names (the caller's right to
write anywhere decides `allowAnywhere`; managed folders refused unless `ManagedFolders::Allow`),
`project_write_file(projectDir, rel)` for the assets commands, which record project-relative paths and so stay inside the
project for everyone, and `fs.write`, `fs.edit` and `fs.delete`, which refuse the managed folders on the real path.
`resolve_project_path` (`resolve_for_write_in` with `allowAnywhere` false and `ManagedFolders::Allow`) is the reader's and
the tools' own: selections, previews, reads. The checks resolve the path and the caller opens it afterwards: a link
swapped in between is out of scope (it takes a local attacker with write access to the project).

**Windows file rules.** Windows refuses to replace or delete a file another thread has open for reading and moves a file's
time in steps of about 15.6 ms; POSIX does neither, so bugs that follow from them only showed in the Windows CI job. On
macOS and Linux the environment variable `FA_FS_WINDOWS_RULES=1` (ctest sets it for every test: docs/design/BUILDING_TESTS.md, "Running
tests") makes `fa::fs` follow both rules: `fs::ReadStream` (a `std::ifstream` that registers its file while open; `fs::read_*`
use it) makes `fs::replace_file`, `fs::remove_file`, `fs::remove_tree` and `fs::write_bytes` fail on that file the way Windows
does, and `fs::modified_time` / `fs::host_modified_time` round down to 15.625 ms. Code that reads a file another thread or
process writes uses `fs::ReadStream` (or `fs::read_*`) instead of `std::ifstream`; code that replaces or deletes a file
that may be read uses `fs::replace_file` / `fs::remove_file` (they wait for readers, as `write_bytes` does) instead of
`std::filesystem::rename` / `remove`; a change detector uses `fs::modified_time` / `host_modified_time` instead of
`std::filesystem::last_write_time`, and still reads once more after a change (a time that did not move does not prove the
file did not change). With the mode off, the registry costs one atomic load per call.

**Private files** (`core/private_file.h`): `fs::write_private(path, bytes)` writes a file only its owner can open (secrets: the
AI config with a key, the feedback admin token) and `fs::make_private(path)` restricts a file another program made (the Android
keystore). The file is created restricted from its first byte (`open` with 0600 on POSIX; on Windows a protected DACL whose only
entry is the current user, set in `CreateFileW`) and replaces the old one with `fs::replace_file`, so no reader sees a
half-written or a world-readable file. Do not write a secret with `fs::write_text` plus a later `chmod`.

**Sealed files** (`core/crypto.h`, namespace `fa::crypto`): our own SHA-256 (`hash.h`), HMAC-SHA256, HKDF-SHA256, ChaCha20-Poly1305
(RFC 8439) and a file format on top: `seal_blob(key, aad, data)` / `open_blob(key, aad, blob)` (magic `FASB`, version, a random salt and
nonce from the operating system's CSPRNG per seal, ciphertext, 16-byte tag; the blob is 50 bytes larger than the data). It is for
save files: a player cannot read or edit one, and a damaged one is reported ("the data was changed or the key is wrong", nothing
decrypted) instead of loaded. It is not DRM: a key shipped inside the game can be extracted, and an older sealed file can be put
back (a rollback), so a counter inside the data is the game's part. The random bytes (`random_bytes`) are I/O, not the simulation:
never `world.rng()` for a nonce, never `rand()`. Tests check every primitive against the RFC vectors (`tests/test_crypto.cpp`).
The save slots (M98.1b) pick the key and expose this; nothing else in the engine uses it yet.

**Child environment** (`core/process.h`, `core/child_process.h`): by default a child inherits the whole environment. A child that
runs text from a prompt, a project or a stranger (hooks, AI agents, tool servers) sets `ProcessOptions::inheritEnv` /
`ChildOptions::inheritEnv`, an allow-list of names (or `PREFIX*`; case-insensitive on Windows): only those variables of the parent
reach it, then `env` is added and `unsetEnv` removed. `fa::base_child_env()` is the list every child needs (`PATH`, `HOME`, the
locale, temp folders, `SystemRoot`/`ComSpec`... on Windows) and `fa::child_env_allow(extra)` joins it with more names. tools/ai
builds each provider's list (`tools/ai/src/ai_env.h`) and the user extends it with `inheritEnv` in ai.json
(docs/AI_PROVIDERS.md, "Environment of the programs the AI starts"). An unset `inheritEnv` keeps the old behaviour. The list is a
floor against leaking a secret by accident, not a barrier: a child that runs with no sandbox (a shell, an agent in a permission
mode without checks) runs as the user and can read `ai.json`, the keychain and the files itself. A signed export run through the
stdio `factoria mcp` gets no `FACTORIA_*_PASSWORD` for the same reason: signing passwords are not in any allow-list.

## Block codecs: LZ4, Zstandard and GDeflate (`core/compress.h`)
`fa::compress` / `fa::decompress` / `fa::decompress_into` (`Codec::Store`, `Lz4`, `Zstd`, `GDeflate`) are the engine's own
implementations of public formats (GDeflate has its own section below), with no outside library: the LZ4 **block** format (no frame; levels 1 to 12) and
the Zstandard frame format of RFC 8878 (levels 1 to 19). They are for the game pack (M70.4); `zlib_compress` stays for
`storage` and the PNG and PSD code. Their files are private (`engine/core/src/`): `lz4_codec.cpp`, `zstd_decode.cpp`
(every frame the reference tool writes except dictionaries: any window up to 128 MiB, Huffman with 1 or 4 streams and
treeless literals, predefined, RLE, compressed and repeated FSE tables, skippable and concatenated frames, the XXH64
checksum), `zstd_encode.cpp` (frames with the content size, Huffman literals, FSE sequences, raw and RLE fallbacks; levels
1-2 use one hash table, 3-19 hash chains with repeat offsets and lazy matching whose search depth grows with the level),
`xxh64.cpp`. Both formats are byte-compatible with the reference tools in both directions: `zstd -d` and `lz4 -d` read what
the engine writes (an LZ4 block wrapped in a frame), and the engine reads what they write (committed fixtures in
`engine/core/tests/data/codecs/`, README there). Rules the code follows: the output of `compress` is a pure function of
input and level (integer decisions only, explicit little-endian, no dependence on the width of `size_t`, so a pack built on
Windows equals one built on macOS); a decoder never trusts its input (every read and write is bounds-checked, memory is
the caller's `expectedSize` plus one 128 KiB literal buffer, `decompress` refuses a size no block of that length could hold
before it allocates, a window over 128 MiB or a dictionary is an error that says so); nothing is global, so every call is
thread-safe. The tests round-trip many inputs at many levels, decode the reference fixtures, cut and flip bits of valid
blocks and feed garbage (also run under ASan and UBSan while writing them).

### GDeflate (`gdeflate_codec.cpp`, M77)
`Codec::GDeflate` (3 in the pack index) is the stream DirectStorage 1.1 decompresses on the GPU, written for the engine from
the published description of the format (no code of the reference implementation, no dependency). The reader reads it on the
CPU like any codec; the pack stores it so that the Windows DirectStorage reader (M77) can hand a block to the GPU as it is.
Levels 1 to 12 (0 = 6; a hash-chain match finder with lazy matching from level 4, deeper chains per level), all read by the
same decoder.

What is implemented (`fa::compress` makes one stream per block; the pack's block is up to 256 KiB, so four tiles):

- **Stream header, 8 bytes, little-endian:** `u8 id = 4`, `u8 magic = 0xFB` (id ^ 0xFF), `u16 numTiles`, then a `u32` with bits
  0-1 `tileSizeIdx = 1` (64 KiB tiles, the only size), bits 2-19 `lastTileSize` (the bytes of the last tile; 0 = a full 65536)
  and bits 20-31 reserved, 0. An empty input is the header with 0 tiles.
- **Tile table:** `u32[numTiles]` after the header. Entry 0 is the compressed size of the LAST tile; entry `i >= 1` is the byte
  offset of tile `i` in the tile data that follows the table (tile 0 starts at offset 0 and ends where tile 1 starts). Tile data
  is a multiple of 4 bytes, tiles back to back with no padding.
- **A tile** holds up to 65536 input bytes as an ordinary Deflate64 bitstream (RFC 1951 with the two Deflate64 changes: length
  symbol 285 is length `3 + 16 extra bits`, distance codes 30 and 31 give distances up to 65536) dealt to 32 lanes. Lane `n`
  starts with the `n`-th 32-bit word of the tile; whenever a lane has fewer than 32 unread bits it takes the next 32-bit word of
  the tile, so the words after the first 128 bytes are in the order the lanes ran dry. The symbols of a block go to the lanes
  round-robin from lane 0. A match's length symbol and its extra bits go to its lane and its distance symbol and extra bits to
  the SAME lane one round later (that lane skips a turn); after the end-of-block symbol there is one more round for the pending
  distances (lanes after the end-of-block lane, then those before it). A block header (3 bits, and for a dynamic block 5+5+4
  bits) goes to lane 0; the 3-bit precode lengths one per lane from lane 0 and then the code-length symbols round-robin from
  lane 0; a stored block is its 3-bit header and a 16-bit length in lane 0 (no complement, no alignment, at most 65535 bytes)
  followed by one byte per lane round-robin from lane 0. The next block starts on lane 0 again. A tile is at least 128 bytes.
- **The encoder** writes, per tile, one dynamic-Huffman block (matches never leave their tile), or stored blocks when that is
  not smaller. Its output is a pure function of the input and the level (integer decisions, no wall-clock, no randomness, not
  dependent on `size_t` width), so the same pack bytes come out on every platform.
- **The decoder** also reads static blocks and several blocks per tile (what the reference compressor can write). It checks
  everything it can: the header fields, the table (offsets in order and inside the data), every code (oversubscribed or
  incomplete codes, a missing end-of-block symbol, symbols 286/287 and distance codes past 31), every distance against the
  tile start, every match and literal against the tile's output size, and every lane word against the tile's end. A fault is
  an error `gdeflate block is damaged: tile N: <what> (at byte B)` with `B` the offset in the block (the pack adds the file
  and block). The decoder allocates its tables (~10 KiB) per call and nothing proportional to the output.
- **Pack:** codec 3 needs no format version: a pack that holds gdeflate files is a version-2 pack, and an older FactorIA
  reports `codec 3 ... which this FactorIA does not know`. The writer picks it per file with `export.pack.codecs`, for all the
  files it would compress with `export.pack.codec = "gdeflate"` (docs/exporting/EXPORTING_DESKTOP.md), or, with `"auto"`, for a
  Windows export with `export.pack.directStorage` on (default off; the reader that uses it arrives in M77).

Tests (`engine/core/tests/test_gdeflate.cpp`): round trips of 0, 1, 64 KiB +/- 1, 256 KiB and more bytes of text, noise,
zeros and structured data at several levels; the header and the table; the decoder against two tiles written by hand
(stored, static with a match in the next round); every cut and bit flip of a small stream; error text with tile and byte;
the pak (mapped, read, through `fs::mount_pack`); determinism; and a bench case that prints MB/s against lz4 and zstd.
**Test vectors for the reference decoder:** the case "test vectors" pins the FNV-1a hash of eight inputs and of the streams
this encoder writes for them, and with `FA_GDEFLATE_VECTORS_DIR=<dir>` writes `<name>.raw` and `<name>.gdef` for each. A
Windows job (M77 P11b) runs the `.gdef` files through DirectStorage's own decompressor (CPU `IDStorageCompressionCodec`
or the GPU path) and compares with the `.raw`; the reverse (its compressor, our decoder) is the same files written by
`GDeflate::Compress` and read with `fa::decompress`. Until that job runs, bit-compatibility with the GPU decoder rests on the
published description, not on a run of the reference.
