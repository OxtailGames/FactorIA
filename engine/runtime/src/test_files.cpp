// resolve_test_files (fa/runtime/test_files.h).
#include "fa/runtime/test_files.h"

#include <algorithm>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

std::vector<std::string> all_test_files() {
    std::vector<std::string> out;
    for (const std::string& f : fs::list("tests", true, ".js"))
        if (ends_with(f, ".test.js")) out.push_back(f);
    std::sort(out.begin(), out.end());
    return out;
}

}  // namespace

Result<std::vector<std::string>> resolve_test_files(const std::vector<std::string>& args) {
    const std::vector<std::string> known = all_test_files();
    if (args.empty()) return known;
    const std::string list = known.empty() ? "This project has no tests/**/*.test.js yet." : "Test files: " + join(known, ", ") + ".";
    std::set<std::string> out;
    for (const std::string& raw : args) {
        std::string arg = raw;
        std::replace(arg.begin(), arg.end(), '\\', '/');
        while (arg.rfind("./", 0) == 0) arg.erase(0, 2);
        const std::string shown = "'" + raw + "'";
        if (arg.empty())
            return Error{"An empty test file name was given.",
                         "Pass test files such as tests/saves.test.js, a folder or a glob like \"tests/ui*.test.js\"."};
        if (arg.find_first_of("*?") != std::string::npos) {
            const std::size_t before = out.size();
            for (const std::string& f : known)
                if (glob_match(arg, f)) out.insert(f);
            if (out.size() == before)
                return Error{"The pattern " + shown + " matches no test file.",
                             list + " A pattern is project-relative; * stays inside a folder, ** crosses folders."};
            continue;
        }
        auto norm = fs::normalize_checked(arg);
        if (!norm) return Error{"The test path " + shown + " is outside the project.", norm.error().to_string()};
        arg = *norm;
        if (fs::is_directory(arg)) {
            const std::size_t before = out.size();
            for (const std::string& f : fs::list(arg, true, ".js"))
                if (ends_with(f, ".test.js")) out.insert(f);
            if (out.size() == before)
                return Error{"The folder " + shown + " has no *.test.js file.", "Test files end in .test.js, for example tests/saves.test.js."};
            continue;
        }
        if (!ends_with(arg, ".test.js"))
            return Error{shown + " is not a test file: test files end in .test.js.",
                         "Pass a test file such as tests/saves.test.js, a folder or a glob like \"tests/ui*.test.js\". " + list};
        if (!fs::exists(arg)) {
            const std::string near = did_you_mean(arg, known);
            return Error{"Test file " + shown + " does not exist.", (near.empty() ? std::string() : near + " ") + list};
        }
        out.insert(arg);
    }
    return std::vector<std::string>(out.begin(), out.end());
}

}  // namespace fa
