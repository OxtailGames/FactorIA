// What the editor's Vector panel (and any tool that edits SVG by hand) needs beyond the vector.* commands (docs/VECTOR.md, "Editing by
// hand"): the nodes of a path as anchors with handles and the operations on them (the code of vector.nodes), a read-only SCENE of an
// SVG (every shape with its style, bounds, nodes and flattened outline in the drawing space) with hit tests, and the engine's own
// rasterizer for a region of the drawing. y is DOWN like SVG; every point is in the drawing space (the viewBox units) unless said
// otherwise. Nothing here writes a file: the edits are made by the commands, which call these functions.
#pragma once

#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/json.h"
#include "fa/core/types.h"
#include "fa/tooling/vector.h"

namespace fa {

// ---- nodes ---------------------------------------------------------------------------------------------------------------

// One anchor of a path with its two handles. A handle is a point (absolute, not relative to the anchor) and exists only when `hasIn` /
// `hasOut` is set; a segment between two anchors is a cubic Bezier when either end has the handle that belongs to it, else a line.
struct VecNode {
    VecPoint p;
    VecPoint in, out;
    bool hasIn = false, hasOut = false;
};
struct VecSubpath {
    std::vector<VecNode> nodes;
    bool closed = false;  // the last node connects back to the first (a segment from nodes.back() to nodes[0])
};
using VecNodePath = std::vector<VecSubpath>;

enum class VecNodeKind { Corner, Smooth, Symmetric };
enum class VecHandleLink { Auto, None, Angle, Mirror };
const char* vector_node_kind_name(VecNodeKind kind);
const char* vector_handle_link_name(VecHandleLink link);

// The nodes of SVG path data (any command: arcs and quadratics become cubics). Error: the position of the mistake and how to fix it.
Result<VecNodePath> vector_nodes_from_d(const std::string& d);
// Absolute path data, `decimals` digits after the point. A closed subpath ends in Z.
std::string vector_nodes_to_d(const VecNodePath& path, int decimals = 3);
// A node with both handles on one line through it is Smooth (Symmetric when they are as long as each other); anything else is a Corner.
VecNodeKind vector_node_kind(const VecNode& node);
int vector_node_count(const VecNodePath& path);
// The number of segments of a subpath (a closed one has as many as nodes, an open one one fewer).
int vector_segment_count(const VecSubpath& sub);
bool vector_segment_is_curve(const VecSubpath& sub, int segment);
// The point at `t` (0 to 1) of segment `segment` (from node `segment` to the next, wrapping when closed).
VecPoint vector_segment_point(const VecSubpath& sub, int segment, double t);

struct VecNearest {
    int subpath = -1, segment = -1;
    double t = 0, distance = 1e300;
    VecPoint point;
};
// The point of the path nearest to `p` (segment < 0 and distance huge when the path has no segment).
VecNearest vector_nearest_on_path(const VecNodePath& path, VecPoint p);

// The editing operations. They validate their indices and return an error that names the valid range. `index` arguments are the
// positions in the subpath's node list at the time of the call.
Result<void> vector_node_move(VecNodePath& path, int subpath, int node, VecPoint to, bool handlesFollow = true);
// Moves one handle. `link` Auto follows the node: a Smooth node keeps the other handle on the same line (its own length), a
// Symmetric node mirrors it, a Corner leaves it. Moving a handle onto its anchor removes it.
Result<void> vector_handle_move(VecNodePath& path, int subpath, int node, bool out, VecPoint to,
                                VecHandleLink link = VecHandleLink::Auto);
// Splits segment `segment` at `t` with a new node (the curve keeps its shape). Returns the new node's index.
Result<int> vector_node_insert(VecNodePath& path, int subpath, int segment, double t);
// Removes a node. keepShape rescales the handles of the neighbours so the curve stays close to what it was. A subpath left with one
// node is removed; a path left with no subpath is an error (delete the element instead).
Result<void> vector_node_delete(VecNodePath& path, int subpath, int node, bool keepShape = true);
// Corner: the handles are taken in. Smooth: the handles lie on one line (made from the neighbours when there are none). Symmetric: and
// are as long as each other.
Result<void> vector_node_convert(VecNodePath& path, int subpath, int node, VecNodeKind kind);
// Cuts a path at a node: a closed subpath becomes open there, an open one splits in two (the node is in both).
Result<void> vector_node_break(VecNodePath& path, int subpath, int node);
// Joins two ends: the last or first node of two open subpaths, or the two ends of one (which closes it). merge = one node at the
// middle of the two; else a straight segment connects them.
Result<void> vector_nodes_join(VecNodePath& path, int subpathA, int nodeA, int subpathB, int nodeB, bool merge = true);
Result<void> vector_subpath_close(VecNodePath& path, int subpath);
Result<void> vector_subpath_reverse(VecNodePath& path, int subpath);
// Adds a node at the end (or the start) of an open subpath; `subpath` == path.size() starts a new one. With `out` the node is
// smooth: its out handle is there and its in handle is the mirror image (the pen tool's drag).
Result<void> vector_node_append(VecNodePath& path, int subpath, VecPoint at, const VecPoint* out = nullptr,
                                bool atEnd = true);

// The operations of vector.nodes, in order, on `path`: [{"op": "move", "subpath": 0, "node": 2, "to": [x, y]}, ...] (docs/VECTOR.md).
Result<void> vector_nodes_apply(VecNodePath& path, const Json& ops);

// ---- the scene -----------------------------------------------------------------------------------------------------------

struct VecRect {
    double x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    double width() const { return x1 - x0; }
    double height() const { return y1 - y0; }
    VecPoint center() const { return {(x0 + x1) * 0.5, (y0 + y1) * 0.5}; }
    bool contains(VecPoint p) const { return p.x >= x0 && p.x <= x1 && p.y >= y0 && p.y <= y1; }
    bool intersects(const VecRect& o) const { return x0 <= o.x1 && o.x0 <= x1 && y0 <= o.y1 && o.y0 <= y1; }
};

// One drawable element: a shape (path, rect, circle, ellipse, line, polyline, polygon) or a group (g, a, switch).
struct VecItem {
    int index = -1;             // in VecScene::items
    int parent = -1;            // an item, or -1 for a child of the root <svg>
    int depth = 0;              // 0 for a child of the root
    std::vector<int> children;  // items, in document order
    std::string tag;            // "path", "g"...
    std::string id;             // "" when it has none
    std::string ref;  // what vector.* commands take to pick it: the id, else a selector that picks exactly this element
    bool isGroup = false;
    bool hidden = false;  // display="none" on it
    bool locked = false;  // data-locked="true" on it
    bool hiddenByAncestor = false, lockedByAncestor = false;
    std::string fill, stroke;  // the CSS value with inheritance ("" = the SVG default: black fill, no stroke)
    std::string fillRule;      // "nonzero" or "evenodd"
    double strokeWidth = 0;    // in the element's own units, with inheritance
    double opacity = 1;        // its own `opacity`
    std::string transform;     // its own transform attribute
    std::string shapeKind;     // data-fa-shape: the vector.shape kind that drew it, "" for any other element
    std::string shapeArgs;     // data-fa-args: the arguments of that kind as JSON text ("" when there is none)
    VecRect bounds;  // geometry in the drawing space (a group: the union of its shapes); empty when there is no shape
    VecRect visualBounds;  // bounds with half the stroke
    bool hasBounds = false;
    bool closed = false;  // shapes: every subpath is closed
    int nodeCount = 0;
    bool curves = false;
    VecNodePath nodes;  // shapes: the outline in the drawing space (transform applied)
    std::vector<std::vector<VecPoint>>
        rings;  // shapes: the outline flattened, one polyline per subpath (drawing space)
    std::vector<bool> ringClosed;
    std::string problem;  // a shape that could not be read: why
};

struct VecScene {
    VecRect canvas;  // the viewBox (or the size the SVG declares)
    double declaredWidth = 0, declaredHeight = 0;
    std::vector<VecItem> items;  // document order: a parent comes before its children
    int unnamed = 0;             // drawable elements with no id
    std::vector<std::string> warnings;
    int find(const std::string& ref) const;  // the item with this id or ref, -1 when none
    std::vector<int> roots() const;          // the items directly under the root <svg>
    bool is_descendant(int item, int ancestor) const;
    // The outermost group of `item` below `context` (a group, or -1 for the root): what a click selects at that level of the tree; the
    // item itself when its parent is `context`.
    int pick_in_context(int item, int context) const;
};

// Reads the SVG text. Error: the same message as the commands give for an SVG that is not well-formed.
Result<VecScene> vector_scene(const std::string& svg);

// The topmost visible, unlocked shape whose fill covers `p` or whose stroke (or, for unfilled shapes, outline) is within `tolerance` of it.
// -1 when none. Hidden and locked elements (and those inside hidden or locked groups) are skipped when `skipLocked`.
int vector_hit_test(const VecScene& scene, VecPoint p, double tolerance, bool skipLocked = true);
// Shapes whose bounds lie inside `box` (or, with `touch`, meet it), topmost last.
std::vector<int> vector_shapes_in_rect(const VecScene& scene, const VecRect& box, bool touch, bool skipLocked = true);

// ---- the picture ---------------------------------------------------------------------------------------------------------

// The SVG drawn by the engine's rasterizer (the same as assets.rasterize_svg and the previews of the vector.* commands): straight-alpha
// RGBA, transparent where nothing is drawn. `region` is the part of the drawing space to show (null = the whole canvas) and the
// picture is `width` x `height` pixels. The warnings are things the rasterizer does not draw.
Result<Image> vector_rasterize(const std::string& svg, const VecRect* region, int width, int height,
                               std::vector<std::string>* warnings = nullptr);

}  // namespace fa
