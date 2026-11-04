# Skeletons for 3D models: `*.rig.json`

A rig document is the skeleton of a model document (docs/MODELING.md): a **template** (humanoid, quadruped, bird, tail, chain or
generic) plus the hints that fit it to the model, which model parts are which bone and where a joint really is. The document holds
the intent; the joint positions are computed from the model every time, so the same document and model give the same bytes on every
platform. `rig.bake` writes the model again as a skinned `.glb`: the model's mesh, one glTF **skin** whose joints are the bones, and
the inverse bind matrices that make the rest pose draw the model exactly as it was built.

```json
{
  "format": "factoria.rig/1",
  "model": "assets/models/hero.model.json",
  "template": "humanoid",
  "options": {"spine": 3, "neck": 1, "tail": 0, "toes": true, "pose": "auto"},
  "parts": {"arm_upper_l": ["sleeve_left"]},
  "landmarks": {"head": [0, 1.62, 0.03]},
  "strict": false
}
```

`schemas/rig.schema.json` describes the format (`$schema` may point to it). Make a document with `rig.create`, change what the fit
is told with `rig.fit`, look at the result with `rig.info`.

What exists today, and what does not:

| Done here (M59.1, M59.2) | Later |
|---|---|
| Templates, the canonical bone names, the fit to a model, the rest pose, the skinned `.glb` | 3D clips, IK, generators and retargeting between templates (M59.3), the editor panel (M59.4) |
| Skin weights: heat diffusion, voxel binding or rigid per part, the `skin` section, `skin3d.*` edits and the weight preview | |

The file is complete as a skeleton (the joints, their hierarchy and names, and the inverse bind matrices) and as a skin: every
vertex carries up to four bones with normalised weights, computed from the document each time (see "Skin weights").

## Commands

| Command | What it does |
|---|---|
| `rig.templates {}` | The catalog: each template, its options (range and default) and the words in a part name it recognises. |
| `rig.templates {name, options?}` | The bones of one template for those options (name, role, index, side, parent, leaf) and the landmark names a document may use. |
| `rig.create {path, model, template, options?, parts?, landmarks?, strict?, output?, skin?, doc?, overwrite?, bake?}` | Writes a document, fits the template to the model, bakes the `.glb`. A `generic` rig gets one bone per part of the model. |
| `rig.fit {path, parts?, landmarks?, options?, symmetryX?, strict?, skin?, dryRun?, bake?, overwrite?}` | Changes what the fit is told (merged key by key; null removes a key), checks the whole document, writes it, answers with the fit and bakes again. With nothing to change it only shows the fit. `dryRun` shows the fit the changes would give without writing. |
| `rig.info {path, fit?}` | Validity with ALL issues (JSON pointer, what is wrong, fix, "did you mean"), the output, whether the `.glb` is fresh, and the fit. Read-only. |
| `rig.bake {path?, force?, dryRun?, overwrite?}` | Bakes the documents whose `.glb` is missing or stale (one with `path`; `force` also the fresh ones), with provenance and a recipe in `assets.json`. |

The `skin3d.*` commands (below) change the document's `skin` section and look at the weights.

`assets.regenerate` rebuilds a stale `.glb`, `project.validate` lists documents that do not load or fit (an error per issue) or were
never baked (a warning), and `factoria export` bakes the stale ones first. A file at the output that no rig document baked is never
replaced unless `overwrite` is true. A bad `rig.create` or `rig.fit` (a name that is not a bone or a part, a fit that cannot be made)
writes nothing.

## Canonical bones

Every template names its bones `<role>[_<index>][_<side>]`:

- `role` says what the bone is: `root`, `spine`, `neck`, `head`, `clavicle`, `arm_upper`, `arm_lower`, `hand`, `thigh`, `shin`,
  `foot`, `toe`, `tail`, `chain`.
- `index` (1-based) is there only when the template has more than one bone of that role and side: `spine_1..spine_3`,
  `neck_1..neck_2`, `tail_1..tail_4`; a single neck is `neck`.
- `side` is `l` or `r`. The conventions are the engine's: right-handed, +Y up, the character looks towards **+Z**, and
  character-left is **+X**. A bone `_l` sits on the +X side of the symmetry plane.

The top bone of every template is `root` (the hips or pelvis; the base of a chain). **The triple (role, index, side) is the key
retargeting between templates maps** (M59.3): a humanoid `arm_upper_l` and a quadruped `arm_upper_l` are the same role, so a clip
can be carried across. The front leg of a quadruped is its "arm" for that reason. Each joint node in the `.glb` carries the triple
in its `extras` (`{"role": "arm_upper", "side": "l"}`; `index` and `side` are left out when the bone has none) and the skin's
`extras.factoriaRig` says the template (`{"format": "factoria.rig/1", "template": "humanoid"}`).

A bone is its **head**: the position of the joint. Its **tail** is where it ends: the head of its main child, or for a leaf bone
(no children: `head`, `hand_l`, `toe_l`, the last tail bone) a landmark named `<bone>.tail`. All bones rest with identity rotation
and scale, and the local translation of a joint is its head minus its parent's head.

### The templates

| Template | Bones (default options) | Looks for in part names |
|---|---|---|
| `humanoid` | root, spine_1..3, neck, head, and per side clavicle, arm_upper, arm_lower, hand, thigh, shin, foot, toe: 22 | head/skull/face/helmet/hat, neck, torso/body/chest/pelvis/hips, arm/forearm/hand/shoulder, leg/thigh/shin/calf/foot/toe, tail |
| `quadruped` | root, spine_1..3, neck_1..2, head, per side front leg as clavicle, arm_upper, arm_lower, hand, hind leg as thigh, shin, foot, toe, tail_1..4: 27 | head/snout/muzzle, neck, body/torso/barrel, foreleg/front_leg/paw, hindleg/hind_leg/hoof, tail |
| `bird` | root, spine_1..2, neck_1..3, head (its tail is the beak tip), per side wing as clavicle, arm_upper, arm_lower, hand, legs thigh, shin, foot, toe, tail_1..2: 25 | head/beak/bill, neck, body/breast, wing/primaries, leg/claw, tail |
| `tail` | root + tail_1..N along `axis` (a tail, tentacle, antenna, whip) | tail/tentacle/antenna/whip |
| `chain` | root + chain_1..N along `axis` (a rope, cable, chain) | chain/rope/cable/link |
| `generic` | root + the bones you list (a robot arm, a door, a wheeled vehicle) | each bone names its part exactly |

Side words (`l`, `left`, `r`, `right`) and plurals are recognised in any order and case (`arm_l`, `LeftArm`, `legs`). `rig.templates {}`
lists each template's options and exact words; `rig.templates {name}` lists its bones. The options:

- `humanoid`: `spine` 1..5 (3), `neck` 1..3 (1), `tail` 0..12 (0), `toes` (true), `pose` `auto`/`down`/`out` (`auto`: arms out when
  the model is wider than 0.75 of its height).
- `quadruped`: `spine` 1..5 (3), `neck` 1..4 (2), `tail` 0..12 (4).
- `bird`: `spine` 1..3 (2), `neck` 1..6 (3), `tail` 0..6 (2), `pose` `auto`/`folded`/`spread` (`auto`: spread when the model is wider
  than it is long).
- `tail` / `chain`: `segments` 2..32 (5 / 6), `axis` `+x`..`-z` (`-z` / `-y`), the direction the chain grows from its base; the
  base is at the opposite end of the model, and the bones are spaced evenly over the model, or over its `tail` / `chain` part when it
  has one. If the model is longer along another axis the fit warns and names the axis to set.
- `generic`: `bones`, an array of `{name, parent?, role?, part, anchor?, tailAnchor?}`. Parents come before children, a bone with no
  `parent` hangs from `root`, `anchor` is where in the part's bounds the joint is (-1..1 per axis around the centre; `[0,-1,0]` is the
  bottom), and a leaf's tail defaults to the opposite side of the part. `rig.create` with the generic template writes one bone per
  model part; edit the file to give them a hierarchy.

A rig has at most **64 bones**, the limit of one skin in the renderer; a template with more says which option to lower.

## How the fit works

The model is evaluated (the model document with its `gameReady.origin` applied, so the skin sits where the model is drawn; LODs and
the merge by material are not used: the parts are what the fit looks at), then each landmark, every head and every leaf tail,
comes from the first of these that applies:

| Source | Where it comes from |
|---|---|
| `override` | The document's `landmarks` (`"head": [x,y,z]`, `"hand_l.tail": [x,y,z]`), in the model's space. Always wins. |
| `part` | A model part the fit recognised by its name, or that the document's `parts` named: the joint is at a place along the part's bounds, for instance the shoulder at the end of `arm_l` that is nearer to the body. |
| `geometry` | Measured from the mesh: the extremes of the bounds (the top of the head, the tip of a beak or tail), the height of the underside at the symmetry plane (a humanoid's crotch), the ends of a chain's model. |
| `proportion` | The template's default proportions of the model's bounds: an **estimate**. |

`parts` is `{bone: part or [parts]}`: use it when a part's name does not say which bone it is
(`{"arm_upper_l": ["sleeve_left"]}`). A part named there that the model does not have is an error with "did you mean". The
**symmetry plane** is at `symmetryX` or, left out, the centre of the model's bounds; left and right bones mirror about it. The
answer of `rig.create`, `rig.fit` and `rig.info` lists, for every bone, its head and tail, where each came from, and which model
parts it follows (`matched`, `parts`), plus `landmarks` (how many came from each source), `unusedParts` (parts no bone looked at)
and `warnings`. Warnings say what was noticed and what to do: no named parts at all, a part that covers both sides, a part named
`_l` that sits on the -X side, a part no bone matched, landmarks that were estimated, joints outside the model's bounds.

`strict: true` turns every estimate into an error that lists the landmarks to name or give: use it when a wrong joint would be
worse than no rig. A model with no named parts and no `strict` fits from the bounds and the proportions alone, with the warning.

## The `.glb`

`rig.bake` writes `<name>.rig.glb` next to the document (`output.path` changes it; it must be under `assets/` and end in `.glb`).
It is the mesh exactly as `model.bake` writes it (the same submeshes, materials and, when the model is textured and baked, its
texture) plus:

- one **skin** whose joints are the bones, in the fit's order (parents first), each a node named like the bone with translation
  = head minus the parent's head, identity rotation and scale, and `extras` `{role, index?, side?}`;
- `inverseBindMatrices` = translation by minus the bone's head, so at rest the skin palette is the identity and the mesh draws as
  the model does;
- `JOINTS_0` and `WEIGHTS_0` on every primitive.

It loads like any skinned glTF (`MeshRenderer.mesh: "assets/models/hero.rig.glb"`; `parse_skeleton` returns the joints and the
skin, `skin_palette` of the rest pose is the identity). It has no animation clips; the clips of M59.3 will use these joints.

### Binding

Which bones move each vertex, and how much, is the `skin` section of the document (next chapter). A vertex follows at most four
bones, strongest first, and its weights sum to 1. The weights are never stored: they are computed from the document, the fitted
skeleton and the model every time the `.glb` is baked, deterministically, so the same inputs give the same bytes.

### Staleness and provenance

`assets.json` records the provenance (provider `factoria rig.bake`, kind `model3d`) and a recipe whose inputs are the rig document,
the model document, every file the model reads and, for a textured model, its baked picture. When any changes the `.glb` is stale:
`rig.info` says so, `project.validate` warns, and `rig.bake` or `assets.regenerate {"stale": true}` builds it again. The same inputs
give the same bytes on every platform (the fit uses `+ - * /` and `sqrt` and ordered iteration only).

## Skin weights

The `skin` section is optional: left out, every part gets the automatic weights with the defaults below.

```json
"skin": {
  "method": "auto",
  "maxInfluences": 4,
  "smooth": 1,
  "maxHops": 2,
  "locality": 1,
  "parts": {"claw": {"method": "rigid", "bone": "arm_lower_l"}},
  "edits": [
    {"op": "set", "bone": "hand_l", "weight": 1, "part": "glove_l"},
    {"op": "smooth", "iterations": 3, "select": {"by": "box", "min": [0.2, 1.3, -0.2], "max": [0.5, 1.6, 0.2]}},
    {"op": "mirror", "from": "l"}
  ]
}
```

### Methods

`method` is the default for every part, `parts.<part>.method` overrides it for one part (`parts.<part>.bone` names the bone a part
follows or is centred on; a part name the model does not have is an error with a "did you mean").

| Method | What it does | Use it for |
|---|---|---|
| `heat` | Bone heat diffusion on the surface of the mesh: each bone's weight spreads from the vertices nearest to it over a cotangent Laplacian, so the weights are smooth, local and follow the shape. The mesh is welded by position for the solve (the seams of a primitive, the hard edges of a box) and every connected piece is solved on its own, so a model made of several loose parts, or an SDF creature, works. | Organic and smooth models: people, creatures, tails. |
| `voxel` | Distance along a voxelised copy of the surface (a 72-cell grid, the shell thickened by one cell), from the voxels nearest to each bone. It needs no closed, manifold or consistently oriented mesh. It is also what a part falls back to when the heat solve cannot converge (the part's report says so in `note`). | A messy imported mesh; a model that makes the heat solve fail. |
| `rigid` | The whole part follows **one bone with weight 1**: `parts.<part>.bone`, else the part's own bone nearest to the part's centre. | Robots, doors, a character made of parts. |
| `auto` (default) | `heat`, except in a `generic` rig, where the bones were placed on parts and every part is `rigid`. | Most models. |

A vertex may follow only the bones that claim its part in the fit and their neighbours in the hierarchy (a part no bone claims may
follow all of them). A blend never reaches further than `maxHops` bones from the strongest bone of the vertex. Then the weights are
smoothed `smooth` passes over the surface, limited to `maxInfluences` and normalised, and the edits are applied in order. `locality`
(0.05 to 20) shapes the heat solve: higher keeps each bone's weights close to it (short blends at the joints), lower spreads them.

Heat diffusion needs vertices where the skin should bend. A primitive such as a box has vertices only at its corners: give a limb
`segments` (`"segments": [10, 2, 2]` on an arm, `[2, 10, 2]` on a leg) so there is a ring of vertices at each joint to blend, or the
weights of a long box can only change from one end to the other.

### Edits

`skin3d.set`, `add`, `smooth`, `normalize`, `limit` and `mirror` each append one entry to `skin.edits`. An edit works on the
vertices of `part` (one part or a list) and of the faces `select` matches (a face query of the model document: `by` box, sphere,
halfspace, part, normal, top, bottom, and, or, not, grow, shrink; `model.select` tries one), the vertices in both when both are
given and every vertex when neither is. Edits are applied in order after the automatic weights, so they survive a re-bake; the
weights are recomputed with the edit before anything is written, so an unknown bone or part fails and changes nothing.

| Edit | Fields | Effect |
|---|---|---|
| `set` | `bone`, `weight` (0 to 1, default 1) | The bone gets exactly that weight; the other influences share the rest in their proportions. A vertex whose only influence was the bone keeps it at 1. |
| `add` | `bone`, `amount` (-1 to 1) | Adds to the bone's weight (negative takes weight away) and normalises. |
| `smooth` | `iterations` (1 to 50), `strength` (0 to 1, default 0.5) | Moves each selected vertex's weights towards the average of its neighbours on the surface (welded by position); neighbours outside the selection take part, so the border blends in. |
| `normalize` | `threshold` (0 to 0.5, default 0.01) | Drops the influences under the threshold (a vertex keeps at least its strongest) and rescales to sum 1. |
| `limit` | `max` (1 to 4) | Keeps the `max` strongest influences of each vertex. |
| `mirror` | `from` (`l` = +X, `r` = -X) | Copies the weights of one side to the other: each vertex is paired with the vertex nearest to its mirror image across `symmetryX` (preferring a vertex of the mirrored part, `arm_l` <-> `arm_r`), and takes its weights with every bone swapped for its opposite (`arm_upper_l` <-> `arm_upper_r`; bones on the centre line keep themselves). A vertex with no partner within 2% of the model's size keeps its weights and is counted in `mirrorUnmatched`. |

### Commands

| Command | What it does |
|---|---|
| `skin3d.info {path}` | The effective settings, the edits with their index, the bones and the parts each follows, the `quality` of the weights and whether the `.glb` is fresh. Read-only. |
| `skin3d.auto {path, method?, part?, bone?, maxInfluences?, smooth?, maxHops?, locality?, clearEdits?, dryRun?, bake?}` | Chooses the method for everything or for one part, changes the settings, recomputes and bakes. With `part` and neither `method` nor `bone` it removes that part's override. |
| `skin3d.set / add / smooth / normalize / limit / mirror {path, part?, select?, ..., dryRun?, bake?}` | Appends the edit, shows how many vertices it changed (`verticesChanged`) and the `quality`, and bakes. |
| `skin3d.clear {path, index?}` | Removes one edit, or all of them, and bakes. |
| `skin3d.preview {path, bone?, mode?, pose?, views?, yaw?, pitch?, cell?, out?}` | Draws the weights (below) and returns the PNG as `$image`. Read-only. |

Every command computes the weights before it writes: a failure writes nothing. `bake: false` writes only the document (the `.glb`
is then stale; `rig.bake` bakes it), `dryRun: true` writes nothing.

### Quality measures

`rig.create`, `rig.bake` and every `skin3d.*` answer include a report of the weights (`skin` or `quality`): `vertices`,
`unweighted` (vertices the method gave nothing for: they follow the nearest bone), `maxInfluences` and `meanInfluences`,
`farBlends` (vertices that blend bones more than `maxHops` apart in the hierarchy, relative to their strongest bone),
`editsApplied`, `mirrorUnmatched`, the method that was used per part (with a `note` when it fell back), `boneVertices` (the
vertices each bone leads) and `idleBones` (bones that lead none: usually a part nobody matched, see `rig.fit`), the `heat`
solver's `pieces`, `failed` and `iterations`, and `warnings` that each say what was noticed and what to change. `quality.ok` is
true when there are no unweighted vertices, no far blends and no warnings.

### Looking at the weights

`skin3d.preview` draws the model with the software renderer of `model.preview` (no graphics device, the same pixels everywhere):
`bone` makes a heat map of that bone's weights (blue 0, green 0.5, red 1), without it each vertex has the weighted mix of the
colours of its bones, with a legend. `pose` (`{"arm_lower_l": 70}`, or a list of `{bone, degrees, axis?}`) bends bones about the axis
perpendicular to the bone (a knee or an elbow; `axis` sets another), taking their children along, and adds a second row with the
model deformed by linear blend skinning, the way a game would deform the `.glb`: creases, stretched triangles and parts left behind
are what a bad skin looks like. Fix what the picture shows with `skin3d.smooth` (a crease), `skin3d.set` (a part on the wrong
bone), `skin3d.auto` with `locality` or a method for that part, and `rig.fit` `parts` when a whole part follows the wrong bones.

## Limits and known gaps

- Skin weights are automatic plus edits: there is no brush. Clips, IK and retargeting come with M59.3. The posed preview bends bones about one axis; it is a check of the weights, not an animation.
- Heat diffusion works on the vertices the mesh has: a long box without `segments` cannot blend along its length (see "Methods").
- The weights follow the bones of the fit: a vertex never follows a bone further than `maxHops` bones from its strongest one, whatever the heat says.
- The skeleton is the rest pose only, every bone with identity rotation: a bone has no roll or twist axis yet.
- A textured model's rig uses the picture the model's own bake wrote. If the model is baked for the first time after the rig,
  bake the rig again (`rig.bake {"force": true}`): the rig only learns of the picture once it exists. `rig.bake` warns when a
  textured model has not been baked.
- A model document is the only thing a rig fits (not a `.glb` you imported); merged and LOD results are not used.
- At most 64 bones; the name of a bone of a generic rig is lowercase letters, digits and underscores.
