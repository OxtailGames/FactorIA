// Gives a Windows executable the game's icon and version information without a Windows toolchain: the export of
// `factoria_player.exe` (docs/EXPORTING.md, "Desktop").
//
// factoria_player.exe is built with a placeholder icon (player/windows/factoria_player.rc): an ICON resource made only of
// uncompressed 32-bit BMP images of fixed sizes (16, 24, 32, 48, 64, 128, 256 px). patch_pe_icon() overwrites each of
// those RT_ICON images IN PLACE with the game icon rendered at the same size (icon_bmp_entry, fa/tooling/icons.h): an
// image of a given size always has the same byte length, so no section, resource directory, or header has to move, and
// it works from any host OS (an export for Windows made on a Mac or on Linux). The bytes of the file changed, so:
//   - the Authenticode signature (the certificate table, data directory 4) no longer matches and is removed: the
//     directory entry is cleared and, when the table ended the file (it always does), the file is truncated there;
//   - the checksum in the optional header is computed again (Windows checks it for drivers and services only, but a
//     wrong one is a defect).
// The PE structure it reads: DOS header -> PE headers -> section table -> the resource directory (data directory 2),
// whose tree is type -> name -> language -> data entry; the RT_ICON type is 3.
//
// The version information works the same way: the player's VERSIONINFO resource (RT_VERSION, 16) holds strings padded
// with spaces, and patch_pe_version() overwrites each value in place, padded with NULs, so nothing moves either.
#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/types.h"

namespace fa {

struct PeIconPatch {
    int replaced = 0;               // RT_ICON images overwritten with the game icon
    std::vector<int> sizes;         // their sizes in pixels, in the order found
    int skipped = 0;                // RT_ICON images left as they were: PNG-compressed, not 32-bit, or of an unexpected length
    bool signatureRemoved = false;  // the file carried an Authenticode signature and it was removed
    bool truncated = false;         // ... and its bytes were cut off the end of the file
};

// Replaces the icon of the PE image `exe` (the bytes of an .exe or .dll, 32 or 64 bit) with `icon`. A 32-bit BMP RT_ICON
// image of any square size from 1 to 256 px is replaced by the icon rendered at that size; PNG images and the others
// are left alone (`skipped`). When no image was replaced (a player without the placeholder icon, or without resources)
// `exe` is NOT touched at all, signature and checksum included, and the result says replaced == 0. An Error (with what
// is wrong and a hint) means `exe` is not a PE file or its resource table is damaged; `exe` is unchanged then too.
Result<PeIconPatch> patch_pe_icon(std::vector<std::uint8_t>& exe, const Image& icon);

struct PeVersionInfo {
    std::map<std::string, std::string> strings;  // StringFileInfo key -> value (UTF-8): {"ProductName", "Space Dodge"}
    std::string version;                         // "1.2.3": the FILEVERSION and PRODUCTVERSION numbers; "" = unchanged
};

struct PeVersionPatch {
    bool found = false;                  // the file has a VS_VERSIONINFO resource (false: nothing was changed)
    std::vector<std::string> truncated;  // keys of `strings` whose value was cut to the room of the placeholder
    bool signatureRemoved = false;       // as in PeIconPatch
};

// Writes `info` into the version information of the PE image `exe`: each string of `info.strings` whose key the resource
// has (keys it lacks are skipped), and the version numbers. A file without a well-formed VS_VERSIONINFO is NOT touched
// (found == false). Like patch_pe_icon, a change removes the signature and recomputes the checksum; an Error means `exe`
// is not a PE file or its resource table is damaged, and `exe` is unchanged.
Result<PeVersionPatch> patch_pe_version(std::vector<std::uint8_t>& exe, const PeVersionInfo& info);

// The PE checksum of `bytes`: the sum of its 16-bit words (the 4 bytes at `checksumOffset` counted as zero) with the
// carries folded back in, plus the length of the file. checksumOffset is the file offset of the CheckSum field
// (the optional header + 64).
std::uint32_t pe_checksum(const std::vector<std::uint8_t>& bytes, std::size_t checksumOffset);

}  // namespace fa
