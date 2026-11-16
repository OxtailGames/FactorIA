// The rule for the names inside an example's zip, shared by the packer (project.package_examples: never write a zip that no reader
// accepts) and the unpacker (extract_example_zip: never write a name that could leave the project or collide on Windows and macOS).
// Private to fa_tooling.
#pragma once

#include <optional>
#include <string>
#include <vector>

namespace fa {

struct ExampleEntryName {
    std::string name;       // as stored in the zip: forward slashes, a folder ends in '/'
    bool directory = false;
};

struct ExampleEntryProblem {
    std::string name;    // the entry that cannot be used
    std::string reason;  // "it goes up a folder (\"..\")": what is wrong, as a phrase after "because"
};

// The first entry whose name cannot be unpacked safely, or nullopt. Checks every name alone (empty, longer than 240 bytes, not UTF-8,
// control characters, '\\', a leading '/', ':', characters Windows does not allow, empty / "." / ".." parts, a part that ends in a dot or
// a space, Windows device names) and the names together: the same name twice, two names that differ only in capitals (ASCII and Latin-1
// letters are folded; other scripts' capitals and Unicode normalisation are not), a name that is both a file and a folder.
std::optional<ExampleEntryProblem> find_unsafe_example_entry(const std::vector<ExampleEntryName>& entries);

}  // namespace fa
