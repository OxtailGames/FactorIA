# Earlier re-triages

Re-triage 2026-10-13, after `40b049c`: the last three open entries are fixed (SH/FB-0015 in `ebb054d`,
SH/FB-0014 in `ae8bb15`, NS/FB-0008 in `40b049c`). M1-M4 are done; M5 is the only package left and no game has
reported its gaps yet.

Re-triage 2026-10-13, after `99eebad`: the four examples were migrated off their workarounds (Neon Swarm `804c00d`,
Sky Hopper `9dc7fd5`, Block Push `53fab56`, Gem Roller `99eebad`; each removed workaround has a note on its entry).
The migrations found 18 new gaps: 8 were fixed right away (NS/FB-0011..0014 in `f649d8d`/`afbd0e9`, SH/FB-0017..0020
in `cc789f7`) and 10 are open, grouped in M6 below.

Re-triage 2026-10-14, after M6 (`303db3e`, `6e5b5b2`, `2ff6faa`): the 10 open entries are fixed and each has a
`Fixed in <commit>` note; the three that had a workaround in an example (BP/FB-0019, BP/FB-0020, SH/FB-0021) had it
removed in the same commit. No entry is open.

Re-triage 2026-10-14, after M5 (`d5ad914`, `c3b6073`, `022659c`; merges `bdff25f`, `fa07209`, `5c2296e`): the
proactive package is done, so no milestone is left. What is still open is listed under "Found while implementing" in
M5 and M6; no game has hit any of it yet.

Re-triage 2026-10-14, after M7 (merges `6b9b85d`, `46d12bb`, `79d6f1e`, `2eadd1e`): every item of the M5 and M6
"Found while implementing" lists is done (each is struck through with its commit), and CI now runs the mobile players
on a simulator and an emulator. What M7 left open is listed under "Found while implementing M7".
