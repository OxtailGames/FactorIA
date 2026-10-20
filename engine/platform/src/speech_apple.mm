// macOS and iOS: AVSpeechSynthesizer (AVFoundation). The voice is the system's voice for the language ("es", "pt-BR");
// none for it = the default voice. Utterances queue by themselves; interrupt stops the speech at once first.
// UNTESTED here: only compiled by CI (macOS and iOS jobs).
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

#include "fa/platform/speech.h"

namespace fa {

namespace {

class AvSpeechBackend final : public SpeechBackend {
public:
    AvSpeechBackend() { synthesizer_ = [[AVSpeechSynthesizer alloc] init]; }

    bool available() override { return synthesizer_ != nil; }

    void speak(std::string_view text, std::string_view language, bool interrupt) override {
        if (!synthesizer_) return;
        NSString* string = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
        if (!string) return;
        if (interrupt && synthesizer_.speaking) [synthesizer_ stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        AVSpeechUtterance* utterance = [AVSpeechUtterance speechUtteranceWithString:string];
        if (!language.empty()) {
            NSString* tag = [[NSString alloc] initWithBytes:language.data() length:language.size() encoding:NSUTF8StringEncoding];
            AVSpeechSynthesisVoice* voice = tag ? [AVSpeechSynthesisVoice voiceWithLanguage:tag] : nil;
            if (!voice && tag) {  // "es" is not a voice tag everywhere: look for any voice of that primary language
                NSString* primary = [tag componentsSeparatedByString:@"-"].firstObject;
                for (AVSpeechSynthesisVoice* candidate in [AVSpeechSynthesisVoice speechVoices]) {
                    if ([candidate.language hasPrefix:primary]) {
                        voice = candidate;
                        break;
                    }
                }
            }
            if (voice) utterance.voice = voice;
        }
        [synthesizer_ speakUtterance:utterance];
    }

    void stop() override {
        if (synthesizer_) [synthesizer_ stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }

private:
    AVSpeechSynthesizer* synthesizer_ = nil;
};

}  // namespace

std::unique_ptr<SpeechBackend> make_system_speech_backend() { return std::make_unique<AvSpeechBackend>(); }

}  // namespace fa
