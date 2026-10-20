// Windows: SAPI 5 (ISpVoice), asynchronous. The voice is picked by the language of the line: a voice token whose
// "Language" attribute lists the language's LCID (the full tag first, then the primary language); none = the default voice.
// The GUIDs are written out so that this file needs neither sapi.lib nor __uuidof support.
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <objbase.h>
#include <sapi.h>

#include <cstdio>
#include <string>

#include "fa/platform/speech.h"

namespace fa {

namespace {

const GUID kClsidSpVoice = {0x96749377, 0x3391, 0x11D2, {0x9E, 0xE3, 0x00, 0xC0, 0x4F, 0x79, 0x73, 0x96}};
const GUID kIidSpVoice = {0x6C44DF74, 0x72B9, 0x4992, {0xA1, 0xEC, 0xEF, 0x99, 0x6E, 0x04, 0x22, 0xD4}};
const GUID kClsidSpObjectTokenCategory = {0xA910187F, 0x0C7A, 0x45AC, {0x92, 0xCC, 0x59, 0xED, 0xAF, 0xB7, 0x7B, 0x53}};
const GUID kIidSpObjectTokenCategory = {0x2D3D3845, 0x39AF, 0x4850, {0xBB, 0xF9, 0x40, 0xB4, 0x97, 0x80, 0x01, 0x1D}};

std::wstring widen(std::string_view s) {
    if (s.empty()) return {};
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring w(static_cast<std::size_t>(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), w.data(), n);
    return w;
}

class SapiBackend final : public SpeechBackend {
public:
    SapiBackend() {
        // sokol_app may have initialised COM already (any mode is fine for ISpVoice's free-threaded proxy).
        HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
        ownsCom_ = SUCCEEDED(hr);  // S_FALSE (already initialised, same mode) also needs the matching CoUninitialize
        if (SUCCEEDED(hr) || hr == RPC_E_CHANGED_MODE)
            CoCreateInstance(kClsidSpVoice, nullptr, CLSCTX_ALL, kIidSpVoice, reinterpret_cast<void**>(&voice_));
    }
    ~SapiBackend() override {
        if (voice_) {
            voice_->Speak(nullptr, SPF_PURGEBEFORESPEAK, nullptr);
            voice_->Release();
        }
        if (token_) token_->Release();
        if (ownsCom_) CoUninitialize();
    }

    bool available() override { return voice_ != nullptr; }

    void speak(std::string_view text, std::string_view language, bool interrupt) override {
        if (!voice_) return;
        if (language != lastLanguage_) {
            lastLanguage_ = std::string(language);
            choose_voice(lastLanguage_);
        }
        const std::wstring w = widen(text);
        DWORD flags = SPF_ASYNC | SPF_IS_NOT_XML | (interrupt ? SPF_PURGEBEFORESPEAK : 0);
        voice_->Speak(w.c_str(), flags, nullptr);
    }

    void stop() override {
        if (voice_) voice_->Speak(nullptr, SPF_PURGEBEFORESPEAK, nullptr);
    }

private:
    // The first voice whose Language attribute has the LCID of `tag`, else of its primary language; else leave the default.
    void choose_voice(const std::string& tag) {
        if (tag.empty()) return;
        std::string primary = tag.substr(0, tag.find('-'));
        for (const std::string& candidate : {tag, primary}) {
            if (ISpObjectToken* found = find_voice(candidate)) {
                if (token_) token_->Release();
                token_ = found;
                voice_->SetVoice(token_);
                return;
            }
            if (candidate == primary) break;
        }
    }

    ISpObjectToken* find_voice(const std::string& tag) {
        if (tag.empty() || tag.size() >= LOCALE_NAME_MAX_LENGTH) return nullptr;
        const std::wstring name = widen(tag);
        LCID lcid = LocaleNameToLCID(name.c_str(), 0);
        if (lcid == 0) return nullptr;
        ISpObjectTokenCategory* category = nullptr;
        if (FAILED(CoCreateInstance(kClsidSpObjectTokenCategory, nullptr, CLSCTX_ALL, kIidSpObjectTokenCategory,
                                    reinterpret_cast<void**>(&category))) || !category)
            return nullptr;
        ISpObjectToken* result = nullptr;
        if (SUCCEEDED(category->SetId(SPCAT_VOICES, FALSE))) {
            wchar_t req[64];
            std::swprintf(req, 64, L"Language=%X", static_cast<unsigned>(lcid));
            IEnumSpObjectTokens* tokens = nullptr;
            if (SUCCEEDED(category->EnumTokens(req, nullptr, &tokens)) && tokens) {
                ULONG fetched = 0;
                ISpObjectToken* t = nullptr;
                if (tokens->Next(1, &t, &fetched) == S_OK && fetched == 1) result = t;
                tokens->Release();
            }
        }
        category->Release();
        return result;
    }

    ISpVoice* voice_ = nullptr;
    ISpObjectToken* token_ = nullptr;
    std::string lastLanguage_;
    bool ownsCom_ = false;
};

}  // namespace

std::unique_ptr<SpeechBackend> make_system_speech_backend() { return std::make_unique<SapiBackend>(); }

}  // namespace fa
