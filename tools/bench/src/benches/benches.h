// The benchmarks of `fa_bench`, one function per group; main.cpp collects them. Every benchmark builds its scene from a fixed seed
// (fa::Rng), so two runs do the same work and the numbers move only with the code and the machine.
#pragma once

#include <vector>

#include "bench.h"

namespace fa::bench {

void add_ecs_benches(std::vector<Bench>& out);        // World::each, entities_with, spawn and destroy
void add_hierarchy_benches(std::vector<Bench>& out);  // World::world_matrix over a deep and a wide tree
void add_physics_benches(std::vector<Bench>& out);    // Physics::step in 2D and in 3D
void add_render_benches(std::vector<Bench>& out);     // a frame of the headless renderer: 2D sprites and 3D meshes
void release_render_env();                            // main() calls it before it ends: the GPU context closes in order
void add_command_benches(std::vector<Bench>& out);    // CommandRegistry::call
void add_script_benches(std::vector<Bench>& out);     // JS -> C++ calls, component access, behaviours
void add_audio_benches(std::vector<Bench>& out);      // the software mixer, offline
void add_jobs_benches(std::vector<Bench>& out);       // the job system: tiny jobs, parallel_for, graphs, nested waits

}  // namespace fa::bench
