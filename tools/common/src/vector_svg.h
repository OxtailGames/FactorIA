// The SVG document of the vector.* commands: an element tree that writes back exactly the text it read (comments, whitespace,
// attribute order and quotes included) except where an operation changed it; ids and selectors; presentation attributes with
// inheritance; transforms; the geometry of the shape elements. See vector.h.
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "vector.h"

namespace fa::vec {

struct Attr {
    std::string name, value;  // the value with its entities decoded
    std::string raw;          // the value as written; empty once the value was set again
    char quote = '"';
};

struct XNode;
struct XItem {
    std::unique_ptr<XNode> el;  // an element, or
    std::string text;           // anything else, verbatim: text, a comment, CDATA, a processing instruction
};

struct XNode {
    std::string name;  // as written, with its namespace prefix if any
    std::vector<Attr> attrs;
    std::vector<XItem> kids;
    XNode* parent = nullptr;
    bool selfClosed = false;  // written <x/> while it has no children
    std::string rawOpen;      // the start tag as written; emptied when an attribute changes, so an untouched tag is written back as it was
    int line = 1;

    std::string local() const;  // the name without a prefix
    const std::string* attr(const std::string& n) const;
    std::string attr_or(const std::string& n, const std::string& fallback = {}) const;
    void set_attr(const std::string& n, const std::string& v);
    void remove_attr(const std::string& n);
    std::vector<XNode*> elements() const;  // the element children
};

class SvgDoc {
public:
    // Reads the text. Throws CommandError ("invalid_svg", line and column, how to fix) when it is not well-formed XML with an <svg> root.
    static SvgDoc parse(const std::string& text, const std::string& what);
    std::string write() const;

    XNode* root() const { return root_.get(); }
    XNode* by_id(const std::string& id) const;
    std::vector<std::string> ids() const;
    std::vector<XNode*> all_elements() const;  // document order

    // `base`, or `base-2`, `base-3`... : an id nothing uses yet.
    std::string unique_id(const std::string& base) const;

    // The drawing space: viewBox, else the width and height attributes, else the bounds of the shapes.
    Rect canvas() const;
    // The size the SVG declares in pixels (width, height or the viewBox).
    P declared_size() const;

    // Structure edits that keep the document readable.
    XNode* insert_after(XNode* ref, std::unique_ptr<XNode> node);
    XNode* insert_before(XNode* ref, std::unique_ptr<XNode> node);
    XNode* append_child(XNode* parent, std::unique_ptr<XNode> node);
    void remove(XNode* node);
    static std::unique_ptr<XNode> clone(const XNode& n);

private:
    std::string before_, after_;
    std::unique_ptr<XNode> root_;
};

std::unique_ptr<XNode> make_element(const std::string& name);

// ---- elements -----------------------------------------------------------------------------------------------------

bool is_shape_element(const XNode& n);  // path, rect, circle, ellipse, line, polyline, polygon
bool is_group_element(const XNode& n);  // g, svg, a, switch
bool in_inert_subtree(const XNode& n);  // inside defs, clipPath, mask, pattern, symbol, marker...: not drawn where it stands

// A presentation property of the element itself: from its style attribute, else the attribute of that name. Empty when it has none.
std::string own_prop(const XNode& n, const std::string& name);
// The same with inheritance (the nearest ancestor that has it); `inherit` and `currentColor` are not resolved.
std::string inherited_prop(const XNode& n, const std::string& name);
// Sets `name` where the element already says it (its style attribute, else the attribute); a new property is an attribute.
void set_prop(XNode& n, const std::string& name, const std::string& value);
void remove_prop(XNode& n, const std::string& name);

// The transform from the element's own coordinates to the drawing space (every ancestor's transform and its own).
Mat element_ctm(const XNode& n);
// The same without the element's own transform.
Mat parent_ctm(const XNode& n);
Mat own_transform(const XNode& n);

// A length with an optional unit (px, pt, pc, mm, cm, in) as user units; false for percentages, em and what is not a number.
bool parse_length(const std::string& s, double& out);

// The local geometry of a shape element (path, rect, circle, ellipse, line, polyline, polygon). False with `why` when the element
// is not a shape or its attributes cannot be read.
bool shape_path(const XNode& n, Path& out, std::string& why);
// Makes the element a <path> with data `d`: the geometry attributes of the old element go (x, y, width, height, rx, ry, cx, cy, r,
// points, x1...), every other attribute stays.
void set_path_geometry(XNode& n, const std::string& d);

// All the drawable shapes at or below `n`, in document order, leaving the inert subtrees out.
void shapes_under(XNode& n, std::vector<XNode*>& out);

// ---- picking elements -----------------------------------------------------------------------------------------------

// An SVG id ("badge"), or a selector: `#id`, `.class`, `tag`, `[attr]`, `[attr=value]`, `*`, `:first-child`, `:last-child`,
// `:nth-child(n)`, compounds (`path.ring`), descendants (`g path`), children (`g > path`) and lists (`a, b`). A word with none of
// those characters is an id; when no element has it and it names an element (`circle`), it is the tag.
// Returns the matches in document order. Throws CommandError (with "did you mean" over the ids) when nothing matches.
std::vector<XNode*> select_elements(const SvgDoc& doc, const std::string& ref, const char* command, const std::string& pointer);

// "g#badge", "path (index 3)": for messages.
std::string describe_element(const XNode& n);

}  // namespace fa::vec
