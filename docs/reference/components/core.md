[Back to the index](../README.md)

# Components: Core

## EntityInfo

Identity of an entity; present on every entity. In scene files these fields are the entity's top-level keys (id, name, tags, active), not a component entry. Tags are handled by the scene serializer.

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | string | `""` | Stable unique string id within the scene (e.g. "player"). Used to reference the entity from Entity fields, scripts (world.find) and tools. Auto-generated ("e1", "e2"...) if omitted. |
| `name` | string | `""` | Display name shown in the editor and logs. Not unique. |
| `active` | bool | `true` | If false the entity and all its children are skipped by rendering, physics, audio and scripts. |

## Interpolation

Not released yet (on main after 0.29.1).

Draws this entity at the pose BETWEEN the last two fixed simulation steps, so a 60 Hz simulation moves smoothly on a 120-144 Hz display (docs/RENDERING.md, "Render interpolation"). Only the drawing changes: Transform, physics, scripts, bounds and commands always see the real, latest pose; the blend is never written to the Transform. Children follow an interpolated parent and a Camera is viewed from its blended pose. A pose set outside the fixed step (a script's update, a command) or after entity.teleport() is not smeared: it is drawn where it is. The project default is factoria.json render.interpolation (false); add this component to opt one entity in ("on") or out ("off"). Nothing is blended while the game is paused or stepped.

| Field | Type | Default | Description |
|---|---|---|---|
| `mode` | enum: inherit \| on \| off | `"on"` | on: interpolated whatever the project says. off: never interpolated (a cursor that must follow the pointer at once, an entity a script moves every frame). inherit: what factoria.json render.interpolation says. |

## Transform

Position, rotation and scale of an entity relative to its parent. Present on every entity. 2D uses x/y of position and the z angle of rotation; 3D units are meters.

| Field | Type | Default | Description |
|---|---|---|---|
| `position` | vec3 | `[0.0,0.0,0.0]` | Local position relative to the parent [x, y, z]. 2D: x right, y up, z is only used for depth ordering of 3D content. Units: world units (design pixels in 2D, meters in 3D). |
| `rotation` | vec3 | `[0.0,0.0,0.0]` | Local rotation as euler angles in DEGREES [pitch around X, yaw around Y, roll around Z], applied in the order Y, X, Z. 2D games only use the z value (counter-clockwise). |
| `scale` | vec3 | `[1.0,1.0,1.0]` | Local scale [x, y, z]. 1 = original size; negative values mirror. |

