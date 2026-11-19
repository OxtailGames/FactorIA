// The node library of the material graph (fa/tooling/material_graph.h): the node types with their ports, docs and GLSL, and the
// helper functions (noise, parallax...) the generator pastes into a snippet only when a node it draws calls them.
//
// A node writes its outputs as expressions. In an expression {name} is the input `name` (a linked output, a constant or the
// default, already widened to the port's type), {ref} the param or texture the node names, {self} the prefix of the node's own
// variables (`n_<id>_`, so {self}rgba is its output `rgba`) and $uv, $world_pos, $world_normal, $world_tangent, $vertex_color,
// $view_dir, $camera_pos and $time the values of the surface being shaded (i.uv or v.uv, fa_time.x...).
#include <algorithm>

#include "fa/tooling/material_graph.h"
#include "material_graph_internal.h"

namespace fa {

namespace graph_detail {

namespace {

const std::vector<std::string> kAllKinds = {"mesh", "sprite", "sky", "post"};
// Nodes that read a uv: every kind that has one.
const std::vector<std::string> kUvKinds = {"mesh", "sprite", "post"};
const std::vector<std::string> kMeshOnly = {"mesh"};
const std::vector<std::string> kSpriteOnly = {"sprite"};
const std::vector<std::string> kPostOnly = {"post"};

GraphPort in(const char* name, const char* type, Json def, const char* doc) {
    return GraphPort{name, type, std::move(def), doc};
}
// An input of an output node that is optional (null default) and written by `assign` ({} is the value).
GraphPort in_as(const char* name, const char* type, const char* doc, const char* assign) {
    GraphPort p{name, type, Json(), doc};
    p.assign = assign;
    return p;
}
GraphPort out(const char* name, const char* type, const char* doc) { return GraphPort{name, type, Json(), doc}; }

Json vec(std::initializer_list<double> v) {
    Json a = Json::array();
    for (double d : v) a.push_back(d);
    return a;
}

GraphNodeType node(const char* type, const char* category, const char* doc, std::vector<GraphPort> inputs,
                   std::vector<GraphPort> outputs, std::vector<std::string> expr,
                   const std::vector<std::string>& kinds = kAllKinds, std::vector<std::string> helpers = {}) {
    GraphNodeType n;
    n.type = type;
    n.category = category;
    n.doc = doc;
    n.inputs = std::move(inputs);
    n.outputs = std::move(outputs);
    n.expr = std::move(expr);
    n.kinds = kinds;
    n.helpers = std::move(helpers);
    return n;
}

GraphNodeType fragment_only(GraphNodeType n) {
    n.fragmentOnly = true;
    return n;
}
// Why a node is not in material kind `kind` and what to use there (the hint of the error that names the node).
GraphNodeType with_instead(GraphNodeType n, const char* kind, const char* text) {
    n.instead.emplace_back(kind, text);
    return n;
}
GraphNodeType with_ref(GraphNodeType n, const char* ref) {
    n.ref = ref;
    return n;
}

// A math node on `gen` values: `a op b`-like, with the named float inputs.
GraphNodeType math2(const char* type, const char* doc, const char* expr, Json defB) {
    return node(type, "math", doc,
                {in("a", "gen", 0.0, "First value."), in("b", "gen", std::move(defB), "Second value.")},
                {out("result", "gen", "The result, a float or a vector like the linked inputs.")}, {expr});
}

// What to use in a post pass instead of a node that works in other kinds only (the hint of the error that names the node).
void add_post_instead(std::vector<GraphNodeType>& lib) {
    static const std::pair<const char*, const char*> kTexts[] = {
        {"vertex.color",
         "A post pass draws one full-screen triangle: it has no mesh vertex colours. `post.scene` gives the picture."},
        {"position.world",
         "A post pass has no geometry, it shades the pixels of the picture: `uv` is the pixel's place on the screen, "
         "`post.depth` its distance from the camera and `post.normal` its surface direction."},
        {"position.view",
         "A post pass has no surface point: `post.depth` gives the distance from the camera at a pixel and `uv` its "
         "place on the screen."},
        {"normal.world",
         "A post pass has no mesh: `post.normal` reads the view-space normal of what the frame drew at a pixel (it "
         "makes the renderer draw the depth and normal prepass)."},
        {"view.dir", "A post pass has no view direction: use `uv` (the place on the screen) and `post.depth`."},
        {"texture.normal",
         "A normal map belongs to a surface. Sample it as a colour with the `texture` node (for a distortion), or "
         "read the scene's normals with `post.normal`."},
        {"triplanar",
         "A post pass has no world position to project along. Sample the texture at `uv` with the `texture` node."},
        {"parallax",
         "A post pass has no surface or view direction to shift a texture along. Sample the texture at `uv` with the "
         "`texture` node."},
        {"fresnel",
         "A post pass has no surface angle to the camera. For a rim from the picture's geometry use math.dot of "
         "`post.normal` and a direction; for one on the screen use math.length of (`uv` - 0.5) into math.smoothstep."},
        {"sprite.color", "`post.scene` gives the picture at a point of the screen (what the passes before drew)."},
        {"sprite.tint", "A post pass draws no item with a tint: use a colour param with the `param` node."},
        {"sprite.texture",
         "A post pass has no main texture: use the `texture` node with one of the material's textures, or "
         "`post.scene` for the picture."},
        {"sprite.life", "A post pass has no particles: use the `time` node for something that changes over time."},
        {"sprite.custom", "A post pass has no per-item values: use the material's params with the `param` node."},
        {"sprite.position",
         "A post pass shades the screen: `uv` is the place on it, 0..1 with y down, and `post.screen` gives its "
         "size in pixels."},
    };
    for (GraphNodeType& n : lib)
        for (const auto& [type, text] : kTexts)
            if (n.type == type) n.instead.emplace_back("post", text);
    // The post nodes read the picture of the frame: a mesh or a sprite material has none, and says what to use there.
    struct PostNodeHint {
        const char* type;
        const char* mesh;
        const char* sprite;
    };
    static const PostNodeHint kPostNodes[] = {
        {"post.scene",
         "A mesh material shades one surface, not the picture: set the output's fields (albedo, emission...). Reading "
         "the "
         "picture belongs to a post material (kind \"post\").",
         "A sprite material shades one item, not the picture: its own colour is `sprite.color`. Reading the picture "
         "belongs "
         "to a post material (kind \"post\")."},
        {"post.depth",
         "Only a post material reads the depth of the picture (kind \"post\"). In a mesh material `position.view` "
         "gives the "
         "point in view space.",
         "Only a post material reads the depth of the picture (kind \"post\"). A sprite has no depth: "
         "`sprite.position` "
         "gives its place."},
        {"post.normal",
         "Only a post material reads the normals of the picture (kind \"post\"). A mesh material has the surface's own "
         "`normal.world`.",
         "Only a post material reads the normals of the picture (kind \"post\"). A sprite has no normal in a graph."},
        {"post.history",
         "Only a post material keeps what it drew last frame (kind \"post\"). A mesh material has no history: use a "
         "script "
         "that writes a param.",
         "Only a post material keeps what it drew last frame (kind \"post\"). A sprite material has no history: use a "
         "script that writes a param."},
        {"post.screen",
         "Only a post material shades the whole picture (kind \"post\"). A mesh material has `uv` for a place on its "
         "surface.",
         "Only a post material shades the whole picture (kind \"post\"). A sprite has `sprite.position` (its `screen` "
         "output "
         "is the pixel's place) and `uv`."},
    };
    for (GraphNodeType& n : lib)
        for (const PostNodeHint& h : kPostNodes)
            if (n.type == h.type) {
                n.instead.emplace_back("sprite", h.sprite);
                n.instead.emplace_back("mesh", h.mesh);
            }
}

std::vector<GraphNodeType> build_library() {
    std::vector<GraphNodeType> lib;
    // ---- constants ----
    lib.push_back(node("const.float", "constant", "A number.", {in("value", "float", 0.0, "The number.")},
                       {out("value", "float", "The number.")}, {"{value}"}));
    lib.push_back(node("const.vec2", "constant", "A 2-component vector.",
                       {in("value", "vec2", vec({0, 0}), "The vector.")}, {out("value", "vec2", "The vector.")},
                       {"{value}"}));
    lib.push_back(node("const.vec3", "constant", "A 3-component vector.",
                       {in("value", "vec3", vec({0, 0, 0}), "The vector.")}, {out("value", "vec3", "The vector.")},
                       {"{value}"}));
    lib.push_back(node("const.vec4", "constant", "A 4-component vector.",
                       {in("value", "vec4", vec({0, 0, 0, 0}), "The vector.")}, {out("value", "vec4", "The vector.")},
                       {"{value}"}));
    lib.push_back(
        node("const.color", "constant",
             "A colour, red green blue alpha, each 0..1, typed as sRGB like a colour param. A sprite or post graph "
             "converts it to the colour space of the scene (fa_scene_rgb); a mesh graph writes it as typed. A "
             "number typed straight into an output input is not converted.",
             {in("rgba", "vec4", vec({1, 1, 1, 1}), "The colour.")},
             {out("rgba", "vec4", "The colour with alpha."), out("rgb", "vec3", "The colour without alpha.")},
             {"{rgba}", "{self}rgba.rgb"}));
    // ---- parameters and textures ----
    lib.push_back(with_ref(
        node("param", "input",
             "The value of one of the material's params (set \"param\" to its name). The param stays a normal param: "
             "material.info lists it and MeshRenderer.materialParams overrides it per entity. float, vec2, vec3, vec4 "
             "and "
             "color params give a float, vec2, vec3, vec4 and vec4.",
             {}, {out("value", "param", "The param's value, typed like the param.")}, {"{ref}"}),
        "param"));
    // ---- inputs of the surface ----
    lib.push_back(node("uv", "input", "The texture coordinates of the surface, tiled and offset.",
                       {in("uv", "vec2", "$uv", "The coordinates to transform (default: the mesh's uv)."),
                        in("tiling", "vec2", vec({1, 1}), "How many times the coordinates repeat."),
                        in("offset", "vec2", vec({0, 0}), "Added after tiling.")},
                       {out("uv", "vec2", "uv * tiling + offset.")}, {"{uv} * {tiling} + {offset}"}, kUvKinds));
    lib.push_back(
        node("time", "input",
             "The engine clock (seconds of game time since the scene started; deterministic, paused with the game).",
             {in("speed", "float", 1.0, "Multiplier of the clock.")},
             {out("time", "float", "Seconds times speed."), out("sin", "float", "sin(time), -1..1."),
              out("cos", "float", "cos(time), -1..1.")},
             {"$time * {speed}", "sin({self}time)", "cos({self}time)"}));
    lib.push_back(with_instead(
        node("vertex.color", "input", "The vertex colour of the mesh (white without).", {},
             {out("rgba", "vec4", "The colour with alpha."), out("rgb", "vec3", "The colour."),
              out("a", "float", "The alpha.")},
             {"$vertex_color", "{self}rgba.rgb", "{self}rgba.a"}, kMeshOnly),
        "sprite",
        "A sprite has no mesh vertex colours: `sprite.tint` is the tint of the item (its colour, a particle's fade)."));
    lib.push_back(with_instead(node("position.world", "input", "The world-space position of the point.", {},
                                    {out("position", "vec3", "World position.")}, {"$world_pos"}, kMeshOnly),
                               "sprite",
                               "A sprite lives in 2D: `sprite.position` gives its 2D world position (a vec2) and the "
                               "`uv` node the coordinates on the item."));
    lib.push_back(fragment_only(with_instead(
        node("position.view", "input",
             "The position of the point relative to the camera (world axes): world position minus "
             "camera position. Its length is the distance to the camera.",
             {}, {out("position", "vec3", "Camera-relative position.")}, {"$world_pos - $camera_pos"}, kMeshOnly),
        "sprite",
        "A 2D item has no distance to the camera: `sprite.position` gives its 2D world position and, in its `screen` "
        "output, the place on the render target.")));
    lib.push_back(with_instead(
        node("normal.world", "input",
             "The geometric normal in world space (normalized, flipped on back faces); not the normal map.", {},
             {out("normal", "vec3", "World normal.")}, {"$world_normal"}, kMeshOnly),
        "sprite",
        "A sprite is a flat quad with no surface normal; the engine applies the 2D lights before fragment() runs, so "
        "`sprite.color` already holds the lit picture."));
    lib.push_back(fragment_only(with_instead(
        node("view.dir", "input", "The direction from the surface to the camera (normalized).", {},
             {out("direction", "vec3", "Surface to camera.")}, {"$view_dir"}, kMeshOnly),
        "sprite", "A 2D item has no view direction: it always faces the camera. Use `uv` or `sprite.position`.")));
    // ---- inputs of a 2D item (QuadInput and QuadSurface of the sprite template; docs/SHADERS.md, "Materials on sprites...") ----
    lib.push_back(fragment_only(node(
        "sprite.color", "input",
        "What the engine would draw for the item at this point: the picture times the tint, the circle of a shape, the "
        "glyph, already lit by the 2D lights (QuadSurface.color on arrival). Mix it with your own colours to change a "
        "sprite and keep the rest of it.",
        {},
        {out("rgba", "vec4", "The colour with alpha."), out("rgb", "vec3", "The colour."),
         out("a", "float", "The alpha.")},
        {"$sprite_color", "{self}rgba.rgb", "{self}rgba.a"}, kSpriteOnly)));
    lib.push_back(node(
        "sprite.tint", "input",
        "The tint of the item (QuadInput.color: Sprite.color, a particle's colour over its life, the "
        "colour of a shape), linear in a linear scene. Works in the vertex stage too.",
        {},
        {out("rgba", "vec4", "The tint with alpha."), out("rgb", "vec3", "The tint."), out("a", "float", "The alpha.")},
        {"$tint", "{self}rgba.rgb", "{self}rgba.a"}, kSpriteOnly));
    lib.push_back(fragment_only(
        node("sprite.texture", "texture",
             "The item's main texture (the Sprite's picture, the glyph atlas of a Text) at `uv`, in the colour space "
             "of the scene, without the tint. For the material's own textures use the `texture` node.",
             {in("uv", "vec2", "$uv", "Coordinates (default: the item's uv).")},
             {out("rgba", "vec4", "The texel."), out("rgb", "vec3", "Colour."), out("a", "float", "Alpha.")},
             {"fa_sample_main({uv})", "{self}rgba.rgb", "{self}rgba.a"}, kSpriteOnly)));
    lib.push_back(fragment_only(
        node("sprite.life", "input",
             "Particles: how far the particle is through its life, 0 at birth to 1 at the end. 0 for everything else "
             "(sprites, shapes, tiles, text, trails).",
             {}, {out("life", "float", "0..1.")}, {"$life"}, kSpriteOnly)));
    lib.push_back(fragment_only(
        node("sprite.custom", "input",
             "QuadInput.custom: reserved, zero today (per-sprite values are the material's instanced params).", {},
             {out("custom", "vec4", "Zero.")}, {"$custom"}, kSpriteOnly)));
    lib.push_back(fragment_only(
        node("sprite.position", "input",
             "Where the fragment is: its world position (x, y) and its place on the render target.", {},
             {out("world", "vec2", "World position (x, y)."),
              out("screen", "vec2", "Position in the render target, 0..1, y running down on every backend.")},
             {"$sprite_pos", "$screen_uv"}, kSpriteOnly)));
    // ---- inputs of a post pass (PostInput, fa_scene_color, fa_depth, fa_normal, fa_history of the post template; docs/shaders/SHADERS_POST.md) ----
    lib.push_back(node("post.scene", "input",
                       "The picture the passes before this one left, at `uv` (fa_scene_color: 0..1 over the camera's "
                       "rectangle, y down, bilinear, "
                       "clamped to the rectangle): scene-linear HDR colour before the tonemap, display colour after "
                       "it. Sample it at a moved `uv` for a "
                       "distortion or a blur.",
                       {in("uv", "vec2", "$uv", "Where to read the picture (default: this pixel).")},
                       {out("rgba", "vec4", "The picture's colour with alpha."), out("rgb", "vec3", "The colour."),
                        out("a", "float", "The alpha.")},
                       {"fa_scene_color({uv})", "{self}rgba.rgb", "{self}rgba.a"}, kPostOnly));
    lib.push_back(
        node("post.depth", "input",
             "The linear view depth at `uv` in world units (fa_depth), 60000 where no mesh was drawn (the sky, "
             "sprites). Using it makes the "
             "renderer draw the depth and normal prepass for the camera; a GPU without sampled depth skips the pass.",
             {in("uv", "vec2", "$uv", "Where to read the depth (default: this pixel).")},
             {out("depth", "float", "Distance along the camera's forward axis; 60000 where nothing was drawn."),
              out("mask", "float", "1 where a mesh was drawn, 0 on the sky and on sprites.")},
             {"fa_depth({uv})", "1.0 - step(59999.0, {self}depth)"}, kPostOnly));
    lib.push_back(node("post.normal", "input",
                       "The view-space normal of the surface at `uv` (fa_normal: x right, y up, z towards the camera), "
                       "vec3(0) where no mesh was "
                       "drawn. Using it makes the renderer draw the depth and normal prepass for the camera.",
                       {in("uv", "vec2", "$uv", "Where to read the normal (default: this pixel).")},
                       {out("normal", "vec3", "The normal; zero where nothing was drawn.")}, {"fa_normal({uv})"},
                       kPostOnly));
    lib.push_back(
        node("post.history", "input",
             "What THIS pass drew in the frame before, at `uv` (fa_history): a trail, a feedback, an accumulation. "
             "Using it is what asks the "
             "renderer to keep the pass's output (two images of the camera's rectangle, per camera); there is nothing "
             "else to declare. Where "
             "there is no history yet (the first frame, a resize, a camera cut) it gives the picture and `valid` is 0.",
             {in("uv", "vec2", "$uv", "Where to read the last frame (default: this pixel).")},
             {out("rgba", "vec4", "Last frame's output with alpha."), out("rgb", "vec3", "The colour."),
              out("valid", "float", "1 when last frame's output was read, 0 when the picture stands in.")},
             {"fa_history({uv})", "{self}rgba.rgb", "(fa_history_valid ? 1.0 : 0.0)"}, kPostOnly));
    lib.push_back(node("post.screen", "input",
                       "The camera's rectangle: the size of one pixel in uv units, its size in pixels and its aspect "
                       "(width over height), "
                       "to keep a vignette round or a blur the same size on every resolution.",
                       {},
                       {out("texel", "vec2", "1 / size: one pixel in uv units."),
                        out("size", "vec2", "The rectangle in pixels."), out("aspect", "float", "Width over height.")},
                       {"$texel", "$size", "$size.x / max($size.y, 1.0)"}, kPostOnly));
    lib.push_back(fragment_only(with_ref(
        node("texture", "texture",
             "Samples one of the material's textures (set \"texture\" to its name; declare it in the material's "
             "\"textures\"). "
             "A material has at most 4.",
             {in("uv", "vec2", "$uv", "Coordinates (default: the mesh's uv).")},
             {out("rgba", "vec4", "The texel."), out("rgb", "vec3", "Colour."), out("r", "float", "Red channel."),
              out("g", "float", "Green channel."), out("b", "float", "Blue channel."), out("a", "float", "Alpha.")},
             {"texture(sampler2D({ref}, {ref}_smp), {uv})", "{self}rgba.rgb", "{self}rgba.r", "{self}rgba.g",
              "{self}rgba.b", "{self}rgba.a"},
             kUvKinds),
        "texture")));
    lib.push_back(fragment_only(with_instead(
        with_ref(node("texture.normal", "texture",
                      "Samples a tangent-space normal map (set \"texture\" to its name) and unpacks it to a vector of "
                      "length 1 for "
                      "the output's tangentNormal.",
                      {in("uv", "vec2", "$uv", "Coordinates (default: the mesh's uv)."),
                       in("strength", "float", 1.0, "Scales the bumps: 0 is flat, 1 as painted, 2 twice as steep.")},
                      {out("normal", "vec3", "Tangent-space normal (x right, y up the uv, z out of the surface).")},
                      {"gn_unpack_normal(texture(sampler2D({ref}, {ref}_smp), {uv}), {strength})"}, kMeshOnly,
                      {"gn_unpack_normal"}),
                 "texture"),
        "sprite",
        "The output of a sprite graph has no normal: the engine's 2D lights use the sprite's own normal map. Use a "
        "`texture` node to read a texture.")));
    lib.push_back(fragment_only(with_instead(
        with_ref(
            node("triplanar", "texture",
                 "Samples a texture projected along the three world axes and blended by the normal: no uv needed, no "
                 "stretching on "
                 "rocks and terrain (set \"texture\" to its name, use a texture with a Repeat sampler).",
                 {in("position", "vec3", "$world_pos", "World position to project (default: the point's)."),
                  in("normal", "vec3", "$world_normal",
                     "Normal that weights the three projections (default: the geometric normal)."),
                  in("scale", "float", 1.0, "Repeats per world unit."),
                  in("sharpness", "float", 4.0,
                     "How hard the projections separate: 1 is soft, 8 is nearly a hard edge.")},
                 {out("rgba", "vec4", "The blended texel."), out("rgb", "vec3", "Its colour.")},
                 {"texture(sampler2D({ref}, {ref}_smp), {position}.zy * {scale}) * gn_tri_weights({normal}, "
                  "{sharpness}).x "
                  "+ "
                  "texture(sampler2D({ref}, {ref}_smp), {position}.xz * {scale}) * gn_tri_weights({normal}, "
                  "{sharpness}).y "
                  "+ "
                  "texture(sampler2D({ref}, {ref}_smp), {position}.xy * {scale}) * gn_tri_weights({normal}, "
                  "{sharpness}).z",
                  "{self}rgba.rgb"},
                 kMeshOnly, {"gn_tri_weights"}),
            "texture"),
        "sprite",
        "Projecting along three world axes needs a 3D surface; a sprite is flat. Sample the picture with a `texture` "
        "node "
        "(or `sprite.texture`) and move its uv with the `uv` node (tiling, offset) or `flow`.")));
    lib.push_back(fragment_only(with_instead(
        with_ref(node("parallax", "texture",
                      "Parallax occlusion mapping: moves the uv along the view ray until it meets the height map (set "
                      "\"texture\" to "
                      "a height map: white is high, black is deep, red channel), so bricks and cobbles look deep. Feed "
                      "`uv` of this "
                      "node to the texture nodes that draw the surface. Costs up to `steps` texture reads.",
                      {in("uv", "vec2", "$uv", "Coordinates (default: the mesh's uv)."),
                       in("scale", "float", 0.05, "Depth of the surface in uv units (0.02 subtle, 0.1 deep)."),
                       in("steps", "float", 16.0, "Layers of the search, 4 to 64: more is smoother and slower.")},
                      {out("uv", "vec2", "The coordinates to sample with."),
                       out("depth", "float", "How deep the point is, 0 on the top.")},
                      {"gn_parallax({ref}, {ref}_smp, {uv}, gn_tangent_view($view_dir, $world_normal, $world_tangent), "
                       "{scale}, {steps}).xy",
                       "gn_parallax({ref}, {ref}_smp, {uv}, gn_tangent_view($view_dir, $world_normal, $world_tangent), "
                       "{scale}, {steps}).z"},
                      kMeshOnly, {"gn_parallax", "gn_tangent_view"}),
                 "texture"),
        "sprite",
        "Parallax moves the uv along the view ray over a 3D surface; a sprite has no view ray. For depth in 2D shift "
        "the "
        "uv of a `texture` node by an amount that depends on a height (math.mul, `uv`).")));
    // ---- math ----
    lib.push_back(math2("math.add", "a + b, per component.", "{a} + {b}", 0.0));
    lib.push_back(math2("math.sub", "a - b, per component.", "{a} - {b}", 0.0));
    lib.push_back(math2("math.mul", "a * b, per component.", "{a} * {b}", 1.0));
    lib.push_back(math2("math.div", "a / b, per component. Dividing by 0 gives infinity: guard b.", "{a} / {b}", 1.0));
    lib.push_back(math2("math.min", "The smaller of a and b, per component.", "min({a}, {b})", 0.0));
    lib.push_back(math2("math.max", "The larger of a and b, per component.", "max({a}, {b})", 0.0));
    lib.push_back(math2("math.pow", "a raised to b, per component (a below 0 is undefined: use math.abs first).",
                        "pow({a}, {b})", 1.0));
    lib.push_back(node("math.lerp", "math", "Blends from a to b: a at t = 0, b at t = 1.",
                       {in("a", "gen", 0.0, "Value at t = 0."), in("b", "gen", 1.0, "Value at t = 1."),
                        in("t", "float", 0.5, "Blend factor, usually 0..1.")},
                       {out("result", "gen", "The blend.")}, {"mix({a}, {b}, {t})"}));
    lib.push_back(node("math.clamp", "math", "Limits x to min..max.",
                       {in("x", "gen", 0.0, "The value."), in("min", "float", 0.0, "Lower limit."),
                        in("max", "float", 1.0, "Upper limit.")},
                       {out("result", "gen", "The limited value.")}, {"clamp({x}, {min}, {max})"}));
    lib.push_back(node("math.saturate", "math", "Limits x to 0..1.", {in("x", "gen", 0.0, "The value.")},
                       {out("result", "gen", "The limited value.")}, {"clamp({x}, 0.0, 1.0)"}));
    lib.push_back(node("math.smoothstep", "math", "0 below edge0, 1 above edge1, a smooth S curve between.",
                       {in("edge0", "float", 0.0, "Where the curve starts."),
                        in("edge1", "float", 1.0, "Where the curve ends."), in("x", "gen", 0.5, "The value.")},
                       {out("result", "gen", "0..1.")}, {"smoothstep({edge0}, {edge1}, {x})"}));
    lib.push_back(node("math.step", "math", "0 below edge, 1 from edge up (a hard threshold).",
                       {in("edge", "float", 0.5, "The threshold."), in("x", "gen", 0.0, "The value.")},
                       {out("result", "gen", "0 or 1.")}, {"step({edge}, {x})"}));
    lib.push_back(node("math.abs", "math", "The absolute value.", {in("x", "gen", 0.0, "The value.")},
                       {out("result", "gen", "|x|.")}, {"abs({x})"}));
    lib.push_back(node("math.fract", "math", "The fractional part: x minus floor(x), 0..1 (a repeating ramp).",
                       {in("x", "gen", 0.0, "The value.")}, {out("result", "gen", "Fraction.")}, {"fract({x})"}));
    lib.push_back(node("math.sin", "math", "sin(x) with x in radians (6.2831853 is one turn), -1..1.",
                       {in("x", "gen", 0.0, "Angle in radians.")}, {out("result", "gen", "Sine.")}, {"sin({x})"}));
    lib.push_back(node("math.oneminus", "math", "1 - x (inverts a mask).", {in("x", "gen", 0.0, "The value.")},
                       {out("result", "gen", "1 - x.")}, {"1.0 - {x}"}));
    lib.push_back(node("math.dot", "math", "The dot product of a and b (a float).",
                       {in("a", "gen", 0.0, "First vector."), in("b", "gen", 0.0, "Second vector.")},
                       {out("result", "float", "Dot product.")}, {"dot({a}, {b})"}));
    lib.push_back(node("math.length", "math", "The length of a vector (the absolute value of a float).",
                       {in("x", "gen", 0.0, "The vector.")}, {out("result", "float", "Length.")}, {"length({x})"}));
    lib.push_back(node("math.normalize", "math", "The vector scaled to length 1 (a zero vector is undefined).",
                       {in("x", "gen", 1.0, "The vector.")}, {out("result", "gen", "Unit vector.")},
                       {"normalize({x})"}));
    lib.push_back(
        node("math.split", "math",
             "Splits a vector into its components. Use only the outputs the vector has (z needs a vec3, w a vec4).",
             {in("value", "gen", 0.0, "The vector.")},
             {out("x", "float", "First component."), out("y", "float", "Second component (vec2 and up)."),
              out("z", "float", "Third component (vec3 and up)."), out("w", "float", "Fourth component (vec4).")},
             {"{value}.x", "{value}.y", "{value}.z", "{value}.w"}));
    lib.push_back(
        node("math.combine", "math", "Builds a vector from floats; use the output of the size you need.",
             {in("x", "float", 0.0, "First component."), in("y", "float", 0.0, "Second component."),
              in("z", "float", 0.0, "Third component."), in("w", "float", 1.0, "Fourth component.")},
             {out("vec2", "vec2", "(x, y)."), out("vec3", "vec3", "(x, y, z)."), out("vec4", "vec4", "(x, y, z, w).")},
             {"vec2({x}, {y})", "vec3({x}, {y}, {z})", "vec4({x}, {y}, {z}, {w})"}));
    // ---- noise ----
    const char* noiseDoc = "Coordinates to sample, multiplied by scale (default: the mesh's uv).";
    lib.push_back(node(
        "noise.value", "noise", "Value noise: soft random blobs, 0..1. Cheap; deterministic (no time, no random seed).",
        {in("p", "vec2", "$uv", noiseDoc), in("scale", "float", 8.0, "Blobs per unit of p.")},
        {out("value", "float", "Noise, 0..1.")}, {"gn_value_noise({p} * {scale})"}, kUvKinds, {"gn_value_noise"}));
    lib.push_back(node("noise.gradient", "noise",
                       "Gradient (Perlin-style) noise: smoother and less blocky than value noise, 0..1.",
                       {in("p", "vec2", "$uv", noiseDoc), in("scale", "float", 8.0, "Features per unit of p.")},
                       {out("value", "float", "Noise, 0..1, around 0.5.")}, {"gn_gradient_noise({p} * {scale})"},
                       kUvKinds, {"gn_gradient_noise"}));
    lib.push_back(
        node("noise.voronoi", "noise", "Voronoi (cellular) noise: cracked ground, scales, cells.",
             {in("p", "vec2", "$uv", noiseDoc), in("scale", "float", 6.0, "Cells per unit of p.")},
             {out("distance", "float", "Distance to the nearest cell centre, 0 in the middle, about 1 far away."),
              out("cell", "float", "A random value 0..1, the same inside one cell."),
              out("edge", "float",
                  "Gap between the nearest and the second nearest centre: small on the lines between cells.")},
             {"gn_voronoi({p} * {scale}).x", "gn_voronoi({p} * {scale}).y", "gn_voronoi({p} * {scale}).z"}, kUvKinds,
             {"gn_voronoi"}));
    lib.push_back(node(
        "noise.fbm", "noise",
        "Fractal noise: gradient noise summed over octaves of rising detail, 0..1 (clouds, rock, dissolve).",
        {in("p", "vec2", "$uv", noiseDoc), in("scale", "float", 6.0, "Features per unit of p in the first octave."),
         in("octaves", "float", 4.0, "Layers of detail, 1 to 8 (each costs one more noise)."),
         in("lacunarity", "float", 2.0, "Frequency growth per octave."),
         in("gain", "float", 0.5, "Amplitude left per octave.")},
        {out("value", "float", "Noise, 0..1.")}, {"gn_fbm({p} * {scale}, {octaves}, {lacunarity}, {gain})"}, kUvKinds,
        {"gn_fbm"}));
    // ---- effects ----
    lib.push_back(
        node("dissolve", "effect",
             "A dissolve: a surface that burns away where `noise` is below `threshold`, with a glowing edge. Drive "
             "`threshold` from a param and link `alpha` to the output's alpha (alphaMode \"clip\" cuts the holes, also "
             "in the shadow) and `emission` to its emission.",
             {in("noise", "float", 0.5, "A 0..1 noise (noise.fbm)."),
              in("threshold", "float", 0.0, "0 shows everything, 1 nothing."),
              in("edgeWidth", "float", 0.05, "Width of the glowing edge in noise units."),
              in("edgeColor", "vec3", vec({1.0, 0.4, 0.1}), "Colour of the glowing edge (emission).")},
             {out("alpha", "float", "1 where the surface is kept, 0 where it dissolved."),
              out("edge", "float", "1 on the burning edge, 0 elsewhere (and always 0 at threshold 0)."),
              out("emission", "vec3", "edgeColor on the edge, black elsewhere.")},
             {"step({threshold}, {noise})", "gn_dissolve_edge({noise}, {threshold}, {edgeWidth})",
              "{edgeColor} * {self}edge"},
             kAllKinds, {"gn_dissolve_edge"}));
    lib.push_back(
        node("flow", "effect",
             "Flow map: two uv sets that slide along a flow vector and cross-fade, so a texture seems to flow without "
             "stretching. Sample the texture at uv0 and uv1 and blend the two with math.lerp using `blend` as t.",
             {in("uv", "vec2", "$uv", "Coordinates (default: the mesh's uv)."),
              in("flow", "vec2", vec({0, 0}),
                 "Direction and speed of the flow, -1..1 (from a flow-map texture: rg * 2 - 1)."),
              in("strength", "float", 0.25, "How far the uv slides in one cycle."),
              in("speed", "float", 1.0, "Cycles per second."),
              in("time", "float", "$time", "The clock (default: the engine's).")},
             {out("uv0", "vec2", "First coordinate set."), out("uv1", "vec2", "Second set, half a cycle later."),
              out("blend", "float", "Weight of uv1: 1 where uv0 restarts, 0 where uv1 restarts.")},
             {"{uv} - {flow} * {strength} * fract({time} * {speed})",
              "{uv} - {flow} * {strength} * fract({time} * {speed} + 0.5)", "abs(2.0 * fract({time} * {speed}) - 1.0)"},
             kUvKinds));
    lib.push_back(fragment_only(with_instead(
        node("fresnel", "effect",
             "Rim factor: 0 where the surface faces the camera, 1 at the silhouette (rim light, glass, shields).",
             {in("normal", "vec3", "$world_normal", "Surface normal (default: the geometric normal)."),
              in("view", "vec3", "$view_dir", "Direction to the camera (default: the view direction)."),
              in("power", "float", 5.0, "Sharpness of the rim: 1 is wide, 8 is a thin line.")},
             {out("value", "float", "0..1.")},
             {"pow(1.0 - clamp(dot(normalize({normal}), normalize({view})), 0.0, 1.0), max({power}, 0.0001))"},
             kMeshOnly),
        "sprite",
        "A sprite has no 3D normal or view direction, so there is no silhouette angle. For a glowing rim feed "
        "math.length of (`uv` - 0.5) into math.smoothstep: it is 0 in the middle and 1 at the edge of the quad.")));
    // ---- the output ----
    lib.push_back(node(
        kGraphOutputNode, "output",
        "The end of the graph (exactly one): each input that is linked or set in \"inputs\" replaces that field of "
        "the surface the engine lit; the others keep what the MeshRenderer gave (texture * color, normal map...). "
        "`vertexOffset` moves the vertices in vertex() (world space): only nodes that do not sample textures or read "
        "the view may feed it.",
        {in("albedo", "vec3", Json(), "Base colour: replaces Surface.albedo."),
         in("alpha", "float", Json(), "Opacity: replaces Surface.alpha (used by alphaMode clip and blend)."),
         in("emission", "vec3", Json(), "Light the surface emits: replaces Surface.emission."),
         in("metallic", "float", Json(), "0 dielectric, 1 metal: replaces Surface.metallic."),
         in("roughness", "float", Json(),
            "0 mirror, 1 matte (the engine clamps to 0.05..1): replaces Surface.roughness."),
         in("occlusion", "float", Json(), "Ambient occlusion 0..1: replaces Surface.occlusion."),
         in("normal", "vec3", Json(), "World-space normal: replaces Surface.normal. Not together with tangentNormal."),
         in("tangentNormal", "vec3", Json(),
            "Tangent-space normal (texture.normal): turned to world space and replaces Surface.normal."),
         in("vertexOffset", "vec3", Json(),
            "World-space offset added to every vertex (waves, wind): written into vertex().")},
        {}, {}, kMeshOnly));
    // The output of a sprite graph: what fragment() leaves in QuadSurface.color, and vertex()'s offset. Same type name as the mesh one (a
    // graph has one output node whatever its kind); find_graph_node_type(type, kind) picks the one of the kind.
    lib.push_back(node(
        kGraphOutputNode, "output",
        "The end of the graph (exactly one): the fields linked or set in \"inputs\" replace what fragment() received "
        "in "
        "QuadSurface.color (the engine's own picture: texture * tint, lit); the others keep it. `color` is written "
        "first, then `rgb` and `alpha` over it. `vertexOffset` moves the quad's vertices in vertex() (world space): "
        "only nodes that do not sample textures may feed it. The engine blends a sprite: alphaMode clip is not "
        "available, use `alpha` 0 where it must vanish.",
        {in_as("color", "vec4", "The whole colour with alpha (straight, not premultiplied): replaces s.color.",
               "s.color = {};"),
         in_as("rgb", "vec3", "The colour without alpha: replaces s.color.rgb (the alpha stays).", "s.color.rgb = {};"),
         in_as("alpha", "float", "Opacity: replaces s.color.a (a node's alpha, a dissolve cut...).", "s.color.a = {};"),
         in_as("vertexOffset", "vec3",
               "World-space offset added to every vertex of the quad (wobble, wind): written into vertex().",
               "v.world_pos += {};")},
        {}, {}, kSpriteOnly));
    // The output of a post graph: what post() leaves in PostSurface.color. No vertex stage (the pass is one full-screen triangle).
    lib.push_back(node(
        kGraphOutputNode, "output",
        "The end of the graph (exactly one): the fields linked or set in \"inputs\" replace what post() received in "
        "PostSurface.color (the picture at this pixel); the others keep it. `color` is written first, then `rgb` over "
        "it. The pass "
        "has no vertex stage and writes opaque colour (a NaN or a negative becomes 0): the alpha of the picture is "
        "carried through.",
        {in_as("color", "vec4", "The whole colour with alpha: replaces s.color.", "s.color = {};"),
         in_as("rgb", "vec3", "The colour without alpha: replaces s.color.rgb (the alpha stays).",
               "s.color.rgb = {};")},
        {}, {}, kPostOnly));
    add_post_instead(lib);
    return lib;
}

}  // namespace

const std::vector<GraphNodeType>& library() {
    static const std::vector<GraphNodeType> lib = build_library();
    return lib;
}

}  // namespace graph_detail

const std::vector<GraphNodeType>& graph_node_library() { return graph_detail::library(); }

const GraphNodeType* find_graph_node_type(std::string_view type, std::string_view kind) {
    for (const GraphNodeType& n : graph_detail::library()) {
        if (n.type != type) continue;
        if (kind.empty() || std::find(n.kinds.begin(), n.kinds.end(), kind) != n.kinds.end()) return &n;
    }
    return nullptr;
}

const std::vector<std::string>& graph_supported_kinds() {
    static const std::vector<std::string> kinds = {"mesh", "sprite", "post"};
    return kinds;
}

// ---------------------------------------------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------------------------------------------

namespace graph_detail {

// In the order they are pasted; a helper's dependencies come before it. They compile in both stages of the material shader.
const std::vector<Helper>& helpers() {
    static const std::vector<Helper> list = {
        {"gn_hash21", {}, R"(float gn_hash21(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
)"},
        {"gn_hash22", {}, R"(vec2 gn_hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}
)"},
        {"gn_value_noise", {"gn_hash21"}, R"(float gn_value_noise(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = gn_hash21(c);
    float b = gn_hash21(c + vec2(1.0, 0.0));
    float d = gn_hash21(c + vec2(0.0, 1.0));
    float e = gn_hash21(c + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(d, e, u.x), u.y);
}
)"},
        {"gn_gradient_noise", {"gn_hash22"}, R"(float gn_gradient_noise(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    vec2 g00 = gn_hash22(c) * 2.0 - 1.0;
    vec2 g10 = gn_hash22(c + vec2(1.0, 0.0)) * 2.0 - 1.0;
    vec2 g01 = gn_hash22(c + vec2(0.0, 1.0)) * 2.0 - 1.0;
    vec2 g11 = gn_hash22(c + vec2(1.0, 1.0)) * 2.0 - 1.0;
    float n = mix(mix(dot(g00, f), dot(g10, f - vec2(1.0, 0.0)), u.x),
                  mix(dot(g01, f - vec2(0.0, 1.0)), dot(g11, f - vec2(1.0, 1.0)), u.x), u.y);
    return clamp(0.5 + 0.7071 * n, 0.0, 1.0);
}
)"},
        {"gn_voronoi", {"gn_hash21", "gn_hash22"}, R"(vec3 gn_voronoi(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    float d1 = 8.0;
    float d2 = 8.0;
    float cell = 0.0;
    for (int y = -1; y <= 1; ++y) {
        for (int x = -1; x <= 1; ++x) {
            vec2 o = vec2(float(x), float(y));
            vec2 r = o + gn_hash22(c + o) - f;
            float d = dot(r, r);
            if (d < d1) {
                d2 = d1;
                d1 = d;
                cell = gn_hash21(c + o + 17.0);
            } else if (d < d2) {
                d2 = d;
            }
        }
    }
    return vec3(sqrt(d1), cell, sqrt(d2) - sqrt(d1));
}
)"},
        {"gn_fbm", {"gn_gradient_noise"}, R"(float gn_fbm(vec2 p, float octaves, float lacunarity, float gain) {
    float sum = 0.0;
    float amp = 0.5;
    float norm = 0.0;
    int count = int(clamp(octaves, 1.0, 8.0));
    for (int k = 0; k < 8; ++k) {
        if (k >= count) break;
        sum += amp * gn_gradient_noise(p);
        norm += amp;
        p = p * lacunarity + vec2(17.3, 9.1);
        amp *= gain;
    }
    return sum / norm;
}
)"},
        {"gn_dissolve_edge", {}, R"(float gn_dissolve_edge(float n, float threshold, float width) {
    float d = n - threshold;
    return step(0.0001, threshold) * step(0.0, d) * (1.0 - smoothstep(0.0, max(width, 0.0001), d));
}
)"},
        {"gn_tri_weights", {}, R"(vec3 gn_tri_weights(vec3 n, float sharpness) {
    vec3 w = pow(abs(n), vec3(max(sharpness, 0.0001)));
    return w / (w.x + w.y + w.z + 0.00001);
}
)"},
        {"gn_unpack_normal", {}, R"(vec3 gn_unpack_normal(vec4 t, float strength) {
    vec3 n = t.xyz * 2.0 - 1.0;
    return normalize(vec3(n.xy * strength, max(n.z, 0.0001)));
}
)"},
        {"gn_tangent_view", {}, R"(vec3 gn_tangent_view(vec3 viewDir, vec3 n, vec4 t) {
    vec3 tangent = normalize(t.xyz - n * dot(n, t.xyz));
    vec3 bitangent = cross(n, tangent) * t.w;
    return vec3(dot(viewDir, tangent), dot(viewDir, bitangent), dot(viewDir, n));
}
)"},
        {"gn_parallax",
         {},
         R"(vec3 gn_parallax(texture2D tex, sampler smp, vec2 uv, vec3 viewTS, float heightScale, float steps) {
    float count = clamp(steps, 4.0, 64.0);
    vec3 v = normalize(viewTS);
    vec2 shift = v.xy / max(v.z, 0.2) * heightScale;
    float layer = 1.0 / count;
    vec2 cur = uv;
    vec2 prev = uv;
    float curDepth = 0.0;
    float prevDepth = 0.0;
    float h = 1.0 - textureLod(sampler2D(tex, smp), cur, 0.0).r;
    float prevH = h;
    for (int k = 0; k < 64; ++k) {
        if (float(k) >= count || curDepth >= h) break;
        prev = cur;
        prevDepth = curDepth;
        prevH = h;
        cur -= shift * layer;
        curDepth += layer;
        h = 1.0 - textureLod(sampler2D(tex, smp), cur, 0.0).r;
    }
    float after = h - curDepth;
    float before = prevH - prevDepth;
    float w = clamp(after / (after - before - 0.00001), 0.0, 1.0);
    return vec3(mix(cur, prev, w), mix(curDepth, prevDepth, w));
}
)"},
    };
    return list;
}

}  // namespace graph_detail

std::vector<std::pair<std::string, std::string>> graph_helper_functions() {
    std::vector<std::pair<std::string, std::string>> out;
    for (const graph_detail::Helper& h : graph_detail::helpers()) out.emplace_back(h.name, h.code);
    return out;
}

}  // namespace fa
