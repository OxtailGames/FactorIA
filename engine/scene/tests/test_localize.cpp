// fa/scene/localize.h: the pass that writes translations into Text and widgets.
#include <doctest.h>

#include "fa/core/log.h"
#include "fa/scene/components.h"
#include "fa/scene/localize.h"
#include "fa/scene/world.h"

using namespace fa;

namespace {

I18n spanish_game() {
    I18n i;
    i.configure("en", {"en", "es"});
    const auto add = [&](const char* lang, const std::vector<std::pair<std::string, std::string>>& strings) {
        StringTable t;
        t.language = lang;
        for (const auto& [k, v] : strings) t.entries[k].text = v;
        REQUIRE(i.add_table(std::move(t)).ok());
    };
    add("en", {{"menu.play", "Play"}, {"menu.volume", "Volume"}, {"menu.sound", "Sound"}, {"menu.name", "Your name"}});
    add("es", {{"menu.play", "Jugar"}, {"menu.volume", "Volumen"}, {"menu.sound", "Sonido"}, {"menu.name", "Tu nombre"}});
    return i;
}

}  // namespace

TEST_CASE("localize: every Text and widget with a key gets the string of the current language") {
    World w;
    I18n i18n = spanish_game();
    Entity title = w.create("title", "title");
    w.add<Text>(title).key = "menu.play";
    Entity plain = w.create("plain", "plain");  // no key: untouched
    w.add<Text>(plain).text = "Hello";
    Entity button = w.create("button", "button");
    w.add<Button>(button).key = "menu.play";
    Entity toggle = w.create("toggle", "toggle");
    w.add<Toggle>(toggle).key = "menu.sound";
    Entity slider = w.create("slider", "slider");
    w.add<Slider>(slider).key = "menu.volume";
    Entity field = w.create("field", "field");
    TextField& tf = w.add<TextField>(field);
    tf.key = "menu.name";
    tf.text = "typed by the player";
    Entity hidden = w.create("hidden", "hidden");
    w.add<Text>(hidden).key = "menu.play";
    w.get<EntityInfo>(hidden)->active = false;

    CHECK(localize_world(w, i18n) == 6);
    CHECK(w.get<Text>(title)->text == "Play");
    CHECK(w.get<Text>(plain)->text == "Hello");
    CHECK(w.get<Button>(button)->text == "Play");
    CHECK(w.get<Toggle>(toggle)->label == "Sound");
    CHECK(w.get<Slider>(slider)->label == "Volume");
    CHECK(w.get<TextField>(field)->placeholder == "Your name");
    CHECK(w.get<TextField>(field)->text == "typed by the player");  // the player's input is never translated
    CHECK(w.get<Text>(hidden)->text == "Play");                     // inactive entities are right when they open
    CHECK(localize_world(w, i18n) == 0);                            // nothing changed, nothing written

    REQUIRE(i18n.set_language("es").ok());
    CHECK(localize_world(w, i18n) == 6);
    CHECK(w.get<Text>(title)->text == "Jugar");
    CHECK(w.get<Text>(plain)->text == "Hello");
    CHECK(w.get<Button>(button)->text == "Jugar");
    CHECK(w.get<Toggle>(toggle)->label == "Sonido");
    CHECK(w.get<Slider>(slider)->label == "Volumen");
    CHECK(w.get<TextField>(field)->placeholder == "Tu nombre");
    CHECK(w.get<Text>(hidden)->text == "Jugar");
}

TEST_CASE("localize: a key no table has keeps the component's text and warns once") {
    World w;
    I18n i18n = spanish_game();
    Entity e = w.create("lonely", "lonely");
    Text& t = w.add<Text>(e);
    t.text = "Own text";
    t.key = "menu.missing";
    const std::uint64_t before = log_last_seq();
    CHECK(localize_world(w, i18n) == 0);
    CHECK(localize_world(w, i18n) == 0);
    CHECK(w.get<Text>(e)->text == "Own text");
    int warnings = 0;
    for (const LogEntry& l : recent_logs(50, LogLevel::Warn, before))
        if (l.category == "i18n" && l.message.find("menu.missing") != std::string::npos) ++warnings;
    CHECK(warnings == 1);
}

TEST_CASE("localize: one entity, and a game without localization") {
    World w;
    I18n i18n = spanish_game();
    REQUIRE(i18n.set_language("es").ok());
    Entity a = w.create("a", "a");
    w.add<Button>(a).key = "menu.play";
    Entity b = w.create("b", "b");
    w.add<Button>(b).key = "menu.play";
    CHECK(localize_entity(w, a, i18n) == 1);
    CHECK(w.get<Button>(a)->text == "Jugar");
    CHECK(w.get<Button>(b)->text == "Button");  // not asked
    I18n off;
    CHECK(localize_world(w, off) == 0);  // keys are kept as written; the text stays
    CHECK(w.get<Button>(a)->text == "Jugar");
}

namespace {

I18n score_game() {
    I18n i;
    i.configure("en", {"en", "es"});
    const auto add = [&](const char* lang, const std::vector<std::pair<std::string, std::string>>& strings) {
        StringTable t;
        t.language = lang;
        for (const auto& [k, v] : strings) t.entries[k].text = v;
        REQUIRE(i.add_table(std::move(t)).ok());
    };
    add("en", {{"hud.score", "Score: {score} / {goal}"}, {"touch.jump", "Jump {key}"}});
    add("es", {{"hud.score", "Puntos: {score} de {goal}"}, {"touch.jump", "Saltar {key}"}});
    return i;
}

}  // namespace

TEST_CASE("localize: keyArgs fill the placeholders, in two languages, and a switch keeps them") {
    World w;
    I18n i18n = score_game();
    Entity label = w.create("score", "score");
    Text& t = w.add<Text>(label);
    t.key = "hud.score";
    t.keyArgs = Json{{"score", 12}, {"goal", 30.5}};
    CHECK(localize_world(w, i18n) == 1);
    CHECK(w.get<Text>(label)->text == "Score: 12 / 30.5");
    CHECK(localize_world(w, i18n) == 0);  // nothing changed, nothing written

    w.get<Text>(label)->keyArgs["score"] = 13;  // a script changes the args once: the next pass re-localizes
    CHECK(localize_world(w, i18n) == 1);
    CHECK(w.get<Text>(label)->text == "Score: 13 / 30.5");

    REQUIRE(i18n.set_language("es").ok());  // the language changes, the args stay
    CHECK(localize_world(w, i18n) == 1);
    CHECK(w.get<Text>(label)->text == "Puntos: 13 de 30.5");
    CHECK(w.get<Text>(label)->keyArgs["score"] == 13);

    Entity button = w.create("buy", "buy");
    Button& b = w.add<Button>(button);
    b.key = "hud.score";
    b.keyArgs = Json{{"score", "tres"}, {"goal", 4}};
    CHECK(localize_entity(w, button, i18n) == 1);
    CHECK(w.get<Button>(button)->text == "Puntos: tres de 4");
}

TEST_CASE("localize: a TouchButton takes a key and keyArgs") {
    World w;
    I18n i18n = score_game();
    Entity e = w.create("jump", "jump");
    TouchButton& b = w.add<TouchButton>(e);
    b.key = "touch.jump";
    b.keyArgs = Json{{"key", "A"}};
    CHECK(localize_world(w, i18n) == 1);
    CHECK(w.get<TouchButton>(e)->text == "Jump A");
    REQUIRE(i18n.set_language("es").ok());
    CHECK(localize_world(w, i18n) == 1);
    CHECK(w.get<TouchButton>(e)->text == "Saltar A");
    Entity plain = w.create("plain", "plain");
    w.add<TouchButton>(plain).text = "B";  // no key: untouched
    CHECK(localize_world(w, i18n) == 0);
    CHECK(w.get<TouchButton>(plain)->text == "B");
}
