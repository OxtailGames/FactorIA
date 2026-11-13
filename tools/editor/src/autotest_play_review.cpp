// Autotest sections R3, A3, T2, S3 and R4: the Level generator, paid asset calls, Play on phone, Play sessions and the
// Review window.
// Split from autotest_tools.cpp: each section is an Editor::at_section_<id>(AtScript&) that adds its steps to the script,
// called by at_build_tools_script in the order of the full run (autotest_sections.h).
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <memory>
#include <mutex>
#include <atomic>
#include <thread>

#include "ai_project_edit.h"
#include "auto_play_job.h"
#include "autotest_common.h"
#include "autotest_sections.h"
#include "editor_internal.h"
#include "fa/ai/command_hooks.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/savers.h"
#include "fa/core/date.h"
#include "fa/core/jobs.h"
#include "fa/tooling/feedback_share.h"
#include "fa/tooling/net.h"
#include "fa/tooling/play_auto.h"
#include "fa/tooling/qr.h"
#include "sokol_app.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

using namespace at_support;

namespace {

namespace stdfs = std::filesystem;

}  // namespace

void Editor::at_section_R3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------------- R3. Level generator
    // View > Level generator (docs/EDITOR.md, "Level generator"): a drawn level is the sample, Generate makes a level, Next / Previous seed
    // walk the seeds (the same seed gives the same rows again), Keep builds the preview in the open scene as ONE undo step, Save writes a
    // level file. Every wait is a state, not a number of frames.
    {
        struct Ps {
            size_t undo = 0;
            std::vector<std::string> first;
            std::int64_t firstSeed = 0;
            std::string saved;
        };
        auto ps = std::make_shared<Ps>();
        // Waits for the end of the generation (Ready or Failed) and then checks it is Ready: a failure is fast and says why, instead
        // of a 60 s wait that times out.
        auto wait_ready = [this, &step] {
            step(1, [this] {
                atWaitCount_ = 0;
                atWaitUntil_ = [this] {
                    return levelGen_.state() == LevelGenSession::State::Ready || levelGen_.state() == LevelGenSession::State::Failed;
                };
            });
            step(1, [this] {
                at_check(levelGen_.state() == LevelGenSession::State::Ready, "the generation ended with a level (" + levelGen_.error() + ")");
            });
        };
        step(2, [this] {
            run_console_line(
                "scene.import_ascii {\"rows\":[\"............\",\"..####..##..\",\"..#..#..##..\",\"..#..#......\",\"..####..#...\",\"..........#.\","
                "\"....#.......\",\"............\"],\"legend\":{\"#\":0},\"entity\":\"at_sample\",\"tilemap\":{\"tileSize\":[16,16],\"solidTiles\":[0]}}");
        });
        click("menu:view");
        step(3, [] {});
        click("menu:levelgen");
        step(4, [this] {
            at_check(showLevelGen_, "View > Level generator shows the Level generator window");
            pendingFocus_ = "Level generator";
            levelGenKeepName_ = "at_generated";
            levelGenSavePath_ = "levels/at-generated.json";
            levelGenOpt_.width = 20;
            levelGenOpt_.height = 12;
            levelGenOpt_.seed = 1;
            levelGenOpt_.n = 2;
            select_id("at_sample");
        });
        step(3, [this] { at_check(at_enabled("levelgen:use-selected") && at_shown("levelgen:use-selected"), "the sample button is on and on screen with a Tilemap selected"); });
        click("levelgen:use-selected");
        step(3, [this] {
            at_check(levelGenOpt_.sampleEntity == "at_sample", "Use the selected Tilemap makes the selected level the sample (" + levelGenOpt_.sampleEntity + ")");
        });
        click("levelgen:generate");
        wait_ready();
        step(3, [this, ps] {
            const LevelGenPreview& p = levelGen_.preview();
            at_check(p.valid && p.width == 20 && p.height == 12 && p.rows.size() == 12, "Generate fills the preview: a 20 x 12 level");
            at_check(p.cells.size() == 240, "...with a table of its 240 cells, built once when the generation ended");
            at_check(p.seed == 1, "...for the seed in the window");
            ps->first = p.rows;
            ps->firstSeed = p.seed;
            at_check(at_shown("levelgen:stats") && at_shown("levelgen:preview"), "...the numbers and the plan are on screen");
        });
        snap("editor_level_generator.png");
        click("levelgen:next");
        wait_ready();
        step(3, [this] {
            at_check(levelGenOpt_.seed == 2 && levelGen_.preview().seed == 2, "Next seed generates the level of seed 2 at once");
            at_check(levelGen_.tries().size() >= 2, "...and the history keeps both seeds");
        });
        click("levelgen:prev");
        wait_ready();
        step(3, [this, ps] {
            at_check(levelGen_.preview().seed == ps->firstSeed && levelGen_.preview().rows == ps->first, "Previous seed brings the first level back, row by row");
            ps->undo = undo_depth();
        });
        click("levelgen:keep");
        step(4, [this, ps] {
            Entity kept = world().find_by_id("at_generated");
            at_check(!kept.is_null(), "Keep builds the level as the entity at_generated");
            const Tilemap* tm = kept.is_null() ? nullptr : world().get<Tilemap>(kept);
            at_check(tm && tm->width == 20 && tm->height == 12 && tm->tileSize.x == 16.0f, "...a 20 x 12 Tilemap with the sample's tile size");
            at_check(tm && tm->solidTiles.is_array() && tm->solidTiles.size() == 1, "...and the sample's solid tiles");
            at_check(undo_depth() == ps->undo + 1 && dirty(), "...as one undo step, and the scene is marked changed");
            at_check(selected_id() == "at_generated", "...selected");
        });
        click("levelgen:save");
        step(4, [this, project_file, ps] {
            ps->saved = read_file(project_file("levels/at-generated.json"));
            Result<Json> parsed = parse_json(ps->saved, "levels/at-generated.json");
            const Json doc = parsed.ok() ? parsed.value() : Json();
            at_check(doc.is_object() && doc.contains("rows") && doc["rows"].size() == 12 && doc.contains("legend"),
                     "Save level file writes the rows and the legend to levels/at-generated.json");
            at_check(!levelGenMessageBad_ && levelGenMessage_.find("at-generated.json") != std::string::npos, "...and says so");
            at_check(!at_shown("levelgen:replace"), "...a new file is written without asking");
            undo();
            at_check(world().find_by_id("at_generated").is_null(), "Ctrl+Z takes the kept level away");
        });
        // The file exists now: Save asks before it replaces it.
        click("levelgen:next");
        wait_ready();
        step(3, [] {});
        click("levelgen:save");
        step(4, [this, project_file, ps] {
            at_check(at_shown("levelgen:replace") && at_shown("levelgen:replace-cancel"), "Saving over an existing file opens the Replace popup");
            at_check(read_file(project_file("levels/at-generated.json")) == ps->saved, "...and has not touched the file yet");
        });
        click("levelgen:replace-cancel");
        step(4, [this, project_file, ps] {
            at_check(!at_shown("levelgen:replace"), "Cancel closes the popup");
            at_check(read_file(project_file("levels/at-generated.json")) == ps->saved, "...and leaves the file as it was");
        });
        click("levelgen:save");
        step(4, [this] { at_check(at_shown("levelgen:replace"), "Save asks again"); });
        click("levelgen:replace");
        step(4, [this, project_file, ps] {
            const std::string now = read_file(project_file("levels/at-generated.json"));
            at_check(now != ps->saved, "Replace writes the new level over the file");
            Result<Json> parsed = parse_json(now, "levels/at-generated.json");
            at_check(parsed.ok() && parsed.value().contains("rows") && parsed.value()["rows"] == Json(levelGen_.preview().rows),
                     "...the rows shown in the window");
            at_check(!levelGenMessageBad_ && levelGenMessage_.find("Wrote") == 0, "...and says so");
            at_check(!at_shown("levelgen:replace"), "...and the popup is gone");
        });
        // ---- leave the editor as the other sections expect it
        step(2, [this, project_file] {
            showLevelGen_ = false;
            levelGen_.clear(level_gen_caller());
            std::error_code ec;
            stdfs::remove(project_file("levels/at-generated.json"), ec);
        });
    }
}

void Editor::at_section_A3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ---------------------------------------------------------------------------------- A3. Paid asset calls wait for the user's yes
    // docs/AI_COSTS.md, "Asset generation": a paid asset call of an AI run above limits.askAboveUsd waits for the user. The call is the
    // real AssetCostGuard on its own thread (what an agent or MCP thread does), its approver the editor's; the user folder is a scratch
    // one given to THAT thread only (AssetRunScope's spend env: no global that the editor's other threads could read), so the day total
    // never touches the real ~/.factoria. The card sits under the chat, in the window of the 1024x642 display too, with a long prompt.
    // Stop is the real button of a run (a stand-in AiRun, running, with no agent thread): its cancel flag ends the wait.
    {
        struct A3 {
            ShareEnv env;                       // the scratch user folder; outlives the thread (the guard keeps a pointer to it)
            std::thread th;
            std::mutex mu;
            std::string outcome;
            std::atomic<bool> done{false};
            CancelFlag stop{false};             // what the thread's call waits on: set from the run's cancel flag, or when the section ends
            std::string chat, project, prompt;
            std::size_t items = 0;
            ~A3() {                             // a section that aborts must not leave the thread waiting for a card nobody answers
                stop = true;
                if (th.joinable()) th.join();
            }
        };
        auto x = std::make_shared<A3>();
        // One paid call: 4 images, about $1.20 (above the 0.50 default).
        auto call = [this, x](double usd) {
            if (x->th.joinable()) x->th.join();
            x->done = false;
            x->stop = false;
            x->outcome.clear();
            x->th = std::thread([this, x, usd] {
                std::string outcome;
                try {
                    ai::AssetRunScope scope(x->chat, [this](const ai::AssetApprovalRequest& r) { return aiApprovals_.ask(r); }, &x->env);
                    ai::Limits limits;
                    ai::AssetCall c;
                    c.command = "assets.generate_image";
                    c.what = "4 images of a ruby at assets/gems/ruby.png";
                    c.prompt = x->prompt;
                    c.projectDir = x->project;
                    c.provider = "openai";
                    c.model = "gpt-image-1";
                    c.kind = ai::MediaKind::Image;
                    c.estimate.usd = usd;
                    c.estimate.count = 4;
                    c.estimate.basis = "4 x 1024x1024 auto at $0.30";
                    c.estimate.checked = "2026-11-06";
                    c.estimate.source = "https://example.com/prices";
                    c.cancel = &x->stop;
                    ai::AssetCostGuard guard = ai::AssetCostGuard::begin(limits, c, false);
                    outcome = guard.go() ? "go" : "needsApproval";
                    if (guard.go()) guard.commit();
                } catch (const CommandError& e) {
                    outcome = e.code;
                } catch (const std::exception& e) {
                    outcome = std::string("exception: ") + e.what();
                }
                {
                    std::lock_guard<std::mutex> lock(x->mu);
                    x->outcome = outcome;
                }
                x->done = true;
            });
        };
        auto outcome = [x] {
            std::lock_guard<std::mutex> lock(x->mu);
            return x->outcome;
        };
        auto wait_card = [this, &step] {
            step(1, [this] {
                atWaitCount_ = 0;
                atWaitUntil_ = [this] { return at_shown("ai:approve:yes"); };
            });
        };
        auto wait_done = [this, x, &step] {
            step(1, [this, x] {
                atWaitCount_ = 0;
                // the run's cancel flag is what ai_start hands the commands; the stand-in run's is relayed to the thread's call
                atWaitUntil_ = [this, x] {
                    if (const AiRun* r = ai_run_of(x->chat); r && r->cancel.load()) x->stop = true;
                    return x->done.load();
                };
            });
        };
        step(2, [this, x] {
            const std::string home = atOutDir_ + "/asset_home";
            x->env.env = [home](const std::string& name) -> std::string { return name == "HOME" || name == "USERPROFILE" || name == "APPDATA" ? home : ""; };
            x->chat = chat_.current().id;
            x->project = projectDir_;
            // a long prompt: the card must keep its buttons in a narrow window
            x->prompt = "a ruby, pixel art, 32x32, red with a white glint, on a transparent background, in the style of the house palette; " +
                        std::string(300, 'x') + " (end of a long prompt)";
            x->items = chat_.current().items.size();
            ai::asset_run_begin(x->chat);
            focus_window("AI Assistant");
        });
        // ---- Approve: the call waits, the card says what, how many, which provider and the estimate
        step(3, [call] { call(1.20); });
        wait_card();
        step(4, [this, x, outcome] {
            at_check(outcome().empty() && !x->done, "the paid call above the ask limit waits for the user (it has not been made)");
            at_check(aiApprovals_.waiting_for(x->chat), "...and the chat has a card");
            at_check(at_visible("ai:approve:yes") && at_visible("ai:approve:all") && at_visible("ai:approve:cancel"),
                     "the card has Approve, Approve all for this run and Cancel");
            const auto cards = aiApprovals_.cards();
            at_check(cards.size() == 1, "one card is waiting");
            if (!cards.empty()) {
                const AssetCardText t = asset_card_text(cards[0].plan);
                at_check(t.title.find("$1.20") != std::string::npos && t.title.find("4 x image") != std::string::npos &&
                             t.title.find("openai") != std::string::npos,
                         "the card names the estimate, the count and the provider: " + t.title);
                at_check(t.estimate.find("prices checked 2026-11-06") != std::string::npos, "...and when the prices were checked: " + t.estimate);
            }
            at_check(ai::asset_run_spent(x->chat) == 0.0, "nothing is counted as spent while the card waits");
        });
        snap("editor_ai_asset_card.png");
        click("ai:approve:yes");
        wait_done();
        step(3, [this, x, outcome] {
            at_check(outcome() == "go", "Approve lets the call go ahead: " + outcome());
            at_check(!aiApprovals_.waiting_for(x->chat), "...and the card is gone");
            at_check(std::abs(ai::asset_run_spent(x->chat) - 1.20) < 0.001, "...and the estimate is counted into the run");
            at_check(chat_.current().items.size() > x->items && chat_.current().items.back().text.find("You approved") == 0,
                     "...and the chat says what the user approved");
            at_check(!ai::asset_run_approves_all(x->chat), "Approve alone does not approve the next call");
        });
        // ---- Approve all for this run: this call goes, the next one does not ask
        step(2, [call] { call(1.20); });
        wait_card();
        click("ai:approve:all");
        wait_done();
        step(3, [this, x, outcome] {
            at_check(outcome() == "go", "Approve all lets the call go ahead: " + outcome());
            at_check(ai::asset_run_approves_all(x->chat), "...and turns the questions off for this run");
        });
        step(2, [call] { call(1.20); });
        wait_done();
        step(3, [this, x, outcome] {
            at_check(outcome() == "go" && !aiApprovals_.waiting_for(x->chat), "the next paid call of the run goes without a card: " + outcome());
            at_check(std::abs(ai::asset_run_spent(x->chat) - 3.60) < 0.001, "...and still counts into the run (3 x $1.20)");
        });
        // ---- Cancel: the call is declined, nothing is spent
        step(2, [x, call] {
            ai::asset_run_begin(x->chat);  // a new run: the questions are back
            call(1.20);
        });
        wait_card();
        click("ai:approve:cancel");
        wait_done();
        step(3, [this, x, outcome] {
            at_check(outcome() == "asset_declined", "Cancel declines the call (asset_declined): " + outcome());
            at_check(ai::asset_run_spent(x->chat) == 0.0 && !ai::asset_run_approves_all(x->chat), "...and nothing is spent");
            at_check(chat_.current().items.back().text.find("You declined") == 0, "...and the chat says so");
        });
        // ---- Stop while a card waits: the Stop button of the run ends the wait as "cancelled" (not "declined"), the card goes
        step(2, [this, x, call] {
            auto run = std::make_unique<AiRun>(x->chat);   // a run with no agent thread: it only has to be running for Stop
            run->running = true;
            const long long nowMs = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now().time_since_epoch()).count();
            run->lastActivityMs = nowMs;
            run->startMs = nowMs;
            aiRuns_.push_back(std::move(run));
            call(1.20);
        });
        wait_card();
        step(3, [this, x] {
            at_check(ai_run_of(x->chat) && !ai_run_of(x->chat)->cancel.load(), "a run is going and not stopped before the Stop button");
            at_check(at_shown("ai:stop"), "the run's Stop button is on screen while its card waits");
        });
        click("ai:stop");
        wait_done();
        step(3, [this, x, outcome] {
            at_check(ai_run_of(x->chat) && ai_run_of(x->chat)->cancel.load(), "the Stop button set the run's cancel flag");
            at_check(outcome() == "cancelled" && !aiApprovals_.waiting_for(x->chat),
                     "stopping the run ends the wait as cancelled (not declined) and the card goes: " + outcome());
            at_check(ai::asset_run_spent(x->chat) == 0.0, "...and nothing is spent");
            // the stand-in run ends like a real one whose turn ended
            if (AiRun* r = ai_run_of(x->chat)) {
                ai::SessionResult res;
                res.ok = false;
                res.stopReason = "cancelled";
                r->turn_ended(std::move(res));
            }
        });
        step(1, [this, x] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this, x] { return ai_run_of(x->chat) == nullptr; };
        });
        // ---- leave the editor as the other sections expect it
        step(2, [this, x] {
            if (x->th.joinable()) x->th.join();
            ai::asset_run_begin(x->chat);
            std::error_code ec;
            stdfs::remove_all(atOutDir_ + "/asset_home", ec);
            if (chat_.current().id == x->chat) chat_.current().items.resize(std::min(chat_.current().items.size(), x->items));
        });
    }
}

void Editor::at_section_T2(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------------- T2. Play on phone
    // File > Play on Phone... (docs/EDITOR.md, "Play on Phone"): Start without a web player says how to get one; with a stand-in player the
    // server answers on its token, the window shows the LAN address as a QR code (or says there is none), a log line POSTed like the
    // phone's page does lands in the log with category "phone", a changed file exports again, Stop closes the port. Every wait is a state
    // (atWaitUntil_ holds the script for up to 60 s of wall clock, an export takes about a second: a loaded 4-vCPU VM has a wide margin).
    // The window starts the server for the Wi-Fi (0.0.0.0) because the QR code of the LAN address is part of what this section checks;
    // the requests below all go to 127.0.0.1, and the server of the unit tests (serve_web_test) binds loopback only except in its lan case.
    {
        struct Ps {
            int port = 0;
            std::string base;
            std::uint64_t version = 0;
        };
        auto ps = std::make_shared<Ps>();
        // One request to the server on this computer, the reply's first line and body ("" = could not connect).
        auto http = [](int port, const std::string& request) {
            net::Socket s = net::connect_loopback(static_cast<std::uint16_t>(port));
            if (s == net::kNoSocket) return std::string();
            net::set_io_timeouts(s, 20000, 20000);
            net::send_all(s, request);
            std::string all;
            char buf[4096];
            std::ptrdiff_t n;
            while ((n = net::recv_some(s, buf, sizeof(buf))) > 0) all.append(buf, static_cast<size_t>(n));
            net::close_socket(s);
            return all;
        };
        step(2, [this] {
            web_server().stop();
            // A stand-in for the web player: the two files the export copies. No build fingerprint, so the window is told to accept it.
            const std::string dir = atOutDir_ + "/phone-player";
            std::error_code ec;
            stdfs::create_directories(dir, ec);
            { std::ofstream(dir + "/factoria_player.js", std::ios::binary) << "// stand-in glue\n"; }
            { std::ofstream(dir + "/factoria_player.wasm", std::ios::binary) << std::string("\0asm\1\0\0\0", 8) << std::string(512, 'w'); }
            phonePlayer_ = atOutDir_ + "/no-web-player-here";
            phoneAllowMismatch_ = true;
        });
        click("menu:file");
        step(3, [] {});
        click("menu:play-phone");
        step(4, [this] {
            at_check(showPhone_, "File > Play on Phone... opens the Play on phone window");
            at_check(at_shown("phone:start") && at_enabled("phone:start"), "...with a Start button on screen");
            at_check(!at_visible("phone:stop") && !at_visible("phone:qr"), "...and no Stop button or code before it starts");
            at_check(at_visible("phone:help"), "...and the checklist for a phone that cannot connect");
            const std::vector<std::string>& help = phone_help_lines();
            auto mentions = [&help](const char* word) {
                return std::any_of(help.begin(), help.end(), [word](const std::string& l) { return l.find(word) != std::string::npos; });
            };
            at_check(mentions("same Wi-Fi") && mentions("firewall") && mentions("Windows") && mentions("macOS") && mentions("Guest Wi-Fi") + mentions("guest Wi-Fi") > 0,
                     "...which names the same Wi-Fi, the firewall prompt on Windows and macOS and guest networks");
        });
        click("phone:start");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !phone_.busy() && !phoneError_.empty(); };
        });
        step(3, [this] {
            at_check(!web_server().running(), "Start without a web player does not start a server");
            at_check(phoneError_.find("not found") != std::string::npos, "...and the window says why (" + phoneError_ + ")");
            at_check(phoneHint_.find("factoria_player") != std::string::npos, "...and how to fix it (" + phoneHint_ + ")");
            at_check(at_shown("phone:start"), "...Start stays available");
            phonePlayer_ = atOutDir_ + "/phone-player";
        });
        click("phone:start");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [] { return web_server().status().state == "ready" || web_server().status().state == "failed"; };
        });
        step(4, [this, ps] {
            const ServeWebStatus st = web_server().status();
            at_check(st.running && st.state == "ready", "Start with a player exports the web build and serves it (" + st.state + " " + st.error + ")");
            at_check(phoneError_.empty() && at_shown("phone:stop") && !at_visible("phone:start"), "...the window offers Stop now");
            at_check(st.lan && st.localUrl.rfind("http://127.0.0.1:", 0) == 0, "...for the Wi-Fi, with a token in the address");
            ps->port = st.port;
            ps->base = st.localUrl.substr(st.localUrl.find('/', 8));
            ps->version = st.version;
            if (!st.lanUrls.empty()) {
                const std::string url = st.lanUrls.front();
                auto expect = qr_encode(url, QrEcc::Medium);
                at_check(phoneQr_.has_value() && expect.ok() && phoneQr_->size == expect->size && phoneQr_->modules == expect->modules && phoneQrUrl_ == url,
                         "...the LAN address is drawn as its QR code");
                at_check(at_shown("phone:qr") && at_shown("phone:url") && at_shown("phone:copy"), "...with the address and Copy address on screen");
                at_check(phoneQr_.has_value() && phoneQr_->version <= 6, "...a code a phone camera reads at a glance (version " + std::to_string(phoneQr_ ? phoneQr_->version : 0) + ")");
            } else {
                at_check(at_visible("phone:no-lan") && !phoneQr_.has_value(), "No Wi-Fi address on this computer: the window says so instead of drawing a code");
            }
            at_check(at_shown("phone:open") && at_visible("phone:state"), "...Open on this computer and the state line are there");
        });
        snap("editor_play_phone.png");
        // The phone's page: it asks for its files and POSTs what it logs.
        step(3, [this, ps, http] {
            const std::string page = http(ps->port, "GET " + ps->base + " HTTP/1.1\r\nHost: x\r\n\r\n");
            at_check(page.rfind("HTTP/1.1 200", 0) == 0 && page.find("__fa/client.js") != std::string::npos, "The address serves the page with the reload and log script");
            at_check(http(ps->port, "GET /wrong-token/ HTTP/1.1\r\n\r\n").rfind("HTTP/1.1 404", 0) == 0, "...and a path without the token is a 404");
            const std::string body = R"([{"l":"error","t":"T2 phone says hello"}])";
            const std::string reply = http(ps->port, "POST " + ps->base + "__fa/log HTTP/1.1\r\nContent-Length: " + std::to_string(body.size()) + "\r\n\r\n" + body);
            at_check(reply.rfind("HTTP/1.1 204", 0) == 0, "A log line POSTed like the phone's page does is accepted");
            bool found = false;
            for (const LogEntry& e : recent_logs(200, LogLevel::Trace))
                if (e.category == "phone" && e.message == "T2 phone says hello" && e.level == LogLevel::Error) found = true;
            at_check(found, "...and comes back to the console as an error of category \"phone\"");
            at_check(web_server().status().phoneLogLines >= 1, "...and is counted in the window");
        });
        // A changed file: exported again, the version moves (what makes the page reload).
        step(2, [this] {
            std::error_code ec;
            stdfs::create_directories(projectDir_ + "/assets", ec);
            std::ofstream(projectDir_ + "/assets/t2-live.txt", std::ios::binary) << "changed while the phone page is open";
            web_server().refresh();
        });
        step(1, [this, ps] {
            atWaitCount_ = 0;
            atWaitUntil_ = [ps] { return web_server().status().version > ps->version && web_server().status().state == "ready"; };
        });
        step(3, [this, ps, http] {
            at_check(web_server().status().version > ps->version, "A new file in the project exports the web build again (the page reloads on the new version)");
            const std::string pak = http(ps->port, "GET " + ps->base + "game.pak HTTP/1.1\r\n\r\n");
            at_check(pak.rfind("HTTP/1.1 200", 0) == 0 && pak.find("application/octet-stream") != std::string::npos, "...and the new build is served");
        });
        click("phone:stop");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return !phone_.busy() && !web_server().running(); };
            atWaitWhat_ = "Stop to end the web server";
        });
        step(4, [this, ps, http] {
            at_check(!web_server().running(), "Stop ends the server");
            at_check(http(ps->port, "GET " + ps->base + " HTTP/1.1\r\n\r\n").empty(), "...its port refuses connections");
            // The check above is a blocking request (seconds on a loaded VM, none of them drawn): the window shows the
            // new state a few frames after the server stopped, so wait for the frames instead of counting them.
            atWaitCount_ = 0;
            atWaitUntil_ = [this] {
                return at_shown("phone:start") && !at_visible("phone:stop") && !at_visible("phone:qr");
            };
            atWaitWhat_ = "the Phone window to offer Start again and no code after Stop";
        });
        step(1, [this] {
            const auto yn = [](bool b) { return b ? "yes" : "no"; };
            at_check(at_shown("phone:start") && !at_visible("phone:stop") && !at_visible("phone:qr"),
                     std::string("...the window offers Start again and no code (start shown ") +
                         yn(at_shown("phone:start")) + ", stop visible " + yn(at_visible("phone:stop")) +
                         ", code visible " + yn(at_visible("phone:qr")) + ", busy " + yn(phone_.busy()) + ")");
        });
        // ---- leave the editor as the other sections expect it
        step(2, [this] {
            showPhone_ = false;
            phonePlayer_.clear();
            phoneAllowMismatch_ = false;
            std::error_code ec;
            stdfs::remove(projectDir_ + "/assets/t2-live.txt", ec);
            stdfs::remove_all(projectDir_ + "/build/serve-web", ec);
        });
    }
}

void Editor::at_section_S3(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // ----------------------------------------------------------------------------------------- S3. Play > Let the AI Play
    // Play > Let the AI Play and Play > Play Sessions (docs/EDITOR.md, "Play sessions"): the list marks the sessions the AI's bot played,
    // "Attach last play session" never silently picks one of them, and a real play.auto run (a child `factoria`, FA_FACTORIA_EXE, on a
    // worker thread) ends with its session listed, marked and opened, while the window keeps drawing. Waits are states; the window is
    // the 1024x642 one of the macOS runner.
    {
        struct As {
            std::string person = "29990101-000001", bot = "29990101-000002-auto";
            std::string realSession;
            std::uint64_t frames0 = 0;
            bool exe = false, sawRunning = false, hadEnv = false;
            std::string prevEnv, sleeper;
        };
        auto as = std::make_shared<As>();
        auto set_env = [](const char* name, const std::string& value) {
#ifdef _WIN32
            _putenv_s(name, value.c_str());
#else
            setenv(name, value.c_str(), 1);
#endif
        };
        auto sessions_dir = [project_file](const std::string& name) { return project_file(".factoria/sessions/" + name); };
        auto row_of = [this](const std::string& name) -> const PlaySessionRow* {
            for (const PlaySessionRow& r : playSessionRows_)
                if (r.name == name) return &r;
            return nullptr;
        };
        step(2, [this, as, sessions_dir] {
            as->exe = !auto_play_executable().empty();
            std::error_code rm;  // the sessions of an earlier section (or run) of this temp project are not part of what is counted below
            stdfs::remove_all(stdfs::path(projectDir_ + "/.factoria/sessions"), rm);
            stdfs::create_directories(stdfs::path(sessions_dir(as->person)));
            stdfs::create_directories(stdfs::path(sessions_dir(as->bot)));
            write_file(sessions_dir(as->person) + "/session.json",
                       R"({"scene":"scenes/main.scene.json","durationSec":4.0,"frames":240,"marks":[{"n":1,"frame":10,"time":0.2,"note":"fake person mark","screenshot":""}],"logs":[]})");
            write_file(sessions_dir(as->bot) + "/session.json",
                       R"({"source":"auto","scene":"scenes/main.scene.json","durationSec":30.0,"frames":1800,"ended":"stuck","endedWhy":"fake bot stuck","score":null,"phases":[{"name":"main","kind":"scene","scene":"scenes/main.scene.json","frame":0,"time":0.0,"screenshot":""}],"marks":[{"n":1,"frame":900,"time":15.0,"kind":"stuck","note":"fake bot problem","screenshot":""}],"logs":[],"notes":["fake note"],"auto":{"bot":"explorer","replay":"factoria player --replay x"}})");
            autoPlaySeconds_ = 5;  // a real run below plays the least the window allows, with no pictures: no graphics device in the child
            autoPlayPictures_ = false;
        });
        click("menu:play");
        step(3, [] {});
        click("menu:play-sessions");
        step(4, [this, as, row_of] {
            at_check(showPlaySessions_, "Play > Play Sessions opens the Play sessions window");
            const PlaySessionRow* p = row_of(as->person);
            const PlaySessionRow* b = row_of(as->bot);
            at_check(p && !p->isAuto && p->marks == 1, "the list has the session you played, not marked as the AI's");
            at_check(b && b->isAuto && b->ended == "stuck" && b->marks == 1, "...and the AI's bot session, marked as auto with how it ended");
            at_check(b && play_session_label(*b).find("AI") != std::string::npos && p && play_session_label(*p).find("you") != std::string::npos,
                     "...the rows say who played");
            at_check(at_shown("playsessions:row:" + as->person) && at_shown("playsessions:row:" + as->bot) && at_shown("playsessions:run"),
                     "...the rows and the Let the AI play button are on screen");
        });
        click("playsessions:row:" + as->bot);
        step(3, [this, as] {
            at_check(playSessionsPick_ == as->bot, "a click on a row picks it");
            at_check(at_shown("playsessions:ended") && at_shown("playsessions:attach"), "...its report shows how the bot's run ended, and the Attach button");
            at_check(playSessionDoc_.is_object() && playSessionDoc_.value("endedWhy", std::string()) == "fake bot stuck", "...read from its session.json");
        });
        snap("editor_play_sessions.png");
        // ---- "Attach last play session" is the person's, even when the bot's session is newer
        step(2, [this, as] {
            ai_sync_chats();
            chat_.current().input.clear();
            ai_attach_last_session();
            const std::string in = chat_.current().input;
            at_check(in.find("fake person mark") != std::string::npos, "Attach last play session puts in the session you played...");
            at_check(in.find("play.auto") == std::string::npos && in.find("bot") == std::string::npos, "...not the newer one of the AI's bot");
            chat_.current().input.clear();
            std::error_code ec;
            stdfs::remove_all(stdfs::path(projectDir_ + "/.factoria/sessions/" + as->person), ec);
            playSessionsDirty_ = true;
        });
        step(3, [this, as] {
            toasts_.clear();
            ai_attach_last_session();
            const std::string in = chat_.current().input;
            at_check(in.find("played with play.auto, not one the user played") != std::string::npos,
                     "with none of your own, the bot's session is attached and the text says whose play it was");
            at_check(in.find("fake bot problem") != std::string::npos, "...with its problems");
            at_check(!toasts_.empty() && toasts_.back().text.find("no play session of your own") != std::string::npos, "...and a toast says so");
            chat_.current().input.clear();
            std::error_code ec;
            stdfs::remove_all(stdfs::path(projectDir_ + "/.factoria/sessions/" + as->bot), ec);
            playSessionsDirty_ = true;
        });
        // ---- a real run. The script is built before anything runs, so what depends on this machine (is there a factoria next to the
        // editor?) is decided inside the steps.
        auto sessions_count = [this] {
            std::error_code ec;
            std::size_t n = 0;
            for (const auto& e : stdfs::directory_iterator(stdfs::path(projectDir_ + "/.factoria/sessions"), ec)) n += e.is_directory(ec) ? 1 : 0;
            return n;
        };
        auto wait_run_ends = [this, &step] {
            for (int i = 0; i < 2; ++i)  // two waits of at most 60 s: a loaded VM
                step(1, [this] {
                    atWaitCount_ = 0;
                    atWaitUntil_ = [this] { return !autoPlay_.running() && autoPlayLast_.has_value(); };
                });
        };
        step(3, [this, as, row_of] {
            at_check(row_of(as->bot) == nullptr, "the list follows the folder: a removed session is gone");
            as->frames0 = atFramesDrawn_;
            autoPlayLast_.reset();
        });
        click("playsessions:run");
        // A quick run (a tiny project gets stuck at once) can end between two frames: then it is neither running nor collected yet
        // (poll_auto_play takes the result on a later frame), so a finished result that waits counts as started too.
        step(1, [this, as] { as->sawRunning = autoPlay_.running() || autoPlay_.has_result() || autoPlayLast_.has_value(); });
        wait_run_ends();
        step(4, [this, as, row_of] {
            at_check(as->sawRunning, "Let the AI play starts the run at once (the button does not wait for the bot)");
            at_check(autoPlayLast_.has_value(), "the run ended");
            if (!autoPlayLast_) return;
            if (as->exe) {
                at_check(autoPlayLast_->ok, "...with a session (" + autoPlayLast_->error + " " + autoPlayLast_->hint + ")");
                at_check(atFramesDrawn_ - as->frames0 >= 5, "the window kept drawing frames while the bot played");
                as->realSession = autoPlayLast_->session;
                at_check(!as->realSession.empty() && playSessionsPick_ == as->realSession, "the finished run's session is picked in the list");
                const PlaySessionRow* r = row_of(as->realSession);
                at_check(r && r->isAuto, "...marked as the AI's");
                at_check(r && !r->ended.empty(), "...with how the run ended (" + (r ? r->ended : std::string()) + ")");
                at_check(at_shown("playsessions:ended"), "...and its report is open");
                at_check(std::any_of(toasts_.begin(), toasts_.end(), [](const Toast& t) { return t.text.find("The AI played") == 0; }),
                         "...and a toast says how it went");
            } else {
                atLog_.push_back("NOTE no factoria next to the editor and no FA_FACTORIA_EXE: the run's error path was tested instead");
                at_check(!autoPlayLast_->ok && autoPlayLast_->error.find("not found") != std::string::npos && !autoPlayLast_->hint.empty(),
                         "with no factoria tool the run says what is missing and how to fix it");
                at_check(at_shown("playsessions:error"), "...under the button");
            }
        });
        // ---- Cancel: the child is stopped and no session is written
        // The child of this run is a stand-in that only sleeps (FA_FACTORIA_EXE), so Cancel is exercised on every machine, with or
        // without a factoria next to the editor, and the run cannot end before the click.
        step(3, [this, as, sessions_count, set_env] {
            as->frames0 = sessions_count();  // sessions before the second run
            autoPlaySeconds_ = 600;
            autoPlayLast_.reset();
            as->sawRunning = false;
            if (const char* env = std::getenv("FA_FACTORIA_EXE")) {
                as->hadEnv = true;
                as->prevEnv = env;
            }
#ifdef _WIN32
            as->sleeper = projectDir_ + "/.factoria/at-sleeper.cmd";
            write_file(as->sleeper, "@echo off\r\nping -n 300 127.0.0.1 >nul\r\n");
#else
            as->sleeper = projectDir_ + "/.factoria/at-sleeper.sh";
            write_file(as->sleeper, "#!/bin/sh\nexec sleep 300\n");
            std::error_code pe;
            stdfs::permissions(stdfs::path(as->sleeper), stdfs::perms::owner_all, pe);
#endif
            set_env("FA_FACTORIA_EXE", as->sleeper);
            at_check(!auto_play_executable().empty(), "the sleeping stand-in is the factoria of this run");
        });
        click("playsessions:run");
        step(1, [this] {
            atWaitCount_ = 0;
            atWaitUntil_ = [this] { return autoPlay_.running() || autoPlayLast_.has_value(); };
        });
        step(3, [this, as] {
            as->sawRunning = autoPlay_.running();
            at_check(as->sawRunning, "the run with the sleeping stand-in is going");
            at_check(at_shown("playsessions:cancel") && at_shown("playsessions:running"), "while the bot plays the window shows its progress and Cancel");
        });
        // The first run's toast ("Open report") is drawn at the top in the middle of the window and takes clicks: on a 1024 px
        // wide screen (the macOS runner) it lies over Cancel, and a toast with a button stays while the mouse is over it.
        step(1, [this] { toasts_.clear(); });
        step(2, [this] {
            if (autoPlay_.running() && at_shown("playsessions:cancel")) inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("playsessions:cancel"));
        });
        step(2, [this] {
            if (autoPlay_.running() && at_shown("playsessions:cancel")) inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget("playsessions:cancel"));
        });
        step(4, [this] {
            if (autoPlay_.running() && at_shown("playsessions:cancel")) inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget("playsessions:cancel"));
        });
        wait_run_ends();
        step(3, [this, as, sessions_count] {
            at_check(autoPlayLast_.has_value() && autoPlayLast_->cancelled, "Cancel ends the run as cancelled");
            at_check(!autoPlay_.running(), "...the child is stopped");
            at_check(sessions_count() == as->frames0, "...and a cancelled run writes no session");
            at_check(!at_shown("playsessions:error"), "...and shows no error");
        });
        // ---- leave the editor as the other sections expect it
        step(2, [this, as, set_env] {
            reset_auto_play_state();
            if (as->hadEnv)
                set_env("FA_FACTORIA_EXE", as->prevEnv);
            else
#ifdef _WIN32
                _putenv_s("FA_FACTORIA_EXE", "");  // an empty value is "not set" for factoria_executable()
#else
                unsetenv("FA_FACTORIA_EXE");
#endif
            std::error_code ec;
            if (!as->sleeper.empty()) stdfs::remove(stdfs::path(as->sleeper), ec);
            stdfs::remove_all(stdfs::path(projectDir_ + "/.factoria/sessions"), ec);  // none of ours is left for the sections after this one
            toasts_.clear();
        });
    }
}

void Editor::at_section_R4(AtScript& at) {
    AT_SCRIPT_LOCALS(at)
    // View > Review (docs/EDITOR.md, "Review window"): a sheet of four pictures made by a command (the way the AI makes one) is offered
    // in a toast without taking the focus; its button opens the window on that sheet. The digit 3 selects number 3, the arrows move,
    // Compare shows 1 and 2 side by side, Enter and the confirmation pick it through review.pick (the other three files move to the
    // drop folder), History shows the pick, and the Level generator's "Sheet of seeds" makes a sheet of its seeds in a child factoria
    // whose pick sets that seed. Last, an AI's assets.generate_image with a count (the fake provider: offline and free) makes a sheet of
    // candidates for a slot, offered in a toast that names it; picking 2 runs assets.pick in a child factoria, which puts that candidate in
    // the slot and records it in assets.json. Waits are states; the window is the 1024x642 one of the macOS runner.
    {
        struct Rv {
            std::string sheet, seedsSheet;
            bool exe = false;
            std::string candSheet, cand2, manifestBefore;   // the sheet of asset candidates, the second candidate's bytes, assets.json
            bool hadManifest = false;
        };
        auto rv = std::make_shared<Rv>();
        auto key = [this, &step](sapp_keycode code) {
            step(2, [this, code] { inject_key(SAPP_EVENTTYPE_KEY_DOWN, code); });
            step(3, [this, code] { inject_key(SAPP_EVENTTYPE_KEY_UP, code); });
        };
        auto wait_for = [this, &step](std::function<bool()> done, int waits = 1) {
            for (int i = 0; i < waits; ++i)  // each wait ends at its condition or after the autotest's cap (60 s)
                step(1, [this, done] {
                    atWaitCount_ = 0;
                    atWaitUntil_ = done;
                });
        };
        auto sheet_ready = [this, rv] {
            return review_.sheet && review_.sheetId == rv->sheet && !review_.sheetLoading && review_.textures.count("sheet") &&
                   (review_.textures.at("sheet").tex.view || !review_.textures.at("sheet").error.empty());
        };
        step(2, [this, rv, project_file] {
            rv->exe = !factoria_executable().empty();
            std::error_code ec;   // the sheets (and candidates) of an earlier run of this temp project are not part of this one
            stdfs::remove_all(stdfs::path(project_file(".factoria/review")), ec);
            stdfs::remove_all(stdfs::path(project_file(".factoria/assets/candidates")), ec);
            stdfs::remove_all(stdfs::path(project_file("assets/at_review")), ec);
            for (int i = 1; i <= 4; ++i) {
                Image img;
                img.width = 48;
                img.height = 32;
                img.rgba.assign(48 * 32 * 4, 255);
                for (std::size_t p = 0; p < img.rgba.size(); p += 4) img.rgba[p + std::size_t(i % 3)] = std::uint8_t(60 * i);
                at_check(save_png(img, project_file("art/at_review_" + std::to_string(i) + ".png")).ok(), "a candidate picture is written");
            }
            Json items = Json::array();
            for (int i = 1; i <= 4; ++i) items.push_back(Json::object({{"image", "art/at_review_" + std::to_string(i) + ".png"}, {"label", "hero " + std::to_string(i)}}));
            // Through the queued command path, like a call of the AI or of an MCP client.
            const std::optional<CommandResult> r = run_queued("review.sheet", Json::object({{"label", "Which hero?"}, {"items", items}, {"candidates", true}}));
            at_check(r && r->ok, "review.sheet makes a sheet of the four pictures (" + (r && !r->ok ? r->error.dump() : std::string()) + ")");
            if (r && r->ok && r->result.is_object() && r->result.contains("sheet") && r->result["sheet"].is_string()) rv->sheet = r->result["sheet"].get<std::string>();
        });
        step(3, [this, rv] {
            at_check(!review_.show, "the sheet does not open a window by itself (the focus stays where it was)");
            at_check(std::any_of(toasts_.begin(), toasts_.end(), [&](const Toast& t) { return t.actionId == "review:open-announced" && t.text.find(rv->sheet) != std::string::npos; }),
                     "...a toast offers to open " + rv->sheet + " in the Review window");
        });
        click("review:open-announced");
        wait_for(sheet_ready);
        step(3, [this, rv] {
            at_check(review_.show && review_.sheetId == rv->sheet, "the toast's button opens the Review window on the sheet");
            at_check(review_.sheet && review_.sheet->items.size() == 4 && !review_.sheet->is_picked(), "...four numbers, waiting for an answer");
            at_check(review_.textures.count("sheet") && review_.textures.at("sheet").tex.view, "...the sheet's picture is on the GPU (" +
                     (review_.textures.count("sheet") ? review_.textures.at("sheet").error : std::string("no slot")) + ")");
            at_check(at_shown("review:picture") && at_shown("review:item:1") && at_shown("review:item:4") && at_shown("review:pick"),
                     "...the picture, its numbered thumbnails and the Pick button are on screen at this window size");
            at_check(at_shown("review:row:" + rv->sheet), "...and the sheet is in the list");
            at_check(review_.rows.size() == 1 && review_.rows[0].picked == 0, "...as the one sheet waiting for an answer");
        });
        // View > Review closes and opens it again on the same sheet.
        click("menu:view");
        step(3, [] {});
        click("menu:review");
        step(3, [this] { at_check(!review_.show, "View > Review closes the window"); });
        click("menu:view");
        step(3, [] {});
        click("menu:review");
        wait_for(sheet_ready);
        step(3, [this, rv] {
            at_check(review_.show && review_.sheetId == rv->sheet && review_.sheet, "...and opens it again on the same sheet");
            review_.focus = true;   // the keys below go to the window in front
            review_.selected = 0;
        });
        snap("editor_review.png");
        step(3, [this] { review_.focus = true; });
        key(SAPP_KEYCODE_3);
        step(2, [this] { at_check(review_.selected == 3, "the key 3 selects number 3 (" + std::to_string(review_.selected) + ")"); });
        key(SAPP_KEYCODE_RIGHT);
        step(2, [this] { at_check(review_.selected == 4, "the right arrow moves to 4"); });
        key(SAPP_KEYCODE_LEFT);
        step(2, [this] { at_check(review_.selected == 3, "...the left arrow back to 3"); });
        // ---- Compare 1 and 2
        click("review:tab:Compare");
        step(3, [this] { at_check(review_.tab == 1, "the Compare tab"); });
        click("review:cmp-a:1");
        click("review:cmp-b:2");
        wait_for([this] {
            auto loaded = [this](const char* k) {
                const auto it = review_.textures.find(k);
                return it != review_.textures.end() && (it->second.tex.view || !it->second.error.empty());
            };
            return loaded("src:1") && loaded("src:2");
        });
        step(3, [this] {
            at_check(review_.compareA == 1 && review_.compareB == 2, "Compare shows 1 and 2");
            at_check(review_.textures.count("src:1") && review_.textures.at("src:1").tex.w == 48, "...the candidates' own pictures, read off the UI thread");
            at_check(at_shown("review:cmp-picture-a") && at_shown("review:cmp-picture-b") && at_shown("review:cmp-title-a") && at_shown("review:cmp-title-b"),
                     "...side by side with their labels");
        });
        snap("editor_review_compare.png");
        click("review:tab:Sheet");
        step(3, [this] {
            at_check(review_.tab == 0, "back to the sheet");
            review_.focus = true;
        });
        // ---- Enter, then the confirmation
        key(SAPP_KEYCODE_ENTER);
        step(3, [this] {
            at_check(review_.confirmOpen && at_shown("review:confirm"), "Enter asks before it picks number 3");
            const ReviewPickPlan plan = review_.sheet ? review_pick_plan(*review_.sheet, review_.confirmN, true, "") : ReviewPickPlan{};
            at_check(review_.confirmN == 3 && plan.moves.size() == 3 && at_shown("review:confirm-moves"), "...and lists the three files that move to the drop folder");
            at_check(at_shown("review:keep-files") && !review_.keepFiles, "...with the option to keep them, off");
        });
        click("review:confirm");
        // The pick runs in a child factoria (never on the UI thread): the window keeps drawing and says so meanwhile.
        step(1, [this] {
            at_check(reviewPickJob_.running() || review_.pickSheet || review_.pickPending || !review_.pickMessage.empty(), "the pick starts off the UI thread");
        });
        wait_for([this] { return !reviewPickJob_.running() && !review_.pickSheet && !review_.pickPending; }, 2);
        step(3, [this, rv, project_file] {
            if (!rv->exe) {
                atLog_.push_back("NOTE no factoria next to the editor and no FA_FACTORIA_EXE: the pick's error path was tested instead");
                at_check(review_.pickBad && review_.pickMessage.find("not found") != std::string::npos, "with no factoria tool the pick says what is missing");
                return;
            }
            Result<Json> m = parse_json(read_file(project_file(".factoria/review/" + rv->sheet + "/manifest.json")), "manifest");
            const Json n = m.ok() ? json_at(m.value(), "/picked/n") : Json();
            at_check(!review_.pickBad, "the pick worked (" + review_.pickMessage + ")");
            at_check(n.is_number_integer() && n.get<int>() == 3, "...the manifest records number 3");
            std::error_code ec;
            const bool movedAway = !stdfs::exists(stdfs::path(project_file("art/at_review_1.png")), ec) &&
                                   !stdfs::exists(stdfs::path(project_file("art/at_review_2.png")), ec) &&
                                   !stdfs::exists(stdfs::path(project_file("art/at_review_4.png")), ec);
            at_check(movedAway && stdfs::exists(stdfs::path(project_file("art/at_review_3.png")), ec), "...the other three files left art/, the picked one stayed");
            std::size_t dropped = 0;
            for (const auto& e : stdfs::directory_iterator(stdfs::path(project_file(".factoria/review/dropped/" + rv->sheet)), ec)) dropped += e.is_regular_file(ec) ? 1 : 0;
            at_check(dropped == 3, "...and are in the drop folder (" + std::to_string(dropped) + ")");
            at_check(review_.pickLines.size() >= 3 && at_shown("review:pick-message"), "...the window says which files moved");
            at_check(!review_.confirmOpen, "...and the confirmation closed");
        });
        // ---- History
        click("review:tab:History");
        wait_for([this, rv] {
            return !rv->exe || std::any_of(review_.history.begin(), review_.history.end(), [&](const ReviewHistoryRow& h) { return h.id == rv->sheet; });
        });
        step(3, [this, rv] {
            if (!rv->exe) return;
            const auto h = std::find_if(review_.history.begin(), review_.history.end(), [&](const ReviewHistoryRow& r) { return r.id == rv->sheet; });
            at_check(h != review_.history.end() && h->n == 3 && !h->who.empty() && !h->at.empty(), "History shows the pick: number 3, who and when");
            at_check(h != review_.history.end() && h->dropped.size() == 3 &&
                         std::all_of(h->dropped.begin(), h->dropped.end(), [](const ReviewDroppedLine& d) { return d.status == "moved"; }),
                     "...and the three dropped files, still in the drop folder");
            at_check(at_shown("review:history:" + rv->sheet) && at_shown("review:history-open:" + rv->sheet), "...on screen, with Open");
        });
        // The sheet's id is known once the script runs: the click looks the button up then.
        for (int phase = 0; phase < 3; ++phase)
            step(phase == 2 ? 4 : 2, [this, rv, phase] {
                if (!rv->exe) return;
                const sapp_event_type type = phase == 0 ? SAPP_EVENTTYPE_MOUSE_MOVE : phase == 1 ? SAPP_EVENTTYPE_MOUSE_DOWN : SAPP_EVENTTYPE_MOUSE_UP;
                inject_mouse(type, at_widget("review:history-open:" + rv->sheet));
            });
        wait_for([this, rv] { return !rv->exe || (review_.sheet && review_.sheet->is_picked() && !review_.sheetLoading); });
        step(3, [this, rv] {
            if (!rv->exe) return;
            at_check(review_.tab == 0 && review_.sheetId == rv->sheet && review_.sheet && review_.sheet->picked_n() == 3, "Open shows the answered sheet");
            at_check(at_shown("review:pick") && !at_enabled("review:pick"), "...read-only: its Pick button is off");
        });
        // ---- the Level generator's sheet of seeds
        step(2, [this, project_file] {
            write_file(project_file("levels/at_review_sample.json"),
                       R"({"rows":["............","..####..##..","..#..#..##..","..#..#......","..####..#...","..........#.","....#.......","............"],"legend":{"#":0}})");
            showLevelGen_ = true;
            levelGenOpt_ = LevelGenOptions{};
            levelGenOpt_.sampleFile = "levels/at_review_sample.json";
            levelGenOpt_.width = 16;
            levelGenOpt_.height = 10;
            levelGenOpt_.n = 2;
            levelGenOpt_.seed = 5;
            review_.seedsCount = 3;
            focus_window("Level generator");
        });
        step(3, [this] { at_check(at_shown("levelgen:seeds-sheet") && at_enabled("levelgen:seeds-sheet"), "the Level generator has a Sheet of seeds button"); });
        click("levelgen:seeds-sheet");
        wait_for([this] { return !reviewSeedsJob_.running(); }, 4);   // a child factoria: four waits of at most 60 s on a loaded VM
        step(3, [this, rv] {
            if (!rv->exe) {
                atLog_.push_back("NOTE no factoria next to the editor and no FA_FACTORIA_EXE: the sheet of seeds' error path was tested instead");
                at_check(levelGenMessageBad_ && levelGenMessage_.find("not found") != std::string::npos, "with no factoria tool the button says what is missing");
                return;
            }
            at_check(!levelGenMessageBad_, "the sheet of seeds was made (" + levelGenMessage_ + ")");
            rv->seedsSheet = review_.sheetId;
        });
        wait_for([this, rv] { return !rv->exe || (review_.sheet && review_.sheetId != rv->sheet && !review_.sheetLoading); });
        step(3, [this, rv] {
            if (!rv->exe) return;
            at_check(review_.show && review_.sheet && review_.sheet->kind == "levelSeeds" && review_.sheet->items.size() == 3,
                     "...and opens in the Review window: three levels");
            at_check(review_.tab == 0, "...on its Sheet tab");
            rv->seedsSheet = review_.sheetId;
            review_.focus = true;
        });
        step(3, [this] { review_.focus = true; });
        key(SAPP_KEYCODE_2);
        key(SAPP_KEYCODE_ENTER);
        step(3, [this, rv] {
            if (!rv->exe) return;
            at_check(review_.selected == 2 && review_.confirmOpen, "2 and Enter ask to pick the second level");
            at_check(!at_shown("review:confirm-moves"), "...a level is no file: nothing moves");
        });
        step(2, [this, rv] {
            if (rv->exe && at_shown("review:confirm")) inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("review:confirm"));
        });
        step(2, [this, rv] {
            if (rv->exe && at_shown("review:confirm")) inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget("review:confirm"));
        });
        step(4, [this, rv] {
            if (rv->exe && at_shown("review:confirm")) inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget("review:confirm"));
        });
        wait_for([this, rv] {
            if (!rv->exe) return true;
            if (reviewPickJob_.running() || review_.pickSheet || review_.pickPending) return false;   // the pick runs in a child factoria
            return levelGen_.state() == LevelGenSession::State::Ready || levelGen_.state() == LevelGenSession::State::Failed || review_.pickBad;
        }, 2);
        step(3, [this, rv] {
            if (!rv->exe) return;
            at_check(!review_.pickBad, "the level is picked (" + review_.pickMessage + ")");
            at_check(levelGenOpt_.seed == 6 && levelGenOpt_.sampleFile == "levels/at_review_sample.json" && levelGenOpt_.width == 16,
                     "...the Level generator takes its seed (6), sample and size");
            at_check(showLevelGen_ && levelGen_.state() == LevelGenSession::State::Ready && levelGen_.preview().seed == 6,
                     "...and shows that level (" + levelGen_.error() + ")");
        });
        // ---- a sheet of asset candidates: assets.generate_image with count 2 and the offline fake provider, called through a run's proxy
        // registry as an AI calls it (an AI module command: it runs on the caller's thread, not through the queue), is offered in a toast
        // that names the slot; the window picks number 2 with assets.pick in a child factoria, which makes it the slot's file.
        step(2, [this, rv, project_file] {
            std::error_code ec;
            rv->hadManifest = stdfs::exists(stdfs::path(project_file("assets.json")), ec);
            rv->manifestBefore = rv->hadManifest ? read_file(project_file("assets.json")) : std::string();
            toasts_.clear();
            AiRun run("autotest-r4");
            auto proxy = make_proxy_registry(run);
            const CommandResult r = proxy->call("assets.generate_image", Json::object({{"prompt", "a round gem"},
                                                                                       {"path", "assets/at_review/gem.png"},
                                                                                       {"width", 16},
                                                                                       {"height", 16},
                                                                                       {"count", 2},
                                                                                       {"provider", "fake"}}));
            at_check(r.ok, "assets.generate_image with count 2 makes two candidates and a sheet (" + (r.ok ? std::string() : r.error.dump()) + ")");
            if (r.ok && r.result.is_object())
                if (const auto it = r.result.find("sheet"); it != r.result.end() && it->is_string()) rv->candSheet = it->get<std::string>();
            rv->cand2 = read_file(project_file("assets/at_review/gem.candidate-2.png"));
            at_check(!rv->candSheet.empty() && !rv->cand2.empty(), "...the second candidate's file is next to the slot");
        });
        step(3, [this, rv] {
            at_check(std::any_of(toasts_.begin(), toasts_.end(),
                                 [&](const Toast& t) {
                                     return t.actionId == "review:open-announced" && t.text.find(rv->candSheet) != std::string::npos &&
                                            t.text.find("assets/at_review/gem.png") != std::string::npos;
                                 }),
                     "...a toast offers the sheet of candidates and names the slot");
        });
        click("review:open-announced");
        // (the list too: "newest sheet of its slot" is read from the listing, which must include the sheet the toast announced)
        wait_for([this, rv] {
            return review_.sheet && review_.sheetId == rv->candSheet && !review_.sheetLoading && review_.listLoaded && !review_.listLoading &&
                   !review_.listDirty && std::any_of(review_.rows.begin(), review_.rows.end(), [&](const ReviewListRow& r) { return r.id == rv->candSheet; });
        });
        step(3, [this, rv] {
            at_check(review_.sheet && review_.sheetId == rv->candSheet && review_.sheet->kind == "assetCandidates" &&
                         review_.sheet->slot == "assets/at_review/gem.png" && review_.sheet->items.size() == 2,
                     "the toast opens the sheet of candidates: two numbers for the slot");
            at_check(review_.sheet && review_superseded_by(review_.superseded, *review_.sheet).empty(), "...the newest sheet of its slot");
            review_.focus = true;
            review_.tabSet = 0;
        });
        step(3, [this] { review_.focus = true; });
        key(SAPP_KEYCODE_2);
        key(SAPP_KEYCODE_ENTER);
        step(3, [this] {
            at_check(review_.selected == 2 && review_.confirmOpen && at_shown("review:confirm"), "2 and Enter ask to pick the second candidate");
            const ReviewPickPlan plan = review_.sheet ? review_pick_plan(*review_.sheet, 2, true, "") : ReviewPickPlan{};
            at_check(plan.command == "assets.pick", "...with assets.pick, never review.pick");
        });
        step(2, [this] {
            if (at_shown("review:confirm")) inject_mouse(SAPP_EVENTTYPE_MOUSE_MOVE, at_widget("review:confirm"));
        });
        step(2, [this] {
            if (at_shown("review:confirm")) inject_mouse(SAPP_EVENTTYPE_MOUSE_DOWN, at_widget("review:confirm"));
        });
        step(4, [this] {
            if (at_shown("review:confirm")) inject_mouse(SAPP_EVENTTYPE_MOUSE_UP, at_widget("review:confirm"));
        });
        wait_for([this] { return !reviewPickJob_.running() && !review_.pickSheet && !review_.pickPending; }, 2);
        step(3, [this, rv, project_file] {
            if (!rv->exe) {
                at_check(review_.pickBad && review_.pickMessage.find("not found") != std::string::npos, "with no factoria tool the candidate pick says what is missing");
                return;
            }
            at_check(!review_.pickBad && review_.pickMessage.find("assets/at_review/gem.png") != std::string::npos,
                     "the candidate is picked and the window names the slot (" + review_.pickMessage + ")");
            at_check(read_file(project_file("assets/at_review/gem.png")) == rv->cand2, "...the slot's file is the second candidate's picture");
            std::error_code ec;
            at_check(!stdfs::exists(stdfs::path(project_file("assets/at_review/gem.candidate-2.png")), ec), "...which moved into the slot");
            const Json m = Json::parse(read_file(project_file("assets.json")), nullptr, false);
            const auto assets = m.is_object() ? m.find("assets") : m.end();
            at_check(m.is_object() && assets != m.end() && assets->is_object() && assets->contains("assets/at_review/gem.png"),
                     "...and assets.json records the slot");
        });
        // ---- leave the editor as the other sections expect it
        step(2, [this, rv, project_file] {
            reset_review_state();
            showLevelGen_ = false;
            levelGen_.clear(level_gen_caller());
            std::error_code ec;
            stdfs::remove_all(stdfs::path(project_file(".factoria/review")), ec);
            for (int i = 1; i <= 4; ++i) stdfs::remove(stdfs::path(project_file("art/at_review_" + std::to_string(i) + ".png")), ec);
            stdfs::remove(stdfs::path(project_file("levels/at_review_sample.json")), ec);
            stdfs::remove_all(stdfs::path(project_file("assets/at_review")), ec);
            stdfs::remove_all(stdfs::path(project_file(".factoria/assets/candidates")), ec);
            if (rv->hadManifest) write_file(project_file("assets.json"), rv->manifestBefore);
            else stdfs::remove(stdfs::path(project_file("assets.json")), ec);
            toasts_.clear();
        });
    }
}

}  // namespace fa::editor
