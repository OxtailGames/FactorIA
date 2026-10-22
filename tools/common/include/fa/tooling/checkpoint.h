// Project checkpoints: snapshots of every file of a project, so a run of an AI (which edits scripts, tests and assets
// directly) can be taken back as a whole. Stored in <project>/.factoria/checkpoints/:
//   objects/<2 hex>/<sha256>   the content of each distinct file, once (a later checkpoint only copies what changed)
//   <id>.json                  one manifest per checkpoint: id, label, created, files: path -> {hash, size}
//   stat-cache.json            path -> {size, mtime, hash}: an unchanged file is not read again
// Every file of the project is included (assets too) except the folders the other project walks skip: folders starting
// with '.', node_modules and a top-level build/. The newest kCheckpointLimit checkpoints are kept; objects no manifest
// uses are deleted. Commands: checkpoint.create, checkpoint.list, checkpoint.diff, checkpoint.restore.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/types.h"

namespace fa {

// How many checkpoints are kept; creating one beyond that deletes the oldest.
inline constexpr int kCheckpointLimit = 30;

struct CheckpointInfo {
    std::string id;            // "20261022-153012-7": UTC time and a sequence number, never reused
    std::string label;
    std::int64_t created = 0;  // epoch seconds
    int files = 0;
    std::uint64_t bytes = 0;   // total size of the files it holds (not what it adds on disk)
};

struct CheckpointCreated {
    CheckpointInfo info;
    std::uint64_t bytesStored = 0;  // bytes newly copied into objects/ (0 when nothing changed since the last one)
    int filesHashed = 0;            // files that had to be read (the others were found unchanged by size and mtime)
};

// What differs between a checkpoint and the files now (project-relative paths, forward slashes, sorted).
struct CheckpointDiff {
    std::vector<std::string> modified;  // in both, content differs
    std::vector<std::string> added;     // exist now, not in the checkpoint
    std::vector<std::string> deleted;   // in the checkpoint, gone now
    bool empty() const { return modified.empty() && added.empty() && deleted.empty(); }
};

struct CheckpointRestored {
    CheckpointDiff changes;  // what restore did: modified/deleted files written back, added files deleted
    std::string safetyId;    // the automatic "Before restoring <label>" checkpoint: restoring it takes this back
};

Result<CheckpointCreated> checkpoint_create(const std::string& projectDir, const std::string& label);
std::vector<CheckpointInfo> checkpoint_list(const std::string& projectDir);  // newest first
Result<CheckpointDiff> checkpoint_diff(const std::string& projectDir, const std::string& id);
Result<CheckpointRestored> checkpoint_restore(const std::string& projectDir, const std::string& id);

// checkpoint.{create,list,diff,restore}
void register_checkpoint_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
