"""Writes skinned_two_bone.gltf: a square column (3 rings of 4 vertices at y = 0, 1, 2) skinned to two bones.

Bone "Root" (joint 0) sits at the origin, bone "Tip" (joint 1) is its child at y = 1 (inverse bind = translate(0,-1,0)).
Ring 0 is weighted to Root, ring 1 half and half, ring 2 to Tip. Clips (buffer embedded as base64):
  Bend    LINEAR rotation of Tip about Z, 0 -> 90 degrees over 1 s.
  Slide   STEP translation of Root: x = 0 (t 0), 1 (t 0.5), 2 (t 1).
  Spline  CUBICSPLINE translation of Tip from (0,1,0) to (0,2,0) over 1 s, out tangent of key 0 = (1,0,0).
Run: python make_skinned_two_bone.py  (the scene tests check the numbers against hand-computed values).
"""
import base64, json, math, struct, pathlib

pos, jnt, wgt = [], [], []
for ring, y in enumerate((0.0, 1.0, 2.0)):
    for x, z in ((-.25, -.25), (.25, -.25), (.25, .25), (-.25, .25)):
        pos.append((x, y, z))
        jnt.append((0, 0, 0, 0) if ring == 0 else (0, 1, 0, 0) if ring == 1 else (1, 0, 0, 0))
        wgt.append((1, 0, 0, 0) if ring != 1 else (.5, .5, 0, 0))
idx = []
for r in range(2):
    for i in range(4):
        a, b = r * 4 + i, r * 4 + (i + 1) % 4
        c, d = a + 4, b + 4
        idx += [a, b, d, a, d, c]

s = math.sqrt(.5)
blob = bytearray()
views = []


def add(data, target=None):
    while len(blob) % 4:
        blob.append(0)
    views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(data), **({"target": target} if target else {})})
    blob.extend(data)
    return len(views) - 1


accessors = []


def acc(view, ctype, count, typ, **kw):
    accessors.append({"bufferView": view, "componentType": ctype, "count": count, "type": typ, **kw})
    return len(accessors) - 1


def f(*v):
    return struct.pack("<%df" % len(v), *v)


pa = acc(add(b"".join(struct.pack("<3f", *p) for p in pos), 34962), 5126, 12, "VEC3", min=[-.25, 0, -.25], max=[.25, 2, .25])
ja = acc(add(b"".join(struct.pack("<4B", *j) for j in jnt), 34962), 5121, 12, "VEC4")
wa = acc(add(b"".join(struct.pack("<4f", *w) for w in wgt), 34962), 5126, 12, "VEC4")
ia = acc(add(b"".join(struct.pack("<H", i) for i in idx), 34963), 5123, len(idx), "SCALAR")
ibm = acc(add(f(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) + f(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, -1, 0, 1)), 5126, 2, "MAT4")
t01 = acc(add(f(0, 1)), 5126, 2, "SCALAR", min=[0], max=[1])
bend = acc(add(f(0, 0, 0, 1, 0, 0, s, s)), 5126, 2, "VEC4")
t3 = acc(add(f(0, .5, 1)), 5126, 3, "SCALAR", min=[0], max=[1])
slide = acc(add(f(0, 0, 0, 1, 0, 0, 2, 0, 0)), 5126, 3, "VEC3")
# cubic spline output: (in tangent, value, out tangent) per key
spl = acc(add(f(0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0)), 5126, 6, "VEC3")

gltf = {
    "asset": {"version": "2.0", "generator": "make_skinned_two_bone.py"},
    "scene": 0, "scenes": [{"nodes": [0, 1]}],
    "nodes": [{"name": "Column", "mesh": 0, "skin": 0},
              {"name": "Root", "children": [2]},
              {"name": "Tip", "translation": [0, 1, 0]}],
    "meshes": [{"name": "Column", "primitives": [{"attributes": {"POSITION": pa, "JOINTS_0": ja, "WEIGHTS_0": wa}, "indices": ia}]}],
    "skins": [{"name": "Rig", "joints": [1, 2], "inverseBindMatrices": ibm, "skeleton": 1}],
    "animations": [
        {"name": "Bend", "samplers": [{"input": t01, "output": bend, "interpolation": "LINEAR"}],
         "channels": [{"sampler": 0, "target": {"node": 2, "path": "rotation"}}]},
        {"name": "Slide", "samplers": [{"input": t3, "output": slide, "interpolation": "STEP"}],
         "channels": [{"sampler": 0, "target": {"node": 1, "path": "translation"}}]},
        {"name": "Spline", "samplers": [{"input": t01, "output": spl, "interpolation": "CUBICSPLINE"}],
         "channels": [{"sampler": 0, "target": {"node": 2, "path": "translation"}}]},
    ],
    "bufferViews": views, "accessors": accessors,
    "buffers": [{"byteLength": len(blob), "uri": "data:application/octet-stream;base64," + base64.b64encode(bytes(blob)).decode()}],
}
out = pathlib.Path(__file__).with_name("skinned_two_bone.gltf")
out.write_text(json.dumps(gltf, indent=1))
print("wrote", out)
