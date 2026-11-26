# rt_cost: the scene behind the ray tracing costs of docs/RAY_TRACING.md

A courtyard at 1920 x 1080: a sun and three point lights that cast shadows, a ground and a wall, 40 boxes, spheres, cylinders, capsules and
cones of every roughness (a third of them metal), four glass spheres, a mirror sphere, a glossy one and a `RealtimeGI` grid. It is not a
game and has no budget file: it is what the table of "What it costs" was measured on.

To measure an effect, put it in `factoria.json` (`"render": {"rayTracing": {"enabled": true, "ao": true}}`) in a copy of this folder and
compare the wall clock of two runs, for 60 and for 360 frames, timed from outside (`time` on macOS and Linux,
`Measure-Command` on Windows; `perf.measure` itself reports only CPU time):

    time factoria call --project <copy> perf.measure '{"frames":60}'
    time factoria call --project <copy> perf.measure '{"frames":360}'

(the difference of the two times over 300 frames is the frame time with the GPU kept busy; `cpuMs*` is CPU time and does not see the GPU).
The path tracer: `factoria call --project <copy> render.pathtrace '{"samples":72,"path":"out.png"}'` against 8 samples.
