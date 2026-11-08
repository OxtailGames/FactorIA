# Codec interop fixtures

Files made by the reference tools (zstd 1.5.7, lz4 1.10.0) to test that the engine's own LZ4 and Zstandard decoders read
what those tools write (`engine/core/tests/test_compress_blocks.cpp`). Source data: `examples/larkspur-lodge/scenes/ground.scene.json`
("ground"), 300000 zero bytes, and `random2k.bin` (2000 bytes from Python `random.seed(3)`, `random.randrange(256)`).

| File | Command |
| --- | --- |
| `ground.l1.zst`, `ground.l3.zst`, `ground.l19.zst` | `zstd -N -c ground.scene.json` (N = 1, 3, 19; content checksum on, the default) |
| `ground.l3.nocheck.zst` | `zstd -3 --no-check -c ground.scene.json` |
| `ground.l22.zst` | `zstd --ultra -22 -c ground.scene.json` |
| `ground.stdin.zst` | `cat ground.scene.json \| zstd -5 -c` (read from a pipe: no content size in the frame header) |
| `ground.frames.zst` | a skippable frame (`50 2A 4D 18`, 5 bytes of "hello"), the first 40000 bytes at `-3`, the rest at `-3`, another skippable frame; concatenated |
| `zeros300k.zst` | `head -c 300000 /dev/zero \| zstd -3 -c` |
| `random2k.l3.zst` | `zstd -3 -c random2k.bin` (stored as raw blocks) |
| `ground.l1.lz4`, `ground.l9.lz4`, `ground.l12.lz4` | `lz4 -N -c ground.scene.json` (an LZ4 frame; the test reads its blocks) |
| `zeros300k.lz4` | `head -c 300000 /dev/zero \| lz4 -1 -c` |
| `random2k.lz4` | `lz4 -1 -c random2k.bin` (a stored block inside the frame) |

The tests also take the other direction: frames and blocks our encoders write were checked by hand with `zstd -d` and
`lz4 -d` (an LZ4 block wrapped in a frame header) for many inputs and every level; that is not repeatable without the tools,
so it is not part of ctest.
