[Back to the index](../README.md)

# Commands: engine

## `engine.info`

Show engine version, platform, graphics backend and loop state.

Returns {engineVersion, platform, graphics, headless, frame, paused, fixedHz, components, commands}. Example: engine.info {}

## `engine.update_status`

Not released yet (on main after 0.3.0).

Tell whether FactorIA was updated on disk while this process runs, and so whether a restart is due.

Returns {running, onDisk, restartDue, state, executable, summary, ...}: `running` and `onDisk` are {version, fingerprint, label}: the build this process was started from and the one now in the `factoria` file it was started from (the build fingerprint written inside the file, not just its date). state: current | updated_on_disk | unidentified (the file changed but has no comparable identity) | settling (it is being written). When `restartDue`, what to do depends on the host: in the editor (`editor` is present) the user presses Restart in the notice; under `factoria mcp` (`mcp` is present) the server restarts itself between two calls on Linux and macOS and says so in the next tool result, on Windows the client must reconnect the factoria server (Claude Code: /mcp). `mcp.projectConfig` says whether the client was started with the .mcp.json now on disk. Details: docs_read {"name":"mcp"}. Example: {}.

