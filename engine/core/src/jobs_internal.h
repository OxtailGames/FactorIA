// Platform hooks of the job system (jobs.cpp). jobs_thread_posix.cpp and jobs_thread_win32.cpp implement them.
#pragma once

#include <cstddef>
#include <cstdint>

namespace fa::jobs::detail {
// Names the calling thread for debuggers, profilers and crash reports ("fa-job-1"). ASCII, at most 15 characters
// (Linux's limit). Does nothing where the platform has no thread names (web).
void set_current_thread_name(const char* name);
// How many entries sit in the ready queues now, taken ones included (an entry outlives the job it queued until someone
// pops it or its wait drops it). For tests: it takes every queue's lock.
std::size_t queued_entries();
// How many times in a row a worker looks again, when it is told a job is queued and finds none, before it naps (64 by
// default), and how many naps there have been. For tests.
void set_spins_before_nap(int n);
std::uint64_t naps();
}  // namespace fa::jobs::detail
