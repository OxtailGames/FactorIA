// `project.serve_web`: the web build of the game on a small HTTP server inside this process (the editor, `factoria mcp`, a
// `factoria session`), so a browser on this computer or a phone on the same Wi-Fi can play the current state of the project.
//
//   - The game is exported as a web build into <project>/build/serve-web/{a,b} (two folders: the page is served from one while
//     the next export is written into the other, then the server switches). The project's own export folder is not touched.
//   - Localhost (127.0.0.1) unless `lan`; always a random port and a random token in the URL path
//     (http://host:port/<token>/): a request without the token is a 404. The server is stopped with the process or by stop().
//   - A thread watches the project: when a script, scene, asset or factoria.json changes, the game is exported again (after the
//     files stopped changing) and the page reloads itself. The page polls <token>/__fa/version once a second.
//   - The page sends what the game logs (console.log/warn/error, uncaught errors) back with POST <token>/__fa/log; the lines
//     land in the log (category "phone") and so in the editor console.
//   - Bounded: head 8 KB, log body 16 KB, 8 connections served at a time and 32 waiting, then new ones are closed; a connection
//     that sends nothing is closed after 5 s. Only files below the export folder are served, by a strict path check.
#pragma once

#include <cstdint>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct ServeWebOptions {
    std::string projectDir;            // folder with factoria.json
    bool lan = false;                  // listen on every interface (the LAN can connect) instead of 127.0.0.1 only
    std::string playerBinary;          // like ExportOptions::playerBinary: a folder with factoria_player.js/.wasm ("" = find it)
    bool allowPlayerMismatch = false;  // like ExportOptions::allowPlayerMismatch
    std::string buildSourceRoot;       // like ExportOptions::buildSourceRoot (tests)
    int pollMs = 1000;                 // how often the project is checked for changes (tests make it shorter)
};

struct ServeWebStatus {
    bool running = false;
    std::string state = "stopped";  // "stopped", "exporting" (the first export or a re-export is running), "ready" or "failed" (the last export failed)
    std::string projectDir;
    std::string outputDir;              // the folder being served (empty before the first export)
    bool lan = false;
    int port = 0;
    std::string localUrl;               // http://127.0.0.1:<port>/<token>/
    std::vector<std::string> lanUrls;   // http://<address>:<port>/<token>/ for each private address of this computer (lan only)
    std::string error, hint;            // state "failed": why the last export failed
    std::vector<std::string> warnings;  // of the last export, and "no LAN address" when lan found none
    std::uint64_t version = 0;          // successful exports since the start: a page reloads when it changes
    std::uint64_t requests = 0;         // answered requests
    std::uint64_t phoneLogLines = 0;    // log lines received from pages
    Json to_json() const;
};

// The server. One object serves one project; start() after a start() restarts it. All methods are thread-safe (a start() or stop()
// waits for another one). Nothing here
// waits for an export except wait_ready() and stop() (which waits for a running export to finish: seconds): call them from
// a thread that may block, never from the editor's UI thread.
class WebServer {
public:
    WebServer();
    ~WebServer();  // stop()
    WebServer(const WebServer&) = delete;
    WebServer& operator=(const WebServer&) = delete;

    // Binds the listener (the error says which call failed) and starts the threads; the first export runs in the background.
    // Returns at once; the status says "exporting" until it is done. Restarts a running server.
    Result<void> start(const ServeWebOptions& options);
    // Stops the threads and closes every connection. A no-op when not running.
    void stop();
    bool running() const;
    ServeWebStatus status() const;
    // Waits until the first export has finished (state "ready" or "failed") or the server stopped; returns the status.
    // `timeoutMs` is a safety net far above an export's time.
    ServeWebStatus wait_ready(int timeoutMs = 10 * 60 * 1000);
    // Checks the project for changes now instead of at the next poll (a test, or the editor after saving).
    void refresh();

private:
    struct Impl;
    std::shared_ptr<Impl> current() const;  // the running server (or null); a status() in flight keeps it alive while stop() joins
    void stop_locked();
    std::shared_ptr<Impl> impl_;
    mutable std::mutex ptrMutex_;  // guards impl_ only, held for a pointer copy: status() never waits for a start or a stop
    std::mutex lifecycleMutex_;    // one start()/stop() at a time (the editor's window and the command can both call them)
};

// The server of this process: the one project.serve_web and the editor's "Play on phone" window share.
WebServer& web_server();

// Registers command "project.serve_web" for the project at `projectDir`. It starts web_server() (or reuses it when it already
// serves this project with the same `lan`), waits for the first export and returns the status; {stop:true} stops it.
void register_serve_web_commands(CommandRegistry& registry, const std::string& projectDir);

// Pieces the tests (and the editor) use.
namespace serve_web_detail {
// The Content-Type of a file by its extension (case-insensitive): application/wasm for .wasm, text/javascript for .js...
std::string mime_type(std::string_view fileName);
// The file a URL path below the token names, relative to the export folder with '/' separators, or nullopt when it is not safe:
// percent-decoded once, then no empty, "." or ".." segment, no segment starting with '.', no backslash, colon, control
// character or other character Windows file names forbid, and no encoded slash or percent sign left over.
std::optional<std::string> safe_relative_path(std::string_view urlPath);
}  // namespace serve_web_detail

}  // namespace fa
