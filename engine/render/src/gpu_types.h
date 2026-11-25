// Private: the vocabulary the renderer's GPU code shares. TargetFormat (what a render pass writes into: the key of the
// pipelines made for a pass) and PassDesc (one render pass as data: where it draws, what it does with the old contents
// and how it ends) live in gpu/types.h with the rest of the interface; this header only names them in fa::render, so the
// renderer's code keeps writing `TargetFormat` and `PassDesc`. Every pass builds one and begins it on a
// gpu::CommandList (begin_pass).
#pragma once

#include "gpu/types.h"

namespace fa::render {

using gpu::PassDesc;
using gpu::TargetFormat;

}  // namespace fa::render
