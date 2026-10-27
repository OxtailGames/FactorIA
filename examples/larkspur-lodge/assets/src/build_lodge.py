#!/usr/bin/env python3
"""Builds the lodge's area scenes (scenes/ground, upstairs, cellar, test_room) from the layouts below.

Run it from anywhere:  python3 assets/src/build_lodge.py [area ...]

The layouts are the source of truth for the walls, floors, furniture, lights, spawn points and interactable objects; the
scenes are what the engine reads. Edit a layout here and run the script again, never edit the generated scenes by hand
(they say so in a comment-free way: every wall and floor entity id starts with `w_`, `f_`, every prop with `p_`).
Only the Python standard library is used. Measures are metres; one grid cell is 2 m (the Kenney Furniture Kit's wall is
1 unit wide and 1.29 high, drawn at scale 2).
"""
import json
import math
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.normpath(os.path.join(HERE, "..", ".."))
MODELS = "assets/models/lodge/"
T = 2.0  # metres per cell
VIEW = "--view" in sys.argv
WALL_H = 1.29 * 2
PORTER = "assets/models/characters/character-b.glb"

# ------------------------------------------------------------------------------------------------- model measures
_bounds_cache = {}


def _mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def _node_matrix(nd):
    t = nd.get("translation", [0, 0, 0])
    s = nd.get("scale", [1, 1, 1])
    x, y, z, w = nd.get("rotation", [0, 0, 0, 1])
    r = [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)],
    ]
    return [[r[i][j] * s[j] for j in range(3)] + [t[i]] for i in range(3)] + [[0, 0, 0, 1]]


def model_bounds(name):
    """(min, max) of a model of the kit in its own units, node transforms applied."""
    if name in _bounds_cache:
        return _bounds_cache[name]
    data = open(os.path.join(PROJECT, MODELS, name + ".glb"), "rb").read()
    n = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + n])
    lo = [1e9] * 3
    hi = [-1e9] * 3

    def walk(idx, parent):
        nd = j["nodes"][idx]
        m = _mat_mul(parent, _node_matrix(nd))
        if "mesh" in nd:
            for pr in j["meshes"][nd["mesh"]]["primitives"]:
                a = j["accessors"][pr["attributes"]["POSITION"]]
                for cx in (a["min"][0], a["max"][0]):
                    for cy in (a["min"][1], a["max"][1]):
                        for cz in (a["min"][2], a["max"][2]):
                            for i in range(3):
                                v = m[i][0] * cx + m[i][1] * cy + m[i][2] * cz + m[i][3]
                                lo[i] = min(lo[i], v)
                                hi[i] = max(hi[i], v)
        for c in nd.get("children", []):
            walk(c, m)

    ident = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
    for root in j["scenes"][j.get("scene", 0)]["nodes"]:
        walk(root, ident)
    _bounds_cache[name] = (lo, hi)
    return lo, hi


def rnd(v):
    return round(v + 0.0, 3)


def vec(v):
    return [rnd(x) for x in v]


# ------------------------------------------------------------------------------------------------------ the area
class Area:
    def __init__(self, name, title_key, tint, floor_tints, moon=True, ambient=(0.26, 0.28, 0.38), fog=None):
        self.name = name
        self.title_key = title_key
        self.tint = tint
        self.floor_tints = floor_tints
        self.moon = moon
        self.ambient = ambient
        self.rooms = {}
        self.openings = {}  # edge key -> kind
        self.windows = set()
        self.ents = []
        self.counts = {}
        self.min_x = self.min_z = 1e9
        self.max_x = self.max_z = -1e9
        self.interactables = {}
        self.doors = {}
        self.lights = []
        self.spawns = {}
        self.preload = []

    def uid(self, base):
        n = self.counts.get(base, 0)
        self.counts[base] = n + 1
        return "%s_%d" % (base, n) if n else base

    def add(self, e):
        self.ents.append(e)
        return e

    # ---- rooms and walls
    def room(self, name, c0, r0, c1, r1, floor=None):
        self.rooms[name] = (c0, r0, c1, r1, floor or name)
        self.min_x = min(self.min_x, c0 * T)
        self.min_z = min(self.min_z, r0 * T)
        self.max_x = max(self.max_x, c1 * T)
        self.max_z = max(self.max_z, r1 * T)

    def opening(self, kind, key):
        self.openings[key] = kind

    def build_structure(self):
        owners = {}
        for name, (c0, r0, c1, r1, _f) in self.rooms.items():
            for c in range(c0, c1):
                for r in (r0, r1):
                    owners.setdefault(("h", c, r), []).append(name)
            for r in range(r0, r1):
                for c in (c0, c1):
                    owners.setdefault(("v", c, r), []).append(name)
        # floors
        for name, (c0, r0, c1, r1, floor) in self.rooms.items():
            w, d = (c1 - c0) * T, (r1 - r0) * T
            tint = self.floor_tints.get(floor, [0.5, 0.4, 0.3, 1])
            self.add({
                "id": "f_" + name,
                "components": {
                    "Transform": {"position": [c0 * T, -0.05, r1 * T], "scale": [w, 1, d]},
                    "MeshRenderer": {"mesh": MODELS + "floorFull.glb", "color": tint, "castShadows": False},
                    "Collider3D": {"shape": "box", "size": [1, 0.5, 1], "offset": [0.5, -0.2, -0.5], "layer": 0, "friction": 0.8},
                },
            })
        # wall runs
        for orient in ("h", "v"):
            lines = {}
            for (o, c, r), own in owners.items():
                if o != orient:
                    continue
                line, pos = (r, c) if o == "h" else (c, r)
                lines.setdefault(line, {})[pos] = own
            for line, cells in sorted(lines.items()):
                run = []
                for pos in sorted(cells):
                    key = (orient, pos, line) if orient == "h" else (orient, line, pos)
                    kind = self.openings.get(key)
                    if kind == "open":
                        self.flush(orient, line, run)
                        run = []
                        continue
                    exterior = len(cells[pos]) == 1
                    if kind or key in self.windows:
                        self.flush(orient, line, run)
                        run = []
                        self.piece(orient, line, pos, kind or "window", exterior)
                        continue
                    if run and (pos != run[-1][0] + 1 or run[-1][2] != exterior):
                        self.flush(orient, line, run)
                        run = []
                    run.append((pos, key, exterior))
                    if len(run) == 2:
                        self.flush(orient, line, run)
                        run = []
                self.flush(orient, line, run)

    def wall_ent(self, base, orient, line, pos, n, model, collider, exterior, extra=None):
        """One entity for n cells of wall starting at cell `pos` of the line (grid line `line`)."""
        pad = 0.05 if model.endswith("/wall.glb") else 0.0
        length = n * T + 2 * pad
        if orient == "h":
            position = [pos * T - pad, 0, line * T + 0.05]
            rot = [0, 0, 0]
        else:
            position = [line * T + 0.05, 0, (pos + n) * T + pad]
            rot = [0, 90, 0]
        comps = {
            "Transform": {"position": vec(position), "rotation": rot, "scale": [rnd(length / 1.0), 2, 2]},
            "MeshRenderer": {"mesh": model, "color": self.tint},
            "Collider3D": collider,
        }
        comps["Collider3D"]["layer"] = 3 if exterior else 1  # 3: outside walls (the camera stops at them and they fade); 1: inside walls (fade)
        ent = {"id": self.uid(base), "tags": ["wall", "fade"], "components": comps}
        if extra:
            ent.update(extra)
        return self.add(ent)

    def flush(self, orient, line, run):
        if not run:
            return
        pos0 = run[0][0]
        n = len(run)
        exterior = run[0][2]
        box = {"shape": "box", "size": [1, 1.29, 0.125], "offset": [0.5, 0.645, -0.025]}
        self.wall_ent("w_" + ("n" if orient == "h" else "e"), orient, line, pos0, n, MODELS + "wall.glb", box, exterior)

    def piece(self, orient, line, pos, kind, exterior):
        if kind == "window":
            box = {"shape": "box", "size": [1, 1.29, 0.125], "offset": [0.5, 0.645, -0.025]}
            self.wall_ent("w_window", orient, line, pos, 1, MODELS + "wallWindow.glb", box, exterior)
            return
        model = MODELS + ("wallDoorwayWide.glb" if kind == "arch" else "wallDoorway.glb")
        col = {"shape": "mesh", "mesh": model}
        self.wall_ent("w_arch" if kind == "arch" else "w_doorway", orient, line, pos, 1, model, col, exterior)

    def cell_centre(self, orient, line, pos):
        """World centre (x, z) of the unit edge."""
        if orient == "h":
            return pos * T + T / 2, line * T
        return line * T, pos * T + T / 2

    # ---- props
    def place(self, model, cx, cz, rot=0, s=2.0, y=0.0, collide=True, layer=2, fade=False, tags=None, color=None,
              script=None, ident=None, emissive=None):
        """A piece of furniture whose footprint centre is at (cx, cz). rot 0 faces +z (south), 90 faces +x, 180 -z, 270 -x."""
        lo, hi = model_bounds(model)
        if model.startswith("rug") and not color:
            color = RUG_TINTS[sum(map(ord, model)) % len(RUG_TINTS)]
        lc = [(lo[0] + hi[0]) / 2, (lo[2] + hi[2]) / 2]
        a = math.radians(rot)
        ox = lc[0] * s * math.cos(a) + lc[1] * s * math.sin(a)
        oz = -lc[0] * s * math.sin(a) + lc[1] * s * math.cos(a)
        comps = {
            "Transform": {"position": [rnd(cx - ox), rnd(y), rnd(cz - oz)], "rotation": [0, rot, 0], "scale": [s, s, s]},
            "MeshRenderer": {"mesh": MODELS + model + ".glb"},
        }
        if color:
            comps["MeshRenderer"]["color"] = color
        h = (hi[1] - lo[1]) * s
        if (collide and h > 0.12) or script:
            # an object the player can use always has a collider: a click or a tap finds it with a ray
            thin = max(0.0, 0.3 / s - (hi[1] - lo[1]))
            comps["Collider3D"] = {
                "shape": "box",
                "size": vec([hi[0] - lo[0], hi[1] - lo[1] + thin, hi[2] - lo[2]]),
                "offset": vec([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2 + thin / 2, (lo[2] + hi[2]) / 2]),
                "layer": 1 if fade else layer,
            }
        ent = {"id": self.uid(ident or "p_" + model), "tags": list(tags or []) + (["fade"] if fade else []), "components": comps}
        if script:
            comps["Script"] = {"path": "scripts/interactable.js", "props": dict(script, point=[rnd(cx), rnd(cz)])}
            ent["tags"].append("interactable")
        self.add(ent)
        return ent

    def size(self, model, s=2.0, rot=0):
        lo, hi = model_bounds(model)
        w, d = (hi[0] - lo[0]) * s, (hi[2] - lo[2]) * s
        if rot % 180:
            w, d = d, w
        return w, d, (hi[1] - lo[1]) * s

    def row(self, models, x, z, dx, dz, rot, s=2.0, gap=0.0, **kw):
        """Places models one after the other starting at (x, z) (the first one's near edge) going along (dx, dz)."""
        for m in models:
            if isinstance(m, tuple):
                m, extra = m
            else:
                extra = {}
            w, d, _h = self.size(m, s, rot)
            span = w if dx else d
            cx = x + dx * span / 2
            cz = z + dz * span / 2
            args = dict(kw)
            args.update(extra)
            self.place(m, cx, cz, rot, s, **args)
            x += dx * (span + gap)
            z += dz * (span + gap)
        return x, z

    def light(self, x, y, z, color=(1.0, 0.72, 0.42), intensity=1.0, rng=8.0, ident=None):
        self.add({"id": self.uid(ident or "light"), "components": {
            "Transform": {"position": [rnd(x), rnd(y), rnd(z)]},
            "Light": {"type": "point", "color": list(color) + [1], "intensity": intensity, "range": rng},
        }})

    def spawn(self, ident, x, z, yaw=0.0):
        self.spawns[ident] = (x, z, yaw)
        self.add({"id": ident, "tags": ["spawn"], "components": {"Transform": {"position": [rnd(x), 0.95, rnd(z)], "rotation": [0, yaw, 0]}}})

    def door_leaf(self, ident, orient, line, pos, props):
        """The closed door in a narrow doorway piece (an interactable that opens or changes area)."""
        cx, cz = self.cell_centre(orient, line, pos)
        rot = 0 if orient == "h" else 90
        lo, hi = model_bounds("doorway")
        w, d = hi[0] - lo[0], hi[2] - lo[2]
        # the leaf's origin is its lower left corner: centre it on the opening, in the wall's plane
        a = math.radians(rot)
        lx, lz = -(lo[0] + w / 2) * 2, -((lo[2] + hi[2]) / 2) * 2
        ox = lx * math.cos(a) + lz * math.sin(a)
        oz = -lx * math.sin(a) + lz * math.cos(a)
        comps = {
            "Transform": {"position": [rnd(cx + ox), 0, rnd(cz + oz + (0 if orient == "h" else 0))], "rotation": [0, rot, 0], "scale": [2, 2, 2]},
            "MeshRenderer": {"mesh": MODELS + "doorway.glb"},
            "Collider3D": {"shape": "box", "size": [0.5, 1.01, 0.12], "offset": [0.245, 0.505, -0.01], "layer": 1, "navObstacle": True},
            "Script": {"path": "scripts/interactable.js", "props": dict(props, kind="area" if "area" in props else "door", point=[rnd(cx), rnd(cz)])},
        }
        self.add({"id": ident, "tags": ["interactable", "fade", "door"], "components": comps})

    def stairs(self, ident, cx, cz, rot, props, s=1.7):
        self.place("stairs", cx, cz, rot, s, ident=ident, layer=1, fade=True, script=dict(props, kind="area"))

    # ---- output
    def finish(self, porter_spawn, extra_ents=()):
        w = self.max_x - self.min_x + 6
        d = self.max_z - self.min_z + 6
        cx = (self.min_x + self.max_x) / 2
        cz = (self.min_z + self.max_z) / 2
        out = [{"id": "hud", "prefab": "prefabs/ui/hud.prefab.json"}]  # first: area.js and the porter call it from their onStart
        if self.moon:
            out.append({"id": "moon", "components": {
                "Transform": {"position": [cx, 12, cz], "rotation": [-52, 28, 0]},
                "Light": {"type": "directional", "color": [0.55, 0.66, 1.0, 1], "intensity": 0.55, "castShadows": True},
            }})
        out.append({"id": "navmesh", "components": {
            "Transform": {"position": [rnd(cx), 1.5, rnd(cz)]},
            "NavMesh3D": {"size": [rnd(w), 4, rnd(d)], "agentRadius": 0.3, "agentHeight": 1.75, "stepHeight": 0.3, "cellSize": 0.2},
        }})
        out.append({"id": "camera", "components": {
            "Transform": {"position": [rnd(porter_spawn[0]), 6, rnd(porter_spawn[1] + 6)], "rotation": [-35, 0, 0]},
            "Camera": {"projection": "perspective", "fov": 52, "nearPlane": 0.1, "farPlane": 120, "primary": True,
                       "clearColor": [0.03, 0.04, 0.08, 1]},
            "Script": {"path": "scripts/lodge_camera.js"},
        }})
        out.append({"id": "porter", "tags": ["porter"], "components": {
            "Transform": {"position": [rnd(porter_spawn[0]), 0.95, rnd(porter_spawn[1])]},
            "CharacterController3D": {"radius": 0.3, "height": 1.75, "center": [0, 0, 0], "stepOffset": 0.3, "slopeLimit": 45},
            "Script": {"path": "scripts/porter.js"},
        }, "children": [{"id": "porter_model", "components": {
            "Transform": {"position": [0, -0.875, 0], "rotation": [0, 180, 0], "scale": [0.7, 0.7, 0.7]},
            "MeshRenderer": {"mesh": PORTER, "castShadows": True, "emissive": [0.1, 0.09, 0.09]},  # a little self-light: he must read in the dark cellar
            "Animator": PORTER_ANIMATOR,
        }}]})
        out.append({"id": "area", "components": {"Script": {"path": "scripts/area.js", "props": {
            "area": self.name, "titleKey": self.title_key, "preload": self.preload}}}})
        out.append({"id": "pause_menu", "components": {"Script": {"path": "scripts/pause_menu.js"}}})
        out.append({"id": "dialogue", "components": {"Script": {"path": "scripts/dialogue_view.js"}}})  # the dialogue box (spawns its own UI)
        if self.name in STORY_AREAS:  # the people of the night and the chapters live in the areas the story walks through
            out.append({"id": "cast", "components": {"Script": {"path": "scripts/cast.js", "props": {"area": self.name}}}})
            out.append({"id": "chapters", "components": {"Script": {"path": "scripts/chapters.js"}}})
        scene = {
            "format": "factoria.scene/1",
            "settings": {"ambientLight": list(self.ambient) + [1], "skyColor": [0.02, 0.03, 0.07, 1], "horizonColor": [0.05, 0.06, 0.12, 1]},
            "entities": out + list(extra_ents) + self.ents,
        }
        path = os.path.join(PROJECT, "scenes", self.name + ".scene.json")
        with open(path, "w") as f:
            json.dump(scene, f, indent=1)
            f.write("\n")
        if VIEW:
            self.write_view(scene, cx, cz, max(w, d))
        return len(scene["entities"])

    def write_view(self, scene, cx, cz, span):
        """A script-free copy with an overhead camera, to look at the layout while editing it (scenes/_view_*.scene.json)."""
        view = json.loads(json.dumps(scene))
        ents = []
        for e in view["entities"]:
            if e["id"] in ("hud", "pause_menu", "area"):
                continue
            e.get("components", {}).pop("Script", None)
            for c in e.get("children", []):
                c.get("components", {}).pop("Script", None)
            if e["id"] == "camera":
                e["components"]["Transform"] = {"position": [rnd(cx), rnd(span * 0.75), rnd(cz + span * 0.28)], "rotation": [-70, 0, 0]}
                e["components"]["Camera"]["fov"] = 60
                e["components"]["Camera"]["farPlane"] = 200
            ents.append(e)
        view["entities"] = ents
        with open(os.path.join(PROJECT, "scenes", "_view_" + self.name + ".scene.json"), "w") as f:
            json.dump(view, f, indent=1)


STORY_AREAS = ("ground", "upstairs", "cellar")  # areas with a cast and chapters (not the test room)

PORTER_ANIMATOR = {
    "params": {"speed": 0.0, "interact": False, "pickup": False},
    "states": {
        "idle": {"clip": "idle"},
        "walk": {"clip": "walk"},
        "run": {"clip": "sprint"},
        "interact": {"clip": "interact-right", "loop": False},
        "pickup": {"clip": "pick-up", "loop": False},
    },
    "transitions": [
        {"to": "interact", "when": "interact", "fade": 0.1},
        {"to": "pickup", "when": "pickup", "fade": 0.1},
        {"from": "interact", "to": "idle", "onFinish": True, "fade": 0.15},
        {"from": "pickup", "to": "idle", "onFinish": True, "fade": 0.15},
        {"from": "idle", "to": "walk", "when": "speed > 0.3", "fade": 0.15},
        {"from": "walk", "to": "run", "when": "speed > 3.6", "fade": 0.15},
        {"from": "run", "to": "walk", "when": "speed <= 3.2 && speed > 0.3", "fade": 0.15},
        {"from": "walk", "to": "idle", "when": "speed <= 0.3", "fade": 0.2},
        {"from": "run", "to": "idle", "when": "speed <= 0.3", "fade": 0.2},
    ],
    "events": [
        {"clip": "walk", "time": 0.1, "name": "footstep"},
        {"clip": "walk", "time": 0.55, "name": "footstep"},
        {"clip": "sprint", "time": 0.05, "name": "footstep"},
        {"clip": "sprint", "time": 0.4, "name": "footstep"},
    ],
    "state": "idle",
}

RUG_TINTS = [[0.78, 0.42, 0.38, 1], [0.45, 0.55, 0.7, 1], [0.7, 0.6, 0.38, 1], [0.5, 0.65, 0.5, 1]]
WARM = (1.0, 0.82, 0.6)
COOL = (0.6, 0.75, 1.0)
GREEN = (0.75, 1.0, 0.8)

# ---------------------------------------------------------------------------------------------------- the layouts


def ground():
    a = Area("ground", "area.ground", [0.95, 0.85, 0.72, 1], {
        "library": [0.42, 0.28, 0.2, 1], "dining": [0.5, 0.38, 0.3, 1], "kitchen": [0.62, 0.64, 0.66, 1],
        "corridor": [0.46, 0.36, 0.29, 1], "stair_hall": [0.46, 0.36, 0.29, 1], "hall": [0.5, 0.4, 0.32, 1]})
    a.room("library", 0, 0, 5, 6)
    a.room("dining", 5, 0, 11, 6)
    a.room("kitchen", 11, 0, 16, 6)
    a.room("corridor", 0, 6, 16, 8)
    a.room("stair_hall", 0, 8, 4, 12)
    a.room("hall", 4, 8, 12, 12)
    a.opening("door", ("h", 2, 6))      # library door (locked)
    a.opening("arch", ("h", 6, 6))      # dining <-> corridor
    a.opening("arch", ("h", 13, 6))     # kitchen <-> corridor
    a.opening("arch", ("v", 5, 2))      # library <-> dining
    a.opening("arch", ("v", 11, 2))     # dining <-> kitchen
    a.opening("door", ("v", 16, 7))     # cellar door
    a.opening("arch", ("h", 2, 8))      # corridor <-> stair hall
    a.opening("arch", ("v", 4, 9))      # stair hall <-> hall
    for c in (6, 7, 8, 9):
        a.opening("open", ("h", c, 8))   # the hall opens onto the corridor
    a.opening("door", ("h", 7, 12))     # front door (locked: the storm)
    for key in [("h", 1, 0), ("h", 3, 0), ("h", 7, 0), ("h", 9, 0), ("h", 13, 0), ("h", 14, 0), ("v", 0, 2), ("v", 0, 4),
                ("h", 13, 8), ("h", 15, 8), ("v", 16, 6), ("h", 1, 12), ("h", 5, 12), ("h", 9, 12), ("v", 12, 10),
                ("v", 0, 10), ("h", 0, 8)]:
        a.windows.add(key)
    a.windows.discard(("h", 0, 8))
    a.build_structure()

    a.door_leaf("library_door", "h", 6, 2, {"name": "object.library_door", "requiresItem": "library_key", "lockedText": "door.libraryLocked"})
    a.door_leaf("cellar_door", "v", 16, 7, {"name": "object.cellar_door", "area": "cellar", "arrive": "spawn_from_ground"})
    a.door_leaf("front_door", "h", 12, 7, {"name": "object.front_door", "requiresFlag": "storm_over", "lockedText": "door.frontLocked"})

    # --- hall (x 8-24, z 16-24)
    a.place("rugRound", 16, 19.6, 0, 3.0, collide=False)
    a.place("rugDoormat", 15, 22.6, 0, 3.0, collide=False)
    a.row(["coatRackStanding"], 11.0, 23.2, 1, 0, 0, 2.4, fade=True)
    a.place("coatRackStanding", 19.5, 23.2, 0, 2.4, fade=True)
    a.place("benchCushion", 12.4, 23.1, 0, 2.0, ident="p_bench_hall", script={"kind": "examine", "name": "object.hall_bench", "text": "examine.hallBench"})
    a.place("bear", 21.5, 23.2, 180, 3.0, script={"kind": "examine", "name": "object.hall_bear", "text": "examine.hallBear"}, ident="p_bear")
    a.place("desk", 19.0, 18.2, 180, 2.0, ident="p_reception", script={"kind": "examine", "name": "object.reception", "text": "examine.reception"})
    a.place("chairDesk", 19.0, 17.0, 180, 2.0)
    a.place("lampSquareTable", 20.2, 18.2, 0, 2.0, y=0.78, collide=False)
    a.place("loungeSofa", 10.3, 19.3, 90, 2.0)
    a.place("loungeChairRelax", 13.0, 17.4, 180, 2.0)
    a.place("tableCoffee", 12.2, 19.3, 90, 2.0, ident="p_hall_table")
    a.place("lampRoundFloor", 9.0, 17.0, 0, 2.0)
    a.place("pottedPlant", 9.0, 23.0, 0, 2.0)
    a.place("pottedPlant", 23.0, 17.0, 0, 2.0)
    a.place("sideTableDrawers", 23.3, 20.6, 270, 2.0, ident="p_radio_table")
    a.place("radio", 23.3, 20.6, 270, 2.0, y=0.76, collide=False, ident="p_radio", script={"kind": "examine", "name": "object.radio", "text": "examine.radio"})
    a.light(12, 2.1, 20, WARM, 1.1, 9, "light_hall_w")
    a.light(16, 2.3, 19, WARM, 1.3, 10, "light_hall_c")
    a.light(21, 2.1, 20, WARM, 1.1, 9, "light_hall_e")
    a.light(15, 2.0, 23.2, COOL, 0.6, 5, "light_hall_door")

    # --- stair hall (x 0-8, z 16-24)
    a.stairs("stairs_up", 1.15, 19.5, 90, {"name": "object.stairs_up", "area": "upstairs", "arrive": "spawn_from_ground", "verb": "interact.verb.climb"})
    a.place("benchCushion", 5.5, 23.2, 0, 2.0)
    a.place("pottedPlant", 7.0, 23.0, 0, 2.0)
    a.place("rugRectangle", 4.2, 20.3, 0, 2.2, collide=False)
    a.place("lampRoundFloor", 7.2, 17.0, 0, 2.0)
    a.light(4.2, 2.1, 20.5, WARM, 1.0, 8, "light_stair")

    # --- corridor (x 0-32, z 12-16)
    a.place("rugRectangle", 8, 14, 90, 2.0, collide=False)
    a.place("rugRectangle", 24, 14, 90, 2.0, collide=False)
    a.place("sideTableDrawers", 12.2, 12.55, 180, 2.0)
    a.place("lampSquareTable", 12.2, 12.55, 0, 2.0, y=0.76, collide=False)
    a.place("pottedPlant", 30.9, 12.7, 0, 2.0)
    a.place("sideTableDrawers", 28.0, 15.5, 0, 2.0)
    a.place("books", 28.0, 15.5, 0, 2.0, y=0.76, collide=False)
    a.light(6, 2.2, 14, WARM, 0.9, 8, "light_corr_w")
    a.light(16, 2.2, 14, WARM, 0.9, 8, "light_corr_c")
    a.light(26, 2.2, 14, WARM, 0.9, 8, "light_corr_e")

    # --- library (x 0-10, z 0-12)
    a.row(["bookcaseOpen", "bookcaseClosedWide", "bookcaseOpen", "bookcaseClosedWide", "bookcaseOpen"], 0.25, 0.65, 1, 0, 0, 2.4, fade=True)
    a.row(["bookcaseOpen", "bookcaseClosedWide", "bookcaseOpen", "bookcaseClosedWide", "bookcaseOpen"], 0.65, 0.5, 0, 1, 90, 2.4, fade=True)
    a.place("rugRectangle", 5.2, 7.0, 0, 3.0, collide=False)
    a.place("tableCoffee", 5.2, 7.0, 0, 2.0)
    a.place("loungeSofa", 5.2, 9.4, 0, 2.0)
    a.place("loungeChairRelax", 2.8, 7.0, 270, 2.0)
    a.place("desk", 8.2, 3.0, 270, 2.0, ident="p_library_desk", script={"kind": "examine", "name": "object.library_desk", "text": "examine.libraryDesk"})
    a.place("chairDesk", 7.0, 3.0, 270, 2.0)
    a.place("books", 8.2, 3.0, 0, 2.0, y=0.78, collide=False)
    a.place("lampRoundFloor", 9.2, 1.0, 0, 2.0)
    a.place("pottedPlant", 9.1, 10.9, 0, 2.0)
    a.light(5, 2.3, 6, WARM, 1.2, 9, "light_library")
    a.light(8.2, 1.6, 3, WARM, 0.7, 4.5, "light_library_desk")

    # --- dining room (x 10-22, z 0-12)
    a.place("rugRectangle", 17.5, 8.2, 0, 4.0, collide=False)
    a.row(["tableCloth", "tableCloth"], 15.65, 8.2, 1, 0, 0, 2.2)
    for x in (16.5, 18.6):
        a.place("chair", x, 7.2, 180, 2.0)
        a.place("chair", x, 9.2, 0, 2.0)
    a.place("chairRounded", 14.6, 8.2, 270, 2.0)
    a.place("chairRounded", 20.5, 8.2, 90, 2.0)
    a.row(["sideTableDrawers", "sideTableDrawers"], 12.0, 0.6, 1, 0, 0, 2.2, gap=0.0)
    a.place("lampSquareTable", 12.7, 0.6, 0, 2.0, y=0.84, collide=False)
    a.place("pottedPlant", 21.0, 1.0, 0, 2.0)
    a.place("pottedPlant", 21.0, 10.9, 0, 2.0)
    a.place("cardboardBoxClosed", 21.0, 5.2, 10, 2.0, ident="p_ledger_box", script={"kind": "item", "name": "object.dining_box", "item": "guest_ledger", "once": "ledger_taken"})
    a.place("bookcaseClosedWide", 17.4, 0.7, 0, 2.4, fade=True)
    a.light(17.5, 2.3, 8, WARM, 1.5, 11, "light_dining")

    # --- kitchen (x 22-32, z 0-12)
    x, z = a.row(["kitchenFridgeLarge", "kitchenCabinet", "kitchenSink", "kitchenCabinet", "kitchenStove", "kitchenCabinet", "kitchenCabinetCornerInner"],
                 22.1, 0.55, 1, 0, 0, 2.0, fade=False)
    a.row(["kitchenCabinetUpper", "kitchenCabinetUpper", "kitchenCabinetUpper"], 23.8, 0.4, 1, 0, 0, 2.0, y=1.5, collide=False)
    a.place("hoodLarge", 27.6, 0.6, 0, 2.0, y=1.5, collide=False)
    a.place("kitchenCoffeeMachine", 25.1, 0.55, 0, 2.0, y=0.9, collide=False)
    a.row(["kitchenCabinet", "kitchenCabinet", "kitchenCabinet", "kitchenCabinet"], 31.45, 2.2, 0, 1, 270, 2.0)
    a.place("kitchenBar", 26.4, 6.8, 0, 2.2, ident="p_kitchen_island")
    for xx in (25.2, 26.4, 27.6):
        a.place("stoolBar", xx, 8.0, 0, 2.0)
    a.place("trashcan", 22.9, 11.0, 0, 1.6)
    a.place("cardboardBoxClosed", 30.8, 10.8, 20, 2.0, ident="p_kitchen_box", script={"kind": "item", "name": "object.kitchen_box", "item": "lamp_oil", "once": "kitchen_box_taken"})
    a.place("cardboardBoxClosed", 31.0, 9.2, 0, 2.0)
    a.light(27, 2.3, 6, GREEN, 1.4, 10, "light_kitchen")

    # --- spawns
    a.spawn("spawn_default", 15, 21.6, 0)
    a.spawn("spawn_from_upstairs", 3.4, 19.5, 270)
    a.spawn("spawn_from_cellar", 30.6, 15, 270)
    a.preload = ["scenes/upstairs.scene.json", "scenes/cellar.scene.json"]
    return a


def upstairs():
    a = Area("upstairs", "area.upstairs", [0.9, 0.82, 0.74, 1], {
        "room_a": [0.5, 0.36, 0.26, 1], "room_b": [0.46, 0.34, 0.28, 1], "room_c": [0.5, 0.36, 0.26, 1], "room_d": [0.46, 0.34, 0.28, 1],
        "corridor": [0.45, 0.3, 0.22, 1], "landing": [0.5, 0.34, 0.24, 1]})
    for i, name in enumerate(["room_a", "room_b", "room_c", "room_d"]):
        a.room(name, i * 4, 0, i * 4 + 4, 4)
    a.room("corridor", 0, 4, 16, 6)
    a.room("landing", 0, 6, 10, 10)
    for c in (3, 4, 5, 6):
        a.opening("open", ("h", c, 6))
    for i in range(4):
        a.opening("door", ("h", i * 4 + 1, 4))
    for key in [("h", 0, 0), ("h", 2, 0), ("h", 4, 0), ("h", 6, 0), ("h", 8, 0), ("h", 10, 0), ("h", 12, 0), ("h", 14, 0),
                ("v", 0, 1), ("v", 16, 1), ("v", 0, 7), ("v", 10, 7), ("h", 4, 10), ("h", 8, 10), ("v", 16, 4)]:
        a.windows.add(key)
    a.build_structure()
    guest = [
        ("a", None, None),
        ("b", None, None),
        ("c", "room_c_key", None),
        ("d", "room_d_key", None),
    ]
    for i, (k, item, _x) in enumerate(guest):
        props = {"name": "object.guest_door_" + k}
        if item:
            props.update({"requiresItem": item, "lockedText": "door.guestLocked"})
        a.door_leaf("guest_door_" + k, "h", 4, i * 4 + 1, props)
    # --- guest rooms: x 0-8 / 8-16 / 16-24 / 24-32, z 0-8
    bx = lambda i: i * 8
    # room a: double bed, desk
    a.place("bedDouble", bx(0) + 4.0, 2.4, 180, 1.5, ident="p_bed_a")
    a.place("cabinetBedDrawerTable", bx(0) + 6.6, 0.9, 180, 2.0)
    a.place("cabinetBedDrawerTable", bx(0) + 1.4, 0.9, 180, 2.0)
    a.place("rugRound", bx(0) + 4.0, 5.2, 0, 3.0, collide=False)
    a.place("pottedPlant", bx(0) + 7.0, 7.0, 0, 2.0)
    a.light(bx(0) + 4, 2.2, 4, WARM, 1.0, 7, "light_a")
    # room b: two single beds
    a.place("bedSingle", bx(1) + 2.0, 2.6, 180, 1.5, ident="p_bed_b1")
    a.place("bedSingle", bx(1) + 6.0, 2.6, 180, 1.5, ident="p_bed_b2")
    a.place("cabinetBedDrawerTable", bx(1) + 4.0, 0.9, 180, 2.0)
    a.place("rugRectangle", bx(1) + 4.0, 5.6, 0, 2.5, collide=False)
    a.place("cardboardBoxClosed", bx(1) + 7.0, 6.8, 20, 2.0, ident="p_letter_box", script={"kind": "item", "name": "object.guest_box", "item": "torn_letter", "once": "letter_taken"})
    a.light(bx(1) + 4, 2.2, 4, WARM, 1.0, 7, "light_b")
    # room c: double bed, desk and chair
    a.place("bedDouble", bx(2) + 4.0, 2.4, 180, 1.5, ident="p_bed_c")
    a.place("desk", bx(2) + 1.2, 6.6, 90, 2.0)
    a.place("chairDesk", bx(2) + 2.4, 6.6, 90, 2.0)
    a.place("cabinetBedDrawerTable", bx(2) + 6.6, 0.9, 180, 2.0)
    a.light(bx(2) + 4, 2.2, 4, WARM, 1.0, 7, "light_c")
    # room d: bunk beds
    a.place("bedBunk", bx(3) + 2.2, 2.6, 180, 1.5, ident="p_bed_d")
    a.place("bedBunk", bx(3) + 5.6, 2.6, 180, 1.5)
    a.place("rugRound", bx(3) + 4.0, 5.6, 0, 2.6, collide=False)
    a.light(bx(3) + 4, 2.2, 4, COOL, 0.9, 7, "light_d")
    # corridor z 8-12
    a.place("rugRectangle", 8, 10, 90, 2.0, collide=False)
    a.place("rugRectangle", 24, 10, 90, 2.0, collide=False)
    a.place("sideTableDrawers", 16.4, 8.55, 180, 2.0)
    a.place("lampSquareTable", 16.4, 8.55, 0, 2.0, y=0.76, collide=False)
    a.place("pottedPlant", 31.0, 8.7, 0, 2.0)
    a.light(6, 2.2, 10, WARM, 0.9, 8, "light_corr_w")
    a.light(16, 2.2, 10, WARM, 0.9, 8, "light_corr_c")
    a.light(26, 2.2, 10, WARM, 0.9, 8, "light_corr_e")
    # landing x 0-20, z 12-20
    a.stairs("stairs_down", 1.15, 15.5, 90, {"name": "object.stairs_down", "area": "ground", "arrive": "spawn_from_upstairs", "verb": "interact.verb.descend"})
    a.place("loungeSofa", 14.0, 19.2, 0, 2.0)
    a.place("loungeChairRelax", 17.8, 16.4, 90, 2.0)
    a.place("tableCoffee", 14.0, 16.6, 0, 2.0)
    a.place("rugRectangle", 14.0, 16.4, 0, 3.2, collide=False)
    a.place("bookcaseOpen", 8.0, 12.7, 0, 2.4, fade=True)
    a.place("lampRoundFloor", 18.8, 19.0, 0, 2.0)
    a.place("pottedPlant", 9.4, 19.0, 0, 2.0)
    a.light(12, 2.3, 16, WARM, 1.2, 10, "light_landing")
    a.light(3.2, 2.1, 17, WARM, 0.8, 6, "light_stair")
    a.spawn("spawn_default", 3.6, 15.5, 270)
    a.spawn("spawn_from_ground", 3.6, 15.5, 270)
    a.preload = ["scenes/ground.scene.json"]
    return a


def cellar():
    a = Area("cellar", "area.cellar", [0.62, 0.6, 0.58, 1], {"cellar": [0.4, 0.38, 0.37, 1], "nook": [0.38, 0.36, 0.35, 1]},
             moon=False, ambient=(0.1, 0.1, 0.14))
    a.room("cellar", 0, 0, 8, 6)
    a.room("nook", 8, 1, 11, 5)
    a.opening("arch", ("v", 8, 2))
    a.build_structure()
    a.stairs("stairs_up", 1.15, 4.5, 90, {"name": "object.stairs_up", "area": "ground", "arrive": "spawn_from_cellar", "verb": "interact.verb.climb"})
    a.row(["bookcaseOpenLow"] * 6, 2.5, 0.6, 1, 0, 0, 2.4)
    a.row(["bookcaseOpenLow"] * 4, 15.4, 0.6, 0, 1, 90, 2.4)
    a.place("washer", 15.0, 11.0, 180, 2.0)
    a.place("dryer", 13.9, 11.0, 180, 2.0)
    a.place("cardboardBoxClosed", 8.5, 10.4, 15, 2.2, ident="p_cellar_box", script={"kind": "item", "name": "object.cellar_box", "item": "library_key", "once": "cellar_box_taken"})
    a.place("cardboardBoxOpen", 10.0, 10.9, 0, 2.2)
    a.place("cardboardBoxClosed", 10.2, 9.6, 40, 2.0)
    a.place("trashcan", 5.5, 11.0, 0, 1.6)
    a.place("bookcaseOpen", 18.8, 3.0, 270, 2.4, ident="p_wine_rack", script={"kind": "examine", "name": "object.wine_rack", "text": "examine.wineRack"})
    a.place("books", 18.4, 6.0, 0, 2.0, y=0.0, collide=False)
    a.place("cardboardBoxClosed", 20.6, 8.6, 300, 2.0, ident="p_lantern_box", script={"kind": "item", "name": "object.cellar_lantern_box", "item": "cellar_lantern", "once": "lantern_taken"})
    a.light(6, 2.3, 6, COOL, 0.9, 9, "light_cellar_a")
    a.light(12, 2.3, 8, WARM, 0.8, 8, "light_cellar_b")
    a.light(18, 2.1, 5, COOL, 0.6, 6, "light_nook")
    a.spawn("spawn_default", 3.6, 8.8, 270)
    a.spawn("spawn_from_ground", 3.6, 8.8, 270)
    a.preload = ["scenes/ground.scene.json"]
    return a


def test_room():
    a = Area("test_room", "area.testRoom", [0.9, 0.85, 0.8, 1], {"main": [0.5, 0.4, 0.3, 1], "closet": [0.4, 0.4, 0.45, 1]})
    a.room("main", 0, 0, 5, 5)
    a.room("closet", 5, 1, 8, 4)
    a.opening("door", ("v", 5, 2))  # a locked door (needs test_key) between the two rooms
    a.windows.add(("h", 1, 0))
    a.build_structure()
    a.door_leaf("test_door", "v", 5, 2, {"name": "object.test_door", "requiresItem": "test_key", "lockedText": "door.testLocked"})
    # a free-standing interior wall (it fades) that hides the porter from a camera behind him when he stands north of it
    a.wall_ent("w_screen", "h", 3, 1, 2, MODELS + "wall.glb", {"shape": "box", "size": [1, 1.29, 0.125], "offset": [0.5, 0.645, -0.025]}, False)
    a.place("cardboardBoxClosed", 1.6, 8.0, 0, 2.2, ident="p_test_box", script={"kind": "item", "name": "object.test_box", "item": "test_key", "once": "test_box_taken"})
    a.place("bear", 7.5, 8.0, 180, 3.0, ident="p_test_bear", script={"kind": "examine", "name": "object.hall_bear", "text": "examine.hallBear"})
    a.place("bookcaseOpen", 13.0, 2.7, 0, 2.4, fade=True, ident="p_test_shelf")
    a.place("tableCoffee", 13.0, 6.0, 0, 2.0)
    a.light(5, 2.3, 5, WARM, 1.2, 9, "light_main")
    a.light(13, 2.2, 4, COOL, 0.8, 6, "light_closet")
    a.spawn("spawn_default", 5.0, 8.0, 0)
    return a


AREAS = {"ground": ground, "upstairs": upstairs, "cellar": cellar, "test_room": test_room}
SPAWN_OF = {"ground": (15, 21.6), "upstairs": (3.6, 15.5), "cellar": (3.6, 8.8), "test_room": (5.0, 8.0)}


def main():
    wanted = [a for a in sys.argv[1:] if not a.startswith("--")] or list(AREAS)
    for name in wanted:
        area = AREAS[name]()
        n = area.finish(SPAWN_OF[name])
        print("%s: %d entities" % (name, n))


if __name__ == "__main__":
    main()
