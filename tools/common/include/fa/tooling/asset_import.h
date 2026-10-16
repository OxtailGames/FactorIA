// Importing files into a project: the commands assets.import and assets.slice_sheet (docs/ASSETS.md, "Importing files").
//
//   assets.import      brings a file made elsewhere into assets/ and records where it came from in assets.json:
//                      png/jpg/tga/bmp, wav/ogg/mp3, ttf/otf and glTF are copied; Aseprite and PSD become a PNG (an
//                      Aseprite file a sprite sheet with its clips); OBJ becomes a glTF; FBX is converted to glb by
//                      FBX2glTF or Blender.
//   assets.slice_sheet makes an image playable by SpriteAnimator: checks a uniform grid, or finds the frames of a
//                      sheet with transparent gutters and repacks them into a uniform grid.
#pragma once

#include <string>

#include "fa/core/command.h"

namespace fa {

// Registers assets.import and assets.slice_sheet for the project at `projectDir`.
void register_asset_commands(CommandRegistry& registry, const std::string& projectDir);

// The programs that convert an FBX file. An empty path means "not installed". Only tests change them; by default
// assets.import looks at this machine: $FACTORIA_FBX2GLTF, else FBX2glTF in PATH, and Blender in PATH or in its
// standard install folders.
struct FbxConverters {
    std::string fbx2gltf;
    std::string blender;
};
FbxConverters find_fbx_converters();
// Replaces what assets.import uses for FBX files until the next call; nullptr goes back to find_fbx_converters().
void set_fbx_converters(const FbxConverters* converters);

}  // namespace fa
