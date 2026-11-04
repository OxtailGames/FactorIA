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

| Done here (M59.1, M59.3) | Later |
|---|---|
| Templates, the canonical bone names, the fit to a model, the rest pose, the skinned `.glb` | Smooth skin weights (`skin3d.*`, M59.2) |
| A rigid placeholder binding: every vertex follows ONE bone | The editor panel (M59.4) |
| 3D bone clips, 3D IK, clip generators, retargeting and the filmstrip preview (M59.3, "Clips, IK and retargeting") | |

Until skin weights exist the `.glb` has the rigid placeholder, see "Binding", so a posed model would show hard seams at the joints.
The file is already complete as a skeleton: the joints, their hierarchy and names, and the inverse bind matrices do not change when
the weights do.

## Commands

| Command | What it does |
|---|---|
| `rig.templates {}` | The catalog: each template, its options (range and default) and the words in a part name it recognises. |
| `rig.templates {name, options?}` | The bones of one template for those options (name, role, index, side, parent, leaf) and the landmark names a document may use. |
| `rig.create {path, model, template, options?, parts?, landmarks?, strict?, output?, doc?, overwrite?, bake?}` | Writes a document, fits the template to the model, bakes the `.glb`. A `generic` rig gets one bone per part of the model. |
| `rig.fit {path, parts?, landmarks?, options?, symmetryX?, strict?, dryRun?, bake?, overwrite?}` | Changes what the fit is told (merged key by key; null removes a key), checks the whole document, writes it, answers with the fit and bakes again. With nothing to change it only shows the fit. `dryRun` shows the fit the changes would give without writing. |
| `rig.info {path, fit?}` | Validity with ALL issues (JSON pointer, what is wrong, fix, "did you mean"), the output, whether the `.glb` is fresh, and the fit. Read-only. |
| `rig.bake {path?, force?, dryRun?, overwrite?}` | Bakes the documents whose `.glb` is missing or stale (one with `path`; `force` also the fresh ones), with provenance and a recipe in `assets.json`. |

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
skin, `skin_palette` of the rest pose is the identity). It has no animation clips of its own; the `*.anim.json` 3D clips (below) animate these joints, and each joint's `extras` also
hold `axis` (the unit vector from the bone's head to its tail at rest) and `length` (head to tail, model units) when the bone is
not zero-length, which the generators and IK read (a leaf bone has no child to measure from).

### Binding (the placeholder until M59.2)

`binding: "rigid"` is the only binding today: every vertex follows **one bone with weight 1**, the nearest, measured from the vertex
to the bone's segment (head to tail), among the bones of the vertex's part (the bones the part placed or was named for); a part no
bone claims uses all of them. The result moves in rigid pieces: right for a robot, a door or a character made of parts, and visible
as hard seams in a smooth model. `skin3d.*` (M59.2) replaces the weights with blended ones, and nothing else in the file changes.

### Staleness and provenance

`assets.json` records the provenance (provider `factoria rig.bake`, kind `model3d`) and a recipe whose inputs are the rig document,
the model document, every file the model reads and, for a textured model, its baked picture. When any changes the `.glb` is stale:
`rig.info` says so, `project.validate` warns, and `rig.bake` or `assets.regenerate {"stale": true}` builds it again. The same inputs
give the same bytes on every platform (the fit uses `+ - * /` and `sqrt` and ordered iteration only).

## Clips, IK and retargeting

The bones of the `.rig.glb` are animated with `*.anim.json` 3D clips (`format` `factoria.anim3d/1`) that an `Animator` plays, and
bent by the `IK3D` component; all of it is described in [ANIMATION.md](ANIMATION.md) ("3D bone clips", "3D IK", "Generators",
"Retargeting", "Previewing a clip"). In short:

- `anim3d.generate {rig, kind}` writes a walk, run, trot, gallop, idle, swing or hit clip from the skeleton's proportions.
- `anim3d.retarget {path, to, out}` carries a clip to another rig by the (role, index, side) of its bones, keeping planted feet.
- `anim3d.preview {path, rig}` draws a filmstrip of the clip on the model without a window.
- Keep the same bone names in a rig that a clip names: re-fitting a rig (`rig.fit`) keeps them, but a different `options` (spine
  count, tail segments) changes which bones exist, and a clip that names one that is gone says so (`anim3d.info {path, rig}`).

## Limits and known gaps

- Weights are the rigid placeholder (see "Binding"); smooth weights and posing come with M59.2. A rigid binding bends at hard seams
  when a clip rotates a joint.
- The skeleton is the rest pose only, every bone with identity rotation: a bone has no roll or twist axis yet. A 3D clip rotates
  a bone in the model's axes, so the same angles bend any bone the same way whatever its direction.
- A textured model's rig uses the picture the model's own bake wrote. If the model is baked for the first time after the rig,
  bake the rig again (`rig.bake {"force": true}`): the rig only learns of the picture once it exists. `rig.bake` warns when a
  textured model has not been baked.
- A model document is the only thing a rig fits (not a `.glb` you imported); merged and LOD results are not used.
- At most 64 bones; the name of a bone of a generic rig is lowercase letters, digits and underscores.
