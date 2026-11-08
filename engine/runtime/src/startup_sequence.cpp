#include "fa/runtime/startup_sequence.h"

namespace fa {

bool StartupSequence::on_frame() {
    switch (state_) {
        case State::FirstFrame:
            if (timeline_) timeline_->mark(StartupTimeline::Mark::WindowReady);
            if (hooks_.present_clear) hooks_.present_clear();
            if (timeline_) timeline_->mark(StartupTimeline::Mark::FirstPresent);
            state_ = State::Init;
            return false;
        case State::Init:
            if (hooks_.init && !hooks_.init()) {
                state_ = State::Failed;
                return false;
            }
            if (hooks_.present_clear) hooks_.present_clear();
            state_ = State::Warm;
            return false;
        case State::Warm: {
            const int left = hooks_.warm ? hooks_.warm() : 0;
            if (hooks_.present_clear) hooks_.present_clear();
            if (left <= 0) state_ = State::Running;
            return false;
        }
        case State::Running: return true;
        case State::Failed: return false;
    }
    return false;
}

}  // namespace fa
