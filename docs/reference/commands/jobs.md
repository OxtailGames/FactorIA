[Back to the index](../README.md)

# Commands: jobs

## `jobs.info`

Not released yet (on main after 0.18.0).

The job system now: worker threads, mode, jobs run and queued last frame, how busy each thread was.

mode is "threads" (a pool of workers; 0 workers means jobs run on the main thread when it waits for them or at the end of the frame), "inline" (debugging: every job runs on the main thread when it is submitted) or "stopped". setting is the value the pool was started with and source where this engine's setting came from ("EngineConfig", "FA_JOB_THREADS", "factoria.json" for runtime.jobThreads, or "default" = "auto"; a second engine in the same process shares the first one's pool); autoWorkers is what "auto" gives on this machine. lastFrame and lanes (one per thread: main, worker 1..) count the last finished frame; busyMs and busyPct are wall time, rounded, and differ from run to run. Threads never change what the game computes (game.state_hash checks it). Example: jobs.info {}

