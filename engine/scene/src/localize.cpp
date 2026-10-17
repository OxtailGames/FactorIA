#include "fa/scene/localize.h"

#include <format>

#include "fa/scene/components.h"

namespace fa {

namespace {

// Writes the translation of `key` into `target` (the field `what` names) when there is one and it differs.
int apply(const World& world, Entity e, const I18n& i18n, const std::string& key, std::string& target, const char* what) {
    if (key.empty()) return 0;
    std::optional<std::string> text = i18n.translate(key);
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

}  // namespace

int localize_entity(World& world, Entity e, const I18n& i18n) {
    int changed = 0;
    if (Text* t = world.get<Text>(e)) changed += apply(world, e, i18n, t->key, t->text, "Text.text");
    if (Button* b = world.get<Button>(e)) changed += apply(world, e, i18n, b->key, b->text, "Button.text");
    if (Toggle* t = world.get<Toggle>(e)) changed += apply(world, e, i18n, t->key, t->label, "Toggle.label");
    if (Slider* s = world.get<Slider>(e)) changed += apply(world, e, i18n, s->key, s->label, "Slider.label");
    if (TextField* f = world.get<TextField>(e)) changed += apply(world, e, i18n, f->key, f->placeholder, "TextField.placeholder");
    return changed;
}

int localize_world(World& world, const I18n& i18n) {
    int changed = 0;
    world.each<Text>([&](Entity e, Text& t) { changed += apply(world, e, i18n, t.key, t.text, "Text.text"); });
    world.each<Button>([&](Entity e, Button& b) { changed += apply(world, e, i18n, b.key, b.text, "Button.text"); });
    world.each<Toggle>([&](Entity e, Toggle& t) { changed += apply(world, e, i18n, t.key, t.label, "Toggle.label"); });
    world.each<Slider>([&](Entity e, Slider& s) { changed += apply(world, e, i18n, s.key, s.label, "Slider.label"); });
    world.each<TextField>([&](Entity e, TextField& f) { changed += apply(world, e, i18n, f.key, f.placeholder, "TextField.placeholder"); });
    return changed;
}

}  // namespace fa
