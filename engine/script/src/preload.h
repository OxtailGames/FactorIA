// Reading a scene's files ahead of time (scene.preload, assets.preload; docs/SCRIPTING.md "Preloading").
//
// A job reads the files a scene or a list of assets needs into the file system's warm set (fs::warm), a bit every frame,
// so the later scene.load (and the renderer, on the first draw) find the bytes in memory. The work is cut in UNITS, one
// file each: unit 1 reads the scene (or the first assets) and finds everything it points at (prefabs, materials, the
// buffers and textures of .gltf models), then one unit per file. How many units run in a frame is the budget:
//   fixed  (tests, headless runs, replays): exactly kFixedUnitsPerFrame units per frame, so a run gives the same result on
//          any machine (a level of 20 files is read in 6 frames);
//   timed  (a game with a window): units run until `budgetMs` milliseconds have passed, at least one.
// A worker thread can replace tick() later without changing the handle scripts see.
#pragma once

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "fa/core/json.h"

namespace fa {

class Preloader {
public:
    static constexpr int kFixedUnitsPerFrame = 4;

    struct Update {
        int id = 0;
        int done = 0;   // units finished
        int total = 0;  // units in the job
        std::uint64_t bytes = 0;
        bool finished = false;
        std::string error;  // set when the job failed
        std::string hint;
    };

    // The scene file `path` and everything it uses. The error (a missing file, with "did you mean") is for the caller to throw.
    Result<int> start_scene(const std::string& path);
    // The given files; .gltf models bring their buffers and textures along, .prefab.json and .material.json their files.
    Result<int> start_assets(const std::vector<std::string>& paths);
    // Stops the job and gives its unread files back. False when the id is unknown.
    bool release(int id);
    // A scene was loaded (called after its behaviours exist). The files of a finished job stay in memory through the first
    // load after it finished (the load it was for, and anything the scene reads while it plays) and are dropped at the
    // second, or by release(). Memory use is therefore bounded: about one scene's files beyond the one in use.
    void scene_loaded();
    // Forgets every job and every warm file (a test file starts).
    void reset();
    // Runs the budget's units and returns the jobs that changed. budgetMs <= 0: the fixed budget.
    std::vector<Update> tick(double budgetMs);
    bool active() const { return !jobs_.empty(); }

private:
    struct Job {
        int id = 0;
        std::vector<std::string> roots;  // what the job was asked for
        bool isScene = false;
        bool scanned = false;
        std::vector<std::string> queue;  // files still to read, in order
        std::size_t next = 0;
        int done = 0;
        int total = 1;  // the scan counts as a unit
        std::uint64_t bytes = 0;
        std::vector<std::string> warmed;  // every file this job warmed
        std::string error, hint;
    };
    // One unit of `job`; false when the job has nothing left.
    bool run_unit(Job& job);
    void scan(Job& job);
    std::vector<Job> jobs_;
    struct Kept {
        std::vector<std::string> files;
        int loads = 0;  // scene loads since the job finished
    };
    std::map<int, Kept> kept_;  // finished jobs: the files they warmed
    int nextId_ = 1;
};

}  // namespace fa
