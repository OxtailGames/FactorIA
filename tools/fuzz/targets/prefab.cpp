// A prefab file ({"format": "factoria.prefab/1", "entity": {...}}) or an entity object, from any JSON: entity_from_json builds
// the entity and its children into a fresh world (also the path of scene.spawn and of every scene entry), make_prefab and
// entity_to_json write it back. A file reference inside the input ("prefab": "x.prefab.json") finds nothing: the project is empty.
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
    auto parsed = fa::parse_json(fa::fuzz::as_text(data, size), "fuzz.prefab.json");
    if (!parsed) return 0;
    const fa::Json& file = parsed.value();
    const fa::Json* entity = &file;
    if (file.is_object())
        if (auto it = file.find("entity"); it != file.end()) entity = &*it;

    fa::World world;
    fa::LoadReport report;
    const fa::Entity root = fa::entity_from_json(world, *entity, fa::kNullEntity, report, "fuzz.prefab.json");
    (void)report.summary();
    // Twice: the second entity meets the ids the first one took, and the deferred-reference path is another branch.
    fa::LoadReport second;
    (void)fa::entity_from_json(world, *entity, root, second, "fuzz.prefab.json", "", -1, /*deferMissingRefs=*/true);
    if (world.alive(root)) {
        (void)fa::make_prefab(world, root);
        (void)fa::entity_to_json(world, root);
    }
    return 0;
}
