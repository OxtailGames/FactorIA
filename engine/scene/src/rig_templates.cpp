// The skeleton templates as data (rig_templates.h). Proportions are the model's bounds: x from the symmetry plane as a fraction of the width,
// y from the ground as a fraction of the height, z from the back as a fraction of the depth (front = +Z = 1).
#include "rig_templates.h"

#include <cctype>

namespace fa::rig_detail {

namespace {

std::string stem(std::string t) {
    if (t.size() > 3 && t.back() == 's' && t[t.size() - 2] != 's') t.pop_back();
    return t;
}

std::vector<std::string> split_words(const std::string& s) {
    std::vector<std::string> out;
    std::string cur;
    auto flush = [&] {
        if (!cur.empty()) out.push_back(cur);
        cur.clear();
    };
    for (std::size_t i = 0; i < s.size(); ++i) {
        const unsigned char c = static_cast<unsigned char>(s[i]);
        if (std::isalpha(c)) {
            if (std::isupper(c) && !cur.empty() && std::islower(static_cast<unsigned char>(cur.back())))
                flush();  // camelCase
            cur += char(std::tolower(c));
        } else
            flush();  // digits and punctuation separate words and are dropped
    }
    flush();
    return out;
}

std::string bone_name(const std::string& role, int index, int count, char side) {
    std::string n = role;
    if (count > 1) n += "_" + std::to_string(index);
    if (side) n += std::string("_") + side;
    return n;
}

struct Builder {
    std::vector<TBone> bones;

    TBone& add(const std::string& role, int index, int count, char side, const std::string& parent, Vec3 prop) {
        TBone b;
        b.role = role;
        b.index = count > 1 ? index : 0;
        b.side = side ? std::string(1, side) : std::string();
        b.name = bone_name(role, index, count, side);
        b.parent = parent;
        b.prop = prop;
        bones.push_back(std::move(b));
        return bones.back();
    }
    static void hint(TBone& b, const char* alternatives, char mode, float head, float tail = kNone,
                     const std::string& ref = {}) {
        std::string alts = alternatives, cur;
        auto flush = [&] {
            if (cur.empty()) return;
            Hint h;
            for (const std::string& w : split_words(cur)) h.words.push_back(stem(w));
            h.mode = mode;
            h.head = head;
            h.tail = tail;
            h.ref = ref;
            b.hints.push_back(std::move(h));
            cur.clear();
        };
        for (char c : alts) {
            if (c == '|')
                flush();
            else
                cur += c;
        }
        flush();
    }
};

// A chain of `n` bones `role_1..role_n` hanging from `parent`: the first has its own proportions, the others sit evenly between it and the
// tail of the last. The last bone's tail is the tip. Hints: the first bone's head and the last bone's tail come from a "tail" part.
void add_tail_chain(Builder& B, const std::string& role, int n, const std::string& parent, Vec3 start, Vec3 tip,
                    Vec3 tipExt, const char* words) {
    if (n <= 0) return;
    const std::string first = bone_name(role, 1, n, 0), last = bone_name(role, n, n, 0);
    for (int k = 1; k <= n; ++k) {
        TBone& b =
            B.add(role, k, n, 0, k == 1 ? parent : bone_name(role, k - 1, n, 0), k == 1 ? start : Vec3{0, 0.5f, 0.5f});
        if (k > 1) {
            b.lerpA = first;
            b.lerpB = last + ".tail";
            b.lerpT = float(k - 1) / float(n);
        }
        if (k == 1)
            Builder::hint(b, words, 'L', 0.0f, n == 1 ? 1.0f : kNone,
                          parent);  // the end nearer to the body (the parent's default head) is the base
        if (k == n) {
            b.hasTailProp = true;
            b.tailProp = tip;
            b.tailExt = tipExt;
            if (k > 1) Builder::hint(b, words, 'L', kNone, 1.0f, parent);
        }
    }
}

// arm: shoulder, upper, lower, hand with the given proportions of the given side
struct LimbProps {
    Vec3 clavicle, upper, lower, hand, handTail;
};

void add_front_limb(Builder& B, char side, const std::string& parent, const std::string& neckBase, const LimbProps& p,
                    Vec3 handExt, const char* upperWords, const char* lowerWords, const char* handWords,
                    const char* wholeWords) {
    const float sg = side == 'l' ? 1.0f : -1.0f;
    auto sgn = [&](Vec3 v) { return Vec3{v.x * sg, v.y, v.z}; };
    const std::string up = bone_name("arm_upper", 1, 1, side);
    {
        // the collar bone runs from the base of the neck towards the shoulder
        TBone& c = B.add("clavicle", 1, 1, side, parent, sgn(p.clavicle));
        c.lerpA = neckBase;
        c.lerpB = up;
        c.lerpT = 0.2f;
    }
    {
        TBone& b = B.add("arm_upper", 1, 1, side, bone_name("clavicle", 1, 1, side), sgn(p.upper));
        Builder::hint(b, upperWords, 'L', 0.0f);
        Builder::hint(b, wholeWords, 'L', 0.03f, kNone, up);
    }
    {
        TBone& b = B.add("arm_lower", 1, 1, side, up, sgn(p.lower));
        Builder::hint(b, lowerWords, 'L', 0.0f);
        Builder::hint(b, wholeWords, 'L', 0.5f, kNone, up);
    }
    {
        TBone& b = B.add("hand", 1, 1, side, bone_name("arm_lower", 1, 1, side), sgn(p.hand));
        b.hasTailProp = true;
        b.tailProp = sgn(p.handTail);
        b.tailExt = Vec3{handExt.x * sg, handExt.y, handExt.z};
        Builder::hint(b, handWords, 'L', 0.0f, 1.0f);
        Builder::hint(b, wholeWords, 'L', 0.9f, 1.0f, up);
    }
}

struct LegProps {
    Vec3 thigh, shin, foot, toe, toeTail;
};

void add_hind_limb(Builder& B, char side, const std::string& parent, const LegProps& p, bool toes, float underOffset,
                   bool underHead, const char* thighWords, const char* shinWords, const char* footWords,
                   const char* toeWords, const char* wholeWords, bool footByY) {
    const float sg = side == 'l' ? 1.0f : -1.0f;
    auto sgn = [&](Vec3 v) { return Vec3{v.x * sg, v.y, v.z}; };
    const std::string th = bone_name("thigh", 1, 1, side);
    {
        TBone& b = B.add("thigh", 1, 1, side, parent, sgn(p.thigh));
        b.under = underHead;
        b.underOffset = underOffset;
        Builder::hint(b, thighWords, 'L', 0.0f);
        Builder::hint(b, wholeWords, 'L', 0.02f, kNone, th);
    }
    {
        TBone& b = B.add("shin", 1, 1, side, th, sgn(p.shin));
        Builder::hint(b, shinWords, 'L', 0.0f);
        Builder::hint(b, wholeWords, 'L', toes ? 0.45f : 0.5f, kNone, th);
    }
    {
        TBone& b = B.add("foot", 1, 1, side, bone_name("shin", 1, 1, side), sgn(p.foot));
        if (!toes) {
            b.hasTailProp = true;
            b.tailProp = sgn(p.toeTail);
            b.tailExt = Vec3{0, -1, 0};
        }
        if (footByY)
            Builder::hint(b, footWords, 'Y', 0.75f, toes ? kNone : 0.0f);
        else
            Builder::hint(b, footWords, 'L', 0.0f, toes ? kNone : 1.0f);
        Builder::hint(b, wholeWords, 'L', footByY ? 0.93f : 0.75f, toes ? kNone : 1.0f,
                      th);  // a plain leg: the humanoid's ankle is near the floor
    }
    if (toes) {
        TBone& b = B.add("toe", 1, 1, side, bone_name("foot", 1, 1, side), sgn(p.toe));
        b.hasTailProp = true;
        b.tailProp = sgn(p.toeTail);
        b.tailExt = Vec3{0, -1, 0};
        Builder::hint(b, toeWords, 'L', 0.0f, 1.0f);
        if (footByY) Builder::hint(b, footWords, 'Z', 0.7f, 1.0f);
        Builder::hint(b, wholeWords, 'L', footByY ? 0.975f : 0.93f, 1.0f, th);
    }
}

void add_chain_bones(Builder& B, const RigDoc& doc, const char* role, const char* words) {
    const int n = doc.optionInt("segments", 5);
    B.add("root", 1, 1, 0, "", Vec3{0, 0, 0.5f});
    for (int k = 1; k <= n; ++k) {
        TBone& b = B.add(role, k, n, 0, k == 1 ? "root" : bone_name(role, k - 1, n, 0), Vec3{0, 0.5f, 0.5f});
        Builder::hint(
            b, words, 'L',
            0.0f);  // the chain's region is decided by the fit; these only record that a part of that name is used
    }
}

std::vector<TBone> humanoid(const RigDoc& doc, bool armsOut) {
    Builder B;
    const int Ns = doc.optionInt("spine", 3), Nn = doc.optionInt("neck", 1), Nt = doc.optionInt("tail", 0);
    const bool toes = doc.optionBool("toes", true);
    {
        TBone& r = B.add("root", 1, 1, 0, "", Vec3{0, 0.52f, 0.5f});
        r.under = true;
        r.underOffset = 0.04f;
        Builder::hint(r, "pelvis|hip|waist", 'Y', 0.5f);
        Builder::hint(r, "torso|body|chest|trunk|spine", 'Y', 0.12f);
    }
    const std::string neck1 = bone_name("neck", 1, Nn, 0);
    for (int k = 1; k <= Ns; ++k) {
        TBone& b = B.add("spine", k, Ns, 0, k == 1 ? "root" : bone_name("spine", k - 1, Ns, 0), Vec3{0, 0.6f, 0.5f});
        b.lerpA = "root";
        b.lerpB = neck1;
        b.lerpT = float(k) / float(Ns + 1);
    }
    const std::string lastSpine = bone_name("spine", Ns, Ns, 0);
    for (int k = 1; k <= Nn; ++k) {
        TBone& b = B.add("neck", k, Nn, 0, k == 1 ? lastSpine : bone_name("neck", k - 1, Nn, 0), Vec3{0, 0.83f, 0.5f});
        if (k == 1) {
            Builder::hint(b, "neck", 'Y', 0.0f);
            Builder::hint(b, "torso|body|chest|trunk", 'Y', 0.98f);
        } else {
            b.lerpA = neck1;
            b.lerpB = "head";
            b.lerpT = float(k - 1) / float(Nn);
        }
    }
    {
        TBone& h = B.add("head", 1, 1, 0, bone_name("neck", Nn, Nn, 0), Vec3{0, 0.87f, 0.5f});
        h.hasTailProp = true;
        h.tailProp = Vec3{0, 1.0f, 0.5f};
        h.tailExt = Vec3{0, 1, 0};
        Builder::hint(h, "head|skull|face|helmet|hat", 'Y', 0.0f, 1.0f);
    }
    const std::string armParent = lastSpine;
    LimbProps arm = armsOut ? LimbProps{{0.06f, 0.83f, 0.5f},
                                        {0.13f, 0.82f, 0.5f},
                                        {0.28f, 0.82f, 0.5f},
                                        {0.42f, 0.82f, 0.5f},
                                        {0.5f, 0.82f, 0.5f}}
                            : LimbProps{{0.08f, 0.83f, 0.5f},
                                        {0.27f, 0.82f, 0.5f},
                                        {0.42f, 0.62f, 0.5f},
                                        {0.42f, 0.46f, 0.5f},
                                        {0.42f, 0.37f, 0.5f}};
    for (char s : {'l', 'r'})
        add_front_limb(B, s, armParent, neck1, arm, armsOut ? Vec3{1, 0, 0} : Vec3{0, 0, 0}, "upper arm|bicep|humerus",
                       "forearm|lower arm", "hand|fist|palm", "arm");
    LegProps leg{{0.22f, 0.50f, 0.5f},
                 {0.22f, 0.27f, 0.52f},
                 {0.22f, 0.05f, 0.46f},
                 {0.22f, 0.02f, 0.62f},
                 {0.22f, 0.0f, 0.72f}};
    for (char s : {'l', 'r'})
        add_hind_limb(B, s, "root", leg, toes, 0.02f, true, "thigh|upper leg", "shin|calf|lower leg", "foot|feet|ankle",
                      "toe", "leg", true);
    // the shin sits half way between the hip and the ankle unless a part says otherwise
    for (TBone& b : B.bones)
        if (b.role == "shin") {
            b.lerpA = bone_name("thigh", 1, 1, b.side[0]);
            b.lerpB = bone_name("foot", 1, 1, b.side[0]);
            b.lerpT = 0.5f;
        }
    add_tail_chain(B, "tail", Nt, "root", Vec3{0, 0.48f, 0.42f}, Vec3{0, 0.3f, 0.02f}, Vec3{0, 0, -1}, "tail");
    return B.bones;
}

std::vector<TBone> quadruped(const RigDoc& doc) {
    Builder B;
    const int Ns = doc.optionInt("spine", 3), Nn = doc.optionInt("neck", 2), Nt = doc.optionInt("tail", 4);
    {
        TBone& r = B.add("root", 1, 1, 0, "", Vec3{0, 0.6f, Nt > 0 ? 0.3f : 0.12f});
        Builder::hint(r, "pelvis|hip|rump|haunch", 'Y', 0.5f);
        Builder::hint(r, "body|torso|trunk|barrel", 'Z', 0.2f);
    }
    const std::string neck1 = bone_name("neck", 1, Nn, 0);
    for (int k = 1; k <= Ns; ++k) {
        TBone& b = B.add("spine", k, Ns, 0, k == 1 ? "root" : bone_name("spine", k - 1, Ns, 0), Vec3{0, 0.62f, 0.5f});
        b.lerpA = "root";
        b.lerpB = neck1;
        b.lerpT = float(k) / float(Ns + 1);
    }
    const std::string lastSpine = bone_name("spine", Ns, Ns, 0);
    for (int k = 1; k <= Nn; ++k) {
        TBone& b = B.add("neck", k, Nn, 0, k == 1 ? lastSpine : bone_name("neck", k - 1, Nn, 0), Vec3{0, 0.64f, 0.7f});
        if (k == 1) {
            Builder::hint(b, "neck", 'L', 0.0f);
            Builder::hint(b, "body|torso|trunk|barrel", 'Z', 0.88f);
        } else {
            b.lerpA = neck1;
            b.lerpB = "head";
            b.lerpT = float(k - 1) / float(Nn);
        }
    }
    {
        TBone& h = B.add("head", 1, 1, 0, bone_name("neck", Nn, Nn, 0), Vec3{0, 0.8f, 0.84f});
        h.hasTailProp = true;
        h.tailProp = Vec3{0, 0.74f, 1.0f};
        h.tailExt = Vec3{0, 0, 1};
        Builder::hint(h, "snout|muzzle|nose", 'L', kNone, 1.0f);
        Builder::hint(h, "head|skull|face", 'L', 0.0f, 1.0f);
    }
    LimbProps front{{0.08f, 0.62f, 0.68f},
                    {0.16f, 0.58f, 0.7f},
                    {0.16f, 0.38f, 0.68f},
                    {0.16f, 0.18f, 0.72f},
                    {0.16f, 0.0f, 0.78f}};
    for (char s : {'l', 'r'})
        add_front_limb(B, s, lastSpine, neck1, front, Vec3{0, -1, 0}, "upper arm|upper foreleg|shoulder",
                       "forearm|lower foreleg", "hand|front paw|front hoof|forepaw",
                       "foreleg|fore leg|front leg|forelimb");
    LegProps hind{
        {0.16f, 0.56f, 0.2f}, {0.16f, 0.36f, 0.27f}, {0.16f, 0.18f, 0.14f}, {0.16f, 0.04f, 0.2f}, {0.16f, 0.0f, 0.26f}};
    for (char s : {'l', 'r'})
        add_hind_limb(B, s, "root", hind, true, 0, false, "thigh|upper leg", "shin|lower leg|stifle",
                      "foot|hock|metatarsus", "toe|hind paw|hind hoof|hindpaw|rear paw|back paw",
                      "hind leg|hindleg|back leg|rear leg|leg", false);
    add_tail_chain(B, "tail", Nt, "root", Vec3{0, 0.62f, 0.14f}, Vec3{0, 0.4f, 0.0f}, Vec3{0, 0, -1}, "tail");
    return B.bones;
}

std::vector<TBone> bird(const RigDoc& doc, bool spread) {
    Builder B;
    const int Ns = doc.optionInt("spine", 2), Nn = doc.optionInt("neck", 3), Nt = doc.optionInt("tail", 2);
    {
        TBone& r = B.add("root", 1, 1, 0, "", Vec3{0, 0.42f, 0.4f});
        Builder::hint(r, "pelvis|hip", 'Y', 0.5f);
        Builder::hint(r, "body|torso|trunk|breast|chest", 'Z', 0.35f);
    }
    const std::string neck1 = bone_name("neck", 1, Nn, 0);
    for (int k = 1; k <= Ns; ++k) {
        TBone& b = B.add("spine", k, Ns, 0, k == 1 ? "root" : bone_name("spine", k - 1, Ns, 0), Vec3{0, 0.5f, 0.5f});
        b.lerpA = "root";
        b.lerpB = neck1;
        b.lerpT = float(k) / float(Ns + 1);
    }
    const std::string lastSpine = bone_name("spine", Ns, Ns, 0);
    for (int k = 1; k <= Nn; ++k) {
        TBone& b = B.add("neck", k, Nn, 0, k == 1 ? lastSpine : bone_name("neck", k - 1, Nn, 0), Vec3{0, 0.58f, 0.62f});
        if (k == 1) {
            Builder::hint(b, "neck", 'L', 0.0f);
            Builder::hint(b, "body|torso|trunk|breast|chest", 'Z', 0.8f);
        } else {
            b.lerpA = neck1;
            b.lerpB = "head";
            b.lerpT = float(k - 1) / float(Nn);
        }
    }
    {
        TBone& h = B.add("head", 1, 1, 0, bone_name("neck", Nn, Nn, 0), Vec3{0, 0.9f, 0.74f});
        h.hasTailProp = true;
        h.tailProp = Vec3{0, 0.86f, 1.0f};
        h.tailExt = Vec3{0, 0, 1};
        Builder::hint(h, "beak|bill", 'L', kNone, 1.0f);
        Builder::hint(h, "head|skull", 'L', 0.0f, 1.0f);
    }
    LimbProps wing = spread ? LimbProps{{0.04f, 0.6f, 0.5f},
                                        {0.12f, 0.62f, 0.48f},
                                        {0.3f, 0.62f, 0.46f},
                                        {0.44f, 0.62f, 0.44f},
                                        {0.5f, 0.62f, 0.42f}}
                            : LimbProps{{0.05f, 0.6f, 0.52f},
                                        {0.14f, 0.6f, 0.5f},
                                        {0.17f, 0.56f, 0.34f},
                                        {0.17f, 0.52f, 0.18f},
                                        {0.17f, 0.5f, 0.04f}};
    for (char s : {'l', 'r'})
        add_front_limb(B, s, lastSpine, neck1, wing, spread ? Vec3{1, 0, 0} : Vec3{0, 0, 0},
                       "upper wing|humerus|upper arm", "forewing|forearm|lower wing", "hand|primaries|wingtip|wing tip",
                       "wing");
    LegProps leg{
        {0.1f, 0.38f, 0.42f}, {0.1f, 0.24f, 0.45f}, {0.1f, 0.1f, 0.42f}, {0.1f, 0.015f, 0.5f}, {0.1f, 0.0f, 0.6f}};
    for (char s : {'l', 'r'})
        add_hind_limb(B, s, "root", leg, true, 0, false, "thigh|upper leg", "shin|tibia|lower leg", "foot|tarsus|ankle",
                      "toe|claw|talon", "leg", false);
    add_tail_chain(B, "tail", Nt, "root", Vec3{0, 0.42f, 0.2f}, Vec3{0, 0.3f, 0.0f}, Vec3{0, 0, -1}, "tail");
    return B.bones;
}

std::vector<TBone> generic(const RigDoc& doc) {
    Builder B;
    {
        TBone& r = B.add("root", 1, 1, 0, "", Vec3{0, 0, 0.5f});
        r.hasAbs = false;  // the fit puts it at the bottom centre of the model
    }
    for (const RigGenericBone& g : doc.bones) {
        TBone b;
        b.name = g.name;
        b.role = g.role.empty() ? g.name : g.role;
        b.parent = g.parent.empty() ? "root" : g.parent;
        b.prop = Vec3{0, 0.5f, 0.5f};
        if (!g.part.empty()) {
            Hint h;
            h.exact = g.part;
            h.mode = 'A';
            h.head = 0;
            h.tail = 1;
            h.aHead = g.anchor;
            h.aTail = g.tailAnchor ? *g.tailAnchor
                                   : (g.anchor.x == 0 && g.anchor.y == 0 && g.anchor.z == 0
                                          ? Vec3{0, 1, 0}
                                          : Vec3{-g.anchor.x, -g.anchor.y, -g.anchor.z});
            b.hints.push_back(h);
        }
        B.bones.push_back(std::move(b));
    }
    return B.bones;
}

}  // namespace

std::vector<std::string> name_tokens(const std::string& name, char* side) {
    std::vector<std::string> out;
    char s = 0;
    for (const std::string& w : split_words(name)) {
        if (w == "l" || w == "left")
            s = 'l';
        else if (w == "r" || w == "right")
            s = 'r';
        else
            out.push_back(stem(w));
    }
    if (side) *side = s;
    return out;
}

std::vector<TBone> build_template(const RigDoc& doc, bool armsOut, bool wingsSpread) {
    std::vector<TBone> bones;
    if (doc.templateName == "humanoid")
        bones = humanoid(doc, armsOut);
    else if (doc.templateName == "quadruped")
        bones = quadruped(doc);
    else if (doc.templateName == "bird")
        bones = bird(doc, wingsSpread);
    else if (doc.templateName == "tail" || doc.templateName == "chain") {
        Builder B;
        add_chain_bones(B, doc, doc.templateName == "tail" ? "tail" : "chain",
                        doc.templateName == "tail" ? "tail|tentacle|antenna|whip" : "chain|rope|cable|link");
        bones = B.bones;
    } else
        bones = generic(doc);
    return bones;
}

}  // namespace fa::rig_detail
