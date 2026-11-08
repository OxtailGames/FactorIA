// Platform hooks of the job system (jobs.cpp). jobs_thread_posix.cpp and jobs_thread_win32.cpp implement them.
#pragma once

namespace fa::jobs::detail {
// Names the calling thread for debuggers, profilers and crash reports ("fa-job-1"). ASCII, at most 15 characters
// (Linux's limit). Does nothing where the platform has no thread names (web).
void set_current_thread_name(const char* name);
}  // namespace fa::jobs::detail
