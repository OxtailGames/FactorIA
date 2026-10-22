#include "autotest_sections.h"

#include <cctype>
#include <vector>

#include "fa/core/strings.h"

namespace fa::editor {

Result<std::set<std::string>> parse_autotest_sections(std::string_view text) {
    std::vector<std::string> ids;
    std::string list;
    for (const AutotestSection& s : kAutotestSections) {
        ids.emplace_back(s.id);
        list += std::string("\n  ") + s.id + "  " + s.title;
    }
    const std::string hint = "name sections by their letter, e.g. FA_EDITOR_AUTOTEST=1 FA_EDITOR_AUTOTEST_SECTIONS=K,M. The sections:" + list;
    std::set<std::string> picked;
    std::string word;
    auto take = [&]() -> Result<void> {
        if (word.empty()) return {};
        for (char& c : word) c = char(std::toupper(static_cast<unsigned char>(c)));
        bool known = false;
        for (const std::string& id : ids) known = known || id == word;
        if (!known)
            return make_error("FA_EDITOR_AUTOTEST_SECTIONS: there is no autotest section '" + word + "'. " +
                                  did_you_mean(word, ids, ids.size()),
                              hint);
        picked.insert(word);
        word.clear();
        return {};
    };
    for (char c : text) {
        if (c == ',' || std::isspace(static_cast<unsigned char>(c))) {
            if (auto r = take(); !r) return r.error();
        } else {
            word += c;
        }
    }
    if (auto r = take(); !r) return r.error();
    if (picked.empty()) return make_error("FA_EDITOR_AUTOTEST_SECTIONS names no section ('" + std::string(text) + "')", hint);
    return picked;
}

}  // namespace fa::editor
