// The commands that build a 2D skeleton and paint a skin: bones.create (a chain of Bone2D entities along points),
// skin.bind (a SpriteSkin on a sprite and its bones, bound at the pose they have now), skin.auto_weights (the automatic weights
// written out as explicit ones to paint over) and skin.set_weights (set, add or smooth the weights of chosen vertices).
// They change the scene, so the editor's snapshot undo covers them; the engine itself keeps no history.
#include <algorithm>
#include <cmath>
#include <format>
#include <map>
#include <numbers>
#include <set>

#include "engine_impl.h"
#include "fa/core/strings.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/bounds.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

double round4(double v) { return std::round(v * 10000.0) / 10000.0; }

float wrap_degrees(float d) {
    while (d > 180.0f) d -= 360.0f;
    while (d < -180.0f) d += 360.0f;
    return d;
}

// The local rectangle the Sprite covers (pivot and size as the renderer lays them out; 0 size = region, else the texture, else 32).
SkinBox skin_box_of(Engine::Impl& I, Entity e) {
    const Sprite& s = *I.world.get<Sprite>(e);
    Vec2 size = s.size;
    if (size.x <= 0 || size.y <= 0) {
        Vec2 base{32.0f, 32.0f};
        if (!s.texture.empty()) {
            if (s.region.w > 0 && s.region.h > 0) base = {s.region.w, s.region.h};
            else if (const VisualMeasure m = I.measure(); m.textureSize) base = m.textureSize(s.texture);
        }
        size = {size.x > 0 ? size.x : base.x, size.y > 0 ? size.y : base.y};
    }
    return SkinBox{-s.pivot.x * size.x, -s.pivot.y * size.y, (1.0f - s.pivot.x) * size.x, (1.0f - s.pivot.y) * size.y};
}

// The grid of the skin's mesh (columns, rows); false when the sprite has none.
bool skin_grid(const Sprite& s, const SpriteSkin& skin, const SkinBox& box, int& cols, int& rows) {
    if (skin.outline) {
        skin_outline_dimensions(box, skin.outlineDetail, cols, rows);
        return cols > 0 && rows > 0;
    }
    return sprite_mesh_grid(s, cols, rows);
}

SpriteSkin& need_skin(Engine::Impl& I, Entity e, const char* command) {
    SpriteSkin* skin = I.world.get<SpriteSkin>(e);
    if (!skin || !I.world.has<Sprite>(e))
        throw CommandError("invalid_argument", std::format("{}: '{}' needs a Sprite and a SpriteSkin.", command, I.world.id_of(e)),
                           "skin.bind {entity, bones} adds the SpriteSkin to a Sprite entity and binds it.");
    return *skin;
}

void collect_bones(const World& w, Entity e, std::vector<Entity>& out) {
    if (w.has<Bone2D>(e)) out.push_back(e);
    for (Entity c : w.children(e)) collect_bones(w, c, out);
}

Json entry_json(const std::vector<std::pair<int, float>>& v) {
    Json entry = Json::array();
    for (const auto& [b, wt] : v) {
        entry.push_back(b);
        entry.push_back(round4(wt));
    }
    return entry;
}

std::vector<std::pair<int, float>> entry_of(const Json& j) {
    std::vector<std::pair<int, float>> out;
    if (!j.is_array()) return out;
    for (std::size_t i = 0; i + 1 < j.size(); i += 2)
        if (j[i].is_number() && j[i + 1].is_number()) out.emplace_back(j[i].get<int>(), j[i + 1].get<float>());
    return out;
}

// Normalises to sum 1, drops weights under 0.001, keeps the 4 heaviest (heaviest first; equal weights keep the lower bone).
void tidy(std::vector<std::pair<int, float>>& v) {
    std::map<int, float> sum;
    for (const auto& [b, w] : v) if (w > 0) sum[b] += w;
    v.assign(sum.begin(), sum.end());
    std::stable_sort(v.begin(), v.end(), [](const auto& a, const auto& b) { return a.second > b.second; });
    float total = 0;
    for (const auto& p : v) total += p.second;
    if (total <= 0) { v.clear(); return; }
    for (auto& p : v) p.second /= total;
    v.erase(std::remove_if(v.begin(), v.end(), [](const auto& p) { return p.second < 0.001f; }), v.end());
    if (v.size() > std::size_t(kMaxBonesPerVertex)) v.resize(std::size_t(kMaxBonesPerVertex));
    total = 0;
    for (const auto& p : v) total += p.second;
    for (auto& p : v) p.second /= total;
}

}  // namespace

void register_bones_commands(Engine& engine, Engine::Impl& I) {
    (void)engine;
    I.commands.add({"bones.create", "Create a chain of Bone2D entities along points, under a parent.",
           "`points` are [x, y] positions in the PARENT's local space (at least 2); N points make N-1 bones. Bone 1 is a child of "
           "`parent`, placed at the first point and turned to face the second; every later bone is a child of the one before, placed "
           "at its tip, with the rotation that turns it toward the next point. Each Bone2D.length is the distance between its two "
           "points. `names` (N-1) names them, default prefix_1, prefix_2... (`prefix` default \"bone\"); two bones may not share a "
           "name under one parent, since clip paths and skins find them by name. Pose bones through Transform.rotation.z (clips, "
           "IK2D). Result: {parent, bones: [{id, name, length}]}. Example: bones.create {\"parent\":\"hero\",\"points\":[[0,40],[0,20],[0,0]],\"names\":[\"thigh\",\"shin\"]}",
           parse_schema(R"({"type":"object","required":["parent","points"],"properties":{
               "parent":{"type":"string","description":"Entity the first bone is a child of (id or name)."},
               "points":{"type":"array","minItems":2,"items":{"type":"array","items":{"type":"number"},"minItems":2,"maxItems":2},"description":"Joint positions [x, y] in the parent's local space, from the root of the chain to its tip."},
               "names":{"type":"array","items":{"type":"string"},"description":"One name per bone (points - 1)."},
               "prefix":{"type":"string","default":"bone","description":"Name prefix when `names` is not given."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              const Entity parent = need_entity(I.world, a, "parent");
              if (!a.contains("points") || !a["points"].is_array() || a["points"].size() < 2)
                  throw CommandError("invalid_argument", "`points` needs at least two [x, y] positions.", "Example: [[0, 40], [0, 20], [0, 0]] makes two bones.");
              std::vector<Vec2> pts;
              for (std::size_t i = 0; i < a["points"].size(); ++i) {
                  Vec2 p;
                  std::string err;
                  if (!json_to(a["points"][i], p, &err)) throw CommandError("invalid_argument", std::format("points[{}]: {}", i, err), "Each point is [x, y].");
                  pts.push_back(p);
              }
              const std::size_t count = pts.size() - 1;
              std::vector<std::string> names;
              if (a.contains("names")) {
                  if (!a["names"].is_array() || a["names"].size() != count)
                      throw CommandError("invalid_argument", std::format("`names` must have {} names (one per bone, points - 1), got {}.", count, a["names"].is_array() ? a["names"].size() : 0),
                                         "Name each segment, e.g. [\"thigh\", \"shin\"] for three points.");
                  for (const Json& n : a["names"]) {
                      if (!n.is_string() || n.get<std::string>().empty() || n.get<std::string>().find('/') != std::string::npos)
                          throw CommandError("invalid_argument", "A bone name must be a non-empty string without '/'.", "Clip paths join names with '/', so a name cannot contain one.");
                      names.push_back(n.get<std::string>());
                  }
              } else {
                  const std::string prefix = a.value("prefix", std::string("bone"));
                  for (std::size_t i = 0; i < count; ++i) names.push_back(prefix + "_" + std::to_string(i + 1));
              }
              std::set<std::string> distinct(names.begin(), names.end());
              if (distinct.size() != names.size()) throw CommandError("invalid_argument", "Two bones of the chain have the same name.", "Give every bone a different name.");
              for (Entity c : I.world.children(parent))
                  if (I.world.info(c).name == names[0])
                      throw CommandError("invalid_argument", std::format("'{}' already has a child called '{}'.", I.world.id_of(parent), names[0]),
                                         "Two siblings with one name make a clip path ambiguous: pick another name or prefix.");
              float previousAngle = 0, previousLength = 0;
              Entity previous = parent;
              Json bones = Json::array();
              for (std::size_t i = 0; i < count; ++i) {
                  const Vec2 d = pts[i + 1] - pts[i];
                  const float length = std::sqrt(d.x * d.x + d.y * d.y);
                  if (!(length > 1e-4f))
                      throw CommandError("invalid_argument", std::format("points[{}] and points[{}] are the same point: a bone needs a length.", i, i + 1), "Move one of them.");
              }
              for (std::size_t i = 0; i < count; ++i) {
                  const Vec2 d = pts[i + 1] - pts[i];
                  const float length = std::sqrt(d.x * d.x + d.y * d.y);
                  const float angle = float(std::atan2(double(d.y), double(d.x)) * 180.0 / std::numbers::pi);
                  const Entity bone = I.world.create(names[i]);
                  I.world.add<Bone2D>(bone).length = length;
                  I.world.set_parent(bone, previous);
                  Transform& t = *I.world.get<Transform>(bone);
                  if (i == 0) {
                      t.position = {pts[0].x, pts[0].y, 0};
                      t.rotation = {0, 0, angle};
                  } else {
                      t.position = {previousLength, 0, 0};
                      t.rotation = {0, 0, wrap_degrees(angle - previousAngle)};
                  }
                  previousAngle = angle;
                  previousLength = length;
                  previous = bone;
                  bones.push_back(Json::object({{"id", I.world.id_of(bone)}, {"name", names[i]}, {"length", round4(length)}}));
              }
              return Json::object({{"parent", I.world.id_of(parent)}, {"bones", bones}});
          });

    I.commands.add({"skin.bind", "Skin a Sprite to bones: add the SpriteSkin, name its bones and bind it at the pose they have now.",
           "Adds a SpriteSkin to the Sprite entity `entity` if it has none, sets its bones and records the bind pose (skin_bind): the "
           "sprite looks the same until a bone moves from where it is now. Name the bones with `bones` (ids or names, the order is "
           "the weight order) or give `root`, a bone: it and every Bone2D below it, depth first. `mesh` [columns, rows] sets "
           "Sprite.meshColumns / meshRows (a skin needs a mesh grid, or SpriteSkin.outline). The weights stay as they are (\"auto\" "
           "by default; skin.auto_weights writes them out to paint). Result: {entity, bones: [ids], mesh: [columns, rows] | null, "
           "note?}. Example: skin.bind {\"entity\":\"leg\",\"root\":\"thigh\",\"mesh\":[4,8]}",
           parse_schema(R"({"type":"object","required":["entity"],"properties":{
               "entity":{"type":"string","description":"The Sprite entity to skin (id or name)."},
               "bones":{"type":"array","items":{"type":"string"},"description":"Bone ids or names, in weight order."},
               "root":{"type":"string","description":"A bone: use it and all the Bone2D entities below it."},
               "mesh":{"type":"array","items":{"type":"integer","minimum":1},"minItems":2,"maxItems":2,"description":"[columns, rows] of the Sprite's mesh grid."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              const Entity e = need_entity(I.world, a, "entity");
              if (!I.world.has<Sprite>(e))
                  throw CommandError("invalid_argument", std::format("'{}' has no Sprite, so there is nothing to skin.", I.world.id_of(e)),
                                     "Skin an entity that draws a Sprite: scene.set_component {id, component: \"Sprite\", fields: {texture: ...}}.");
              if (a.contains("bones") == a.contains("root"))
                  throw CommandError("invalid_argument", a.contains("bones") ? "Pass `bones` or `root`, not both." : "Name the bones: pass `bones` (ids or names) or `root` (a bone and everything below it).",
                                     "Example: {\"root\": \"thigh\"} takes the thigh and the bones under it.");
              std::vector<std::string> ids;
              if (a.contains("root")) {
                  const Entity root = need_entity(I.world, a, "root");
                  std::vector<Entity> bones;
                  collect_bones(I.world, root, bones);
                  if (bones.empty())
                      throw CommandError("invalid_argument", std::format("'{}' and the entities below it have no Bone2D.", I.world.id_of(root)), "bones.create makes a chain of bones.");
                  for (Entity b : bones) ids.push_back(I.world.id_of(b));
              } else {
                  if (!a["bones"].is_array() || a["bones"].empty())
                      throw CommandError("invalid_argument", "`bones` must be a non-empty array of bone ids or names.", "Example: [\"thigh\", \"shin\"].");
                  for (const Json& b : a["bones"]) {
                      if (!b.is_string()) throw CommandError("invalid_argument", "`bones` entries must be strings.", "Use the bone ids or names.");
                      const Entity be = I.world.find(b.get<std::string>());
                      if (be == kNullEntity) {
                          std::vector<std::string> names;
                          for (Entity x : I.world.entities_with(TypeRegistry::global().of<Bone2D>())) names.push_back(I.world.info(x).name);
                          throw CommandError("not_found", "No entity '" + b.get<std::string>() + "'. " + did_you_mean(b.get<std::string>(), names), "Bones are entities with a Bone2D (bones.create).");
                      }
                      if (!I.world.has<Bone2D>(be))
                          throw CommandError("invalid_argument", std::format("'{}' is not a bone (no Bone2D component).", b.get<std::string>()), "Make it one with bones.create, or scene.set_component {component: \"Bone2D\"}.");
                      ids.push_back(I.world.id_of(be));
                  }
              }
              if (ids.size() > std::size_t(kMaxSkinBones))
                  throw CommandError("invalid_argument", std::format("{} bones is more than a skin can follow ({}).", ids.size(), kMaxSkinBones), "Skin each limb with its own SpriteSkin.");
              Sprite& sprite = *I.world.get<Sprite>(e);
              if (a.contains("mesh")) {
                  if (!a["mesh"].is_array() || a["mesh"].size() != 2 || !a["mesh"][0].is_number_integer() || !a["mesh"][1].is_number_integer() || a["mesh"][0].get<int>() < 1 || a["mesh"][1].get<int>() < 1)
                      throw CommandError("invalid_argument", "`mesh` must be [columns, rows], whole numbers from 1.", "Example: [4, 8]. 8 x 8 is plenty for a limb.");
                  sprite.meshColumns = a["mesh"][0].get<int>();
                  sprite.meshRows = a["mesh"][1].get<int>();
              }
              SpriteSkin& skin = I.world.has<SpriteSkin>(e) ? *I.world.get<SpriteSkin>(e) : I.world.add<SpriteSkin>(e);
              const bool hadWeights = skin.weights.is_array();
              const std::size_t previousCount = skin.bones.is_array() ? skin.bones.size() : 0;
              skin.bones = Json::array();
              for (const std::string& id : ids) skin.bones.push_back(id);
              skin.bindPose = Json::array();
              auto bound = skin_bind(I.world, e);
              if (!bound.ok()) throw CommandError("failed", bound.error().message, bound.error().hint);
              Json out = Json::object({{"entity", I.world.id_of(e)}, {"bones", skin.bones}});
              int cols = 0, rows = 0;
              if (skin_grid(sprite, skin, skin_box_of(I, e), cols, rows)) out["mesh"] = Json::array({cols, rows});
              else {
                  out["mesh"] = nullptr;
                  out["note"] = "The sprite has no mesh to deform yet: pass `mesh` [columns, rows], or set SpriteSkin.outline = true.";
              }
              if (hadWeights && previousCount != ids.size())
                  out["note"] = (out.contains("note") ? out["note"].get<std::string>() + " " : std::string()) +
                                "The explicit weights were painted for another number of bones: skin.auto_weights starts them again.";
              return out;
          });

    I.commands.add({"skin.auto_weights", "Write the skin's automatic weights out as explicit ones, to paint over with skin.set_weights.",
           "Computes what SpriteSkin.weights \"auto\" would give every vertex of the full mesh grid (each vertex follows its nearest bones, "
           "up to 4) and stores it in SpriteSkin.weights as [boneIndex, weight, ...] per vertex, row-major from the top row "
           "(vertex = row * (columns + 1) + column). The picture does not change. The skin must be bound (skin.bind). Result: {entity, "
           "vertices, columns, rows, bones}. Example: skin.auto_weights {\"entity\":\"leg\"}",
           parse_schema(R"({"type":"object","required":["entity"],"properties":{
               "entity":{"type":"string","description":"The skinned Sprite entity (id or name)."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              const Entity e = need_entity(I.world, a, "entity");
              SpriteSkin& skin = need_skin(I, e, "skin.auto_weights");
              const SkinBox box = skin_box_of(I, e);
              auto weights = skin_auto_weights(I.world, e, box);
              if (!weights.ok()) throw CommandError("invalid_argument", weights.error().message, weights.error().hint);
              skin.weights = *weights;
              int cols = 0, rows = 0;
              skin_grid(*I.world.get<Sprite>(e), skin, box, cols, rows);
              return Json::object({{"entity", I.world.id_of(e)}, {"vertices", weights->size()}, {"columns", cols}, {"rows", rows}, {"bones", skin.bones.size()}});
          });

    I.commands.add({"skin.set_weights", "Paint the bone weights of chosen vertices: set, add or smooth.",
           "`vertices` are grid vertex numbers (row * (columns + 1) + column, row 0 on top), \"all\", or {\"rect\": [x0, y0, x1, y1]} "
           "(every vertex inside that rectangle of the sprite's local space, +Y up). `bone` is a bone index in SpriteSkin.bones or its "
           "name. Modes: `set` gives the bone `weight` (0..1) and scales the vertex's other bones to fill the rest; `add` adds `weight` "
           "(negative removes) to the bone's weight; `smooth` moves every weight `weight` (default 0.5, 0..1) of the way toward the "
           "average of the vertex's grid neighbours (`bone` is not needed). Afterwards each vertex keeps its 4 heaviest bones, "
           "weights under 0.001 dropped, summing to 1. Automatic weights are written out first when the skin still says \"auto\". "
           "Result: {entity, changed, mode}. Example: skin.set_weights {\"entity\":\"leg\",\"vertices\":{\"rect\":[-8,0,8,12]},\"bone\":\"thigh\",\"weight\":1}",
           parse_schema(R"({"type":"object","required":["entity","vertices"],"properties":{
               "entity":{"type":"string","description":"The skinned Sprite entity (id or name)."},
               "vertices":{"description":"Array of vertex numbers, \"all\", or {\"rect\": [x0, y0, x1, y1]} in the sprite's local space."},
               "bone":{"description":"Bone index in SpriteSkin.bones, or the bone's name or id. Not needed for smooth."},
               "weight":{"type":"number","description":"set: the new weight 0..1. add: the amount to add (may be negative). smooth: how far toward the neighbours' average, 0..1 (default 0.5)."},
               "mode":{"type":"string","enum":["set","add","smooth"],"default":"set","description":"How the weight is applied."}}})"),
           false, "scene"},
          [&I](const Json& a) {
              const Entity e = need_entity(I.world, a, "entity");
              SpriteSkin& skin = need_skin(I, e, "skin.set_weights");
              const std::string mode = a.value("mode", std::string("set"));
              if (mode != "set" && mode != "add" && mode != "smooth")
                  throw CommandError("invalid_argument", "Unknown mode '" + mode + "'. " + did_you_mean(mode, std::vector<std::string>{"set", "add", "smooth"}), "mode is set, add or smooth.");
              const SkinBox box = skin_box_of(I, e);
              int cols = 0, rows = 0;
              if (!skin_grid(*I.world.get<Sprite>(e), skin, box, cols, rows))
                  throw CommandError("invalid_argument", "The skin has no mesh grid to paint.", "Set Sprite.meshColumns / meshRows (skin.bind {mesh: [4, 8]}) or SpriteSkin.outline.");
              const SkinBones resolved = skin_resolve_bones(I.world, e, skin);
              const int boneCount = int(resolved.entities.size());
              if (boneCount == 0) throw CommandError("invalid_argument", "The skin has no bones.", "skin.bind {entity, bones} names them.");
              const std::size_t stride = std::size_t(cols) + 1, total = stride * (std::size_t(rows) + 1);
              // The vertex selection.
              std::vector<std::size_t> selected;
              if (!a.contains("vertices")) throw CommandError("invalid_argument", "Missing `vertices`.", "Pass vertex numbers, \"all\", or {\"rect\": [x0, y0, x1, y1]}.");
              const Json& vj = a["vertices"];
              if (vj.is_string() && vj.get<std::string>() == "all") {
                  for (std::size_t i = 0; i < total; ++i) selected.push_back(i);
              } else if (vj.is_object() && vj.contains("rect")) {
                  const Json& rj = vj["rect"];
                  if (!rj.is_array() || rj.size() != 4 || !rj[0].is_number() || !rj[1].is_number() || !rj[2].is_number() || !rj[3].is_number())
                      throw CommandError("invalid_argument", "rect must be [x0, y0, x1, y1].", "In the sprite's local space, +Y up.");
                  const float x0 = std::min(rj[0].get<float>(), rj[2].get<float>()), x1 = std::max(rj[0].get<float>(), rj[2].get<float>());
                  const float y0 = std::min(rj[1].get<float>(), rj[3].get<float>()), y1 = std::max(rj[1].get<float>(), rj[3].get<float>());
                  for (int r2 = 0; r2 <= rows; ++r2)
                      for (int c = 0; c <= cols; ++c) {
                          const float px = box.x0 + (box.x1 - box.x0) * float(c) / float(cols), py = box.y1 + (box.y0 - box.y1) * float(r2) / float(rows);
                          if (px >= x0 - 1e-4f && px <= x1 + 1e-4f && py >= y0 - 1e-4f && py <= y1 + 1e-4f) selected.push_back(std::size_t(r2) * stride + std::size_t(c));
                      }
                  if (selected.empty())
                      throw CommandError("invalid_argument", "No vertex lies inside that rect.", std::format("The mesh covers x {}..{}, y {}..{} in {} x {} cells.", box.x0, box.x1, box.y0, box.y1, cols, rows));
              } else if (vj.is_array() && !vj.empty()) {
                  for (const Json& v : vj) {
                      if (!v.is_number_integer() || v.get<int>() < 0 || std::size_t(v.get<int>()) >= total)
                          throw CommandError("invalid_argument", "Vertex " + v.dump() + " is not in the mesh.", std::format("The grid is {} x {} cells: vertices 0..{}.", cols, rows, total - 1));
                      selected.push_back(std::size_t(v.get<int>()));
                  }
              } else {
                  throw CommandError("invalid_argument", "`vertices` must be an array of vertex numbers, \"all\" or {\"rect\": [x0, y0, x1, y1]}.", "Vertex = row * (columns + 1) + column.");
              }
              // The bone.
              int bone = -1;
              if (mode != "smooth") {
                  if (!a.contains("bone")) throw CommandError("invalid_argument", "Missing `bone`.", "A bone index in SpriteSkin.bones, or its name.");
                  const Json& bj = a["bone"];
                  if (bj.is_number_integer()) {
                      bone = bj.get<int>();
                      if (bone < 0 || bone >= boneCount) throw CommandError("not_found", std::format("Bone index {} is out of range (the skin has {} bones, 0..{}).", bone, boneCount, boneCount - 1), "SpriteSkin.bones lists them in order.");
                  } else if (bj.is_string()) {
                      std::vector<std::string> names;
                      for (int i = 0; i < boneCount; ++i) {
                          const Entity be = resolved.entities[std::size_t(i)];
                          if (be == kNullEntity) continue;
                          names.push_back(I.world.info(be).name);
                          if (I.world.info(be).name == bj.get<std::string>() || I.world.id_of(be) == bj.get<std::string>()) { bone = i; break; }
                      }
                      if (bone < 0) throw CommandError("not_found", "The skin has no bone '" + bj.get<std::string>() + "'. " + did_you_mean(bj.get<std::string>(), names), "Its bones: " + join(names, ", ") + ".");
                  } else {
                      throw CommandError("invalid_argument", "`bone` must be an index or a name.", "Example: 0 or \"thigh\".");
                  }
              }
              if (a.contains("weight") && !a["weight"].is_number()) throw CommandError("invalid_argument", "weight must be a number.", "0..1 for set and smooth.");
              const double weight = a.contains("weight") ? a["weight"].get<double>() : (mode == "smooth" ? 0.5 : 1.0);
              if (mode == "set" && !(weight >= 0 && weight <= 1)) throw CommandError("invalid_argument", "weight must be between 0 and 1 for mode set.", "1 = the bone owns the vertex.");
              if (mode == "smooth" && !(weight >= 0 && weight <= 1)) throw CommandError("invalid_argument", "weight must be between 0 and 1 for mode smooth.", "0.5 moves each weight halfway to the neighbours' average.");
              // Explicit weights, written out first from the automatic ones.
              if (!skin.weights.is_array() || skin.weights.size() < total) {
                  auto automatic = skin_auto_weights(I.world, e, box);
                  if (!automatic.ok()) throw CommandError("invalid_argument", automatic.error().message, automatic.error().hint);
                  skin.weights = *automatic;
              }
              std::vector<std::vector<std::pair<int, float>>> current(total);
              for (std::size_t i = 0; i < total; ++i) current[i] = entry_of(skin.weights[i]);
              const auto before = current;
              auto weight_of = [&](const std::vector<std::pair<int, float>>& v, int b) { for (const auto& p : v) if (p.first == b) return p.second; return 0.0f; };
              for (std::size_t v : selected) {
                  auto& entry = current[v];
                  if (mode == "set") {
                      float others = 0;
                      for (const auto& p : entry) if (p.first != bone) others += p.second;
                      const float remain = float(1.0 - weight);
                      std::vector<std::pair<int, float>> next;
                      for (const auto& p : entry)
                          if (p.first != bone) next.emplace_back(p.first, others > 0 ? p.second / others * remain : 0.0f);
                      next.emplace_back(bone, float(weight));
                      entry = next;
                  } else if (mode == "add") {
                      const float w = std::max(0.0f, weight_of(entry, bone) + float(weight));
                      std::erase_if(entry, [&](const auto& p) { return p.first == bone; });
                      entry.emplace_back(bone, w);
                  } else {
                      const std::size_t row = v / stride, col = v % stride;
                      std::map<int, float> avg;
                      int n = 0;
                      for (int dr = -1; dr <= 1; ++dr)
                          for (int dc = -1; dc <= 1; ++dc) {
                              if ((dr == 0) == (dc == 0)) continue;  // the 4 neighbours
                              const long r2 = long(row) + dr, c2 = long(col) + dc;
                              if (r2 < 0 || c2 < 0 || r2 > rows || c2 > cols) continue;
                              ++n;
                              for (const auto& p : before[std::size_t(r2) * stride + std::size_t(c2)]) avg[p.first] += p.second;
                          }
                      if (n == 0) continue;
                      std::map<int, float> mix;
                      for (const auto& p : before[v]) mix[p.first] += p.second * float(1.0 - weight);
                      for (const auto& [b, s] : avg) mix[b] += s / float(n) * float(weight);
                      entry.assign(mix.begin(), mix.end());
                  }
                  tidy(entry);
                  if (entry.empty()) entry = before[v];  // never leave a vertex without a bone
              }
              std::size_t changed = 0;
              for (std::size_t v : selected) {
                  Json now = entry_json(current[v]);
                  if (now != entry_json(before[v])) ++changed;
                  skin.weights[v] = std::move(now);
              }
              return Json::object({{"entity", I.world.id_of(e)}, {"changed", changed}, {"mode", mode}, {"vertices", selected.size()}});
          });
}

}  // namespace fa
