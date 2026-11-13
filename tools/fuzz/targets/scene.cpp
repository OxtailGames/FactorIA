// fa::load_scene on any JSON (the .scene.json loader behind the editor, the player, scene.load and scene.import_ascii):
// the scene is loaded into a fresh world, written back with save_scene and loaded again. The loader reports a bad scene as
// messages in the LoadReport; it must never crash, hang or allocate without a bound.
#include <cstddef>
#include <cstdint>

#include "fa/core/json.h"
#include "fa/scene/components.h"
#include "fa/scene/serialize.h"
#include "fa/scene/world.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), fa::ensure_builtin_components(), fa::fuzz::empty_project(), true);
    (void)once;
    auto parsed = fa::parse_json(fa::fuzz::as_text(data, size), "fuzz.scene.json");
    if (!parsed) return 0;

    fa::World world;
    const fa::LoadReport report = fa::load_scene(world, parsed.value(), "fuzz.scene.json");
    (void)report.summary();
    const fa::Json saved = fa::save_scene(world);
    fa::World again;
    (void)fa::load_scene(again, saved, "fuzz-saved.scene.json");
    return 0;
}
