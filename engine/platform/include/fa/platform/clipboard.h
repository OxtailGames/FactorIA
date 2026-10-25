// The clipboard, as scripts (`clipboard.*`) and the UI (a TextField's Ctrl+V / Ctrl+C) reach it. The Engine owns one
// (Engine::clipboard()): a game with a window gets the system clipboard, headless runs, tests, replays and the editor's
// game view get an in-memory one, so they behave the same on every machine.
#pragma once

#include <string>

namespace fa {

class Clipboard {
public:
    virtual ~Clipboard() = default;
    // false: this platform has no clipboard for games (phones and tablets). get() then answers "" and set() does nothing.
    virtual bool supported() const = 0;
    // The text now on the clipboard ("" when it holds none or something that is not text). On the web the browser lets a
    // page read only inside a paste, so this is the text of the last paste.
    virtual std::string get() = 0;
    virtual void set(const std::string& text) = 0;
};

// A clipboard that lives in this object only.
class MemoryClipboard final : public Clipboard {
public:
    bool supported() const override { return true; }
    std::string get() override { return text_; }
    void set(const std::string& text) override { text_ = text; }

private:
    std::string text_;
};

// The system clipboard through the app window (app_clipboard_get / app_clipboard_set in fa/platform/app.h). Only valid in
// a process that runs an app window; supported() is false on mobile.
Clipboard& system_clipboard();

}  // namespace fa
