// Files that hold a secret (API keys in ai.json, a signing keystore, the feedback admin token): readable by their owner only.
//
// POSIX (Linux, macOS, ...): mode 0600, set when the file is created. Windows: an explicit protected DACL with one entry, full
// control for the current user, set when the file is created; it does not inherit the entries of the folder, so a folder that
// is open to other users or groups does not open the file. SYSTEM and the administrators are not listed: they can still take
// ownership of the file (or read it as backup operators), as they can of any file; the entry keeps out every other account and
// every group. Separate from fs.h: these are plain OS paths, not project-relative ones.
#pragma once

#include <string_view>

#include "fa/core/types.h"

namespace fa::fs {

// Writes `bytes` to `path` (parent folders are created) so that no other user can read them at any moment: a temporary file
// next to the target is created private BEFORE the bytes go in, then it replaces the target atomically (a reader never sees a
// half-written file, a failure leaves the old file). The result keeps the privacy even when the target existed with wider
// permissions. A symlinked `path` is written through (the link stays, the file it points to is replaced). Two writers (threads
// or processes) never share a temporary file. On Windows a target that another program holds open can refuse the replace; it
// is retried for about a second (fs::replace_file), then reported.
Result<void> write_private(std::string_view path, std::string_view bytes);

// Makes an existing FILE readable by its owner only (0600 / the protected DACL above), for a file a tool created with the
// default permissions (keytool's keystore). An Error when the OS refuses. Between the tool creating the file and this call the
// file has the default permissions: prefer write_private when you write the bytes yourself.
Result<void> make_private(std::string_view path);

}  // namespace fa::fs
