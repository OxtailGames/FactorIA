#include "fa/scene/localize.h"

#include <format>

#include "fa/scene/components.h"

namespace fa {

namespace {

// Writes the translation of `key` into `target` (the field `what` names) when there is one and it differs.
// `args` are the entity's keyArgs: the values of the key's {placeholders}. Formatting a short string each frame costs about
// what the lookup already does for a key without args, so the pass compares the result with the field instead of caching it:
// that also keeps a script's own write to the field overwritten in the same frame and a hot-reloaded table picked up.
int apply(const World& world, Entity e, const I18n& i18n, const std::string& key, const Json& args, std::string& target,
          const char* what) {
    if (key.empty()) return 0;
    std::optional<std::string> text = i18n.translate(key, args);
    if (!text) {
        i18n.warn_once("component|" + key,
                       std::format("{} of entity '{}' has the key '{}', which no string table has: it keeps its own text \"{}\" (hint: {})", what,
                                   world.id_of(e), key, target,
                                   i18n.enabled() ? "add the key to locales/" + i18n.default_language() + ".json"
                                                  : std::string("factoria.json has no \"localization\" section, so nothing is translated: add one (docs/LOCALIZATION.md)")));
        return 0;
    }
    if (*text == target) return 0;
    target = std::move(*text);
    return 1;
}

// A Slider.format pattern keeps its {v} and {percent} for the slider to fill in.
const Json& kFormatArgs() {
    static const Json args = Json::object({{"v", "{v}"}, {"percent", "{percent}"}});
    return args;
}

}  // namespace

int localize_entity(World& world, Entity e, const I18n& i18n) {
    int changed = 0;
    if (Text* t = world.get<Text>(e)) changed += apply(world, e, i18n, t->key, t->keyArgs, t->text, "Text.text");
    if (Button* b = world.get<Button>(e)) changed += apply(world, e, i18n, b->key, b->keyArgs, b->text, "Button.text");
    if (Toggle* t = world.get<Toggle>(e)) changed += apply(world, e, i18n, t->key, t->keyArgs, t->label, "Toggle.label");
    if (Slider* s = world.get<Slider>(e)) changed += apply(world, e, i18n, s->key, s->keyArgs, s->label, "Slider.label");
    if (Slider* s = world.get<Slider>(e)) changed += apply(world, e, i18n, s->formatKey, kFormatArgs(), s->format, "Slider.format");
    if (TextField* f = world.get<TextField>(e)) changed += apply(world, e, i18n, f->key, f->keyArgs, f->placeholder, "TextField.placeholder");
    if (TouchButton* b = world.get<TouchButton>(e)) changed += apply(world, e, i18n, b->key, b->keyArgs, b->text, "TouchButton.text");
    return changed;
}

int localize_world(World& world, const I18n& i18n) {
    int changed = 0;
    world.each<Text>([&](Entity e, Text& t) { changed += apply(world, e, i18n, t.key, t.keyArgs, t.text, "Text.text"); });
    world.each<Button>([&](Entity e, Button& b) { changed += apply(world, e, i18n, b.key, b.keyArgs, b.text, "Button.text"); });
    world.each<Toggle>([&](Entity e, Toggle& t) { changed += apply(world, e, i18n, t.key, t.keyArgs, t.label, "Toggle.label"); });
    world.each<Slider>([&](Entity e, Slider& s) { changed += apply(world, e, i18n, s.key, s.keyArgs, s.label, "Slider.label"); });
    world.each<Slider>([&](Entity e, Slider& s) { changed += apply(world, e, i18n, s.formatKey, kFormatArgs(), s.format, "Slider.format"); });
    world.each<TextField>([&](Entity e, TextField& f) { changed += apply(world, e, i18n, f.key, f.keyArgs, f.placeholder, "TextField.placeholder"); });
    world.each<TouchButton>([&](Entity e, TouchButton& b) { changed += apply(world, e, i18n, b.key, b.keyArgs, b.text, "TouchButton.text"); });
    return changed;
}

}  // namespace fa
