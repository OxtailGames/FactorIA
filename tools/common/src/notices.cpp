#include "fa/tooling/notices.h"

#include "fa/tooling/bundle.h"

namespace fa {

std::string third_party_notices(NoticeScope scope) {
    const std::string rule(78, '-');
    std::string out;
    out += "FactorIA " FA_ENGINE_VERSION " - license notices\n\n";
    out += scope == NoticeScope::Game
               ? "This game was made with FactorIA and contains its runtime. The runtime is FactorIA (MIT License) plus the\n"
                 "third-party software below; each part is used under the license that follows it.\n"
               : "The FactorIA engine and tools are FactorIA (MIT License) plus the third-party software below; each part is\n"
                 "used under the license that follows it. Games made with FactorIA ship the parts marked \"in games\".\n";
    for (const ThirdPartyComponent& c : third_party_components()) {
        if (scope == NoticeScope::Game && !c.inGames) continue;
        out += "\n" + rule + "\n" + c.name + " (" + c.usedFor + (scope == NoticeScope::All && c.inGames ? "; in games" : "") +
               ")\n" + c.url + "\nLicense: " + c.license + "\n\n";
        std::string text = bundled_read(c.licenseFile).value_or("");
        if (text.empty()) text = "[license text missing from this build: " + c.licenseFile + " in the FactorIA repository]";
        // Apache-2.0 section 4(d): a library that keeps a NOTICE file beside its LICENSE has that text reproduced too.
        if (auto notice = bundled_read(c.licenseFile.substr(0, c.licenseFile.rfind('/') + 1) + "NOTICE")) text += "\n\n" + *notice;
        while (!text.empty() && (text.back() == '\n' || text.back() == '\r' || text.back() == ' ')) text.pop_back();
        out += text + "\n";
    }
    return out;
}

}  // namespace fa
