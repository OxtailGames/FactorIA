#include "fa/scene/captions.h"

#include <algorithm>
#include <optional>

#include "fa/core/log.h"
#include "fa/scene/components.h"

namespace fa {

void CaptionList::translate(CaptionLine& l, const I18n& i18n) {
    if (l.key.empty()) return;
    if (std::optional<std::string> t = i18n.translate(l.key)) {
        l.text = std::move(*t);
    } else {
        const std::string hint = i18n.enabled()
            ? "add the key to locales/" + i18n.default_language() + ".json"
            : std::string("factoria.json has no \"localization\" section, so nothing is translated: add one (docs/LOCALIZATION.md)");
        i18n.warn_once("caption|" + l.key, "The caption key '" + l.key + "' is in no string table, so the caption shows its own text \"" +
                                               l.text + "\" (hint: " + hint + ")");
    }
}

void CaptionList::add(CaptionLine line, const I18n* i18n) {
    if (i18n) translate(line, *i18n);
    lines_.push_back(std::move(line));
    if (lines_.size() > kMaxLines) lines_.erase(lines_.begin());
}

void CaptionList::remove_voice(std::uint32_t voice) {
    if (voice == 0) return;
    std::erase_if(lines_, [&](const CaptionLine& l) { return l.voice == voice; });
}

void CaptionList::remove_all_voices() {
    std::erase_if(lines_, [](const CaptionLine& l) { return l.voice != 0; });
}

bool CaptionList::update(World& world, const I18n& i18n, const std::function<bool(std::uint32_t)>& voicePlaying) {
    const double now = world.time();
    std::erase_if(lines_, [&](const CaptionLine& l) {
        if (l.endsAt >= 0.0) return now >= l.endsAt;
        return l.voice != 0 && !voicePlaying(l.voice);
    });
    for (CaptionLine& l : lines_) translate(l, i18n);
    bool any = false, changed = false;
    world.each<Captions>([&](Entity, Captions& c) {
        any = true;
        const std::size_t maxLines = static_cast<std::size_t>(std::max(1, c.maxLines));
        Json out = Json::array();
        for (std::size_t i = lines_.size() > maxLines ? lines_.size() - maxLines : 0; i < lines_.size(); ++i)
            out.push_back(Json::object({{"text", lines_[i].text}, {"speaker", lines_[i].speaker}}));
        if (out != c.lines) {
            c.lines = std::move(out);
            changed = true;
        }
    });
    if (!any && !lines_.empty() && !hinted_) {
        hinted_ = true;
        FA_INFO("captions",
                "A caption was shown (\"{}\") but the scene has no Captions entity, so nothing is drawn; game.captions() still lists "
                "it. Add the Captions component to a UI entity (docs/TEXT.md, \"Captions\").",
                lines_.back().text);
    }
    return changed;
}

}  // namespace fa
