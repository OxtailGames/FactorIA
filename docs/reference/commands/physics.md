[Back to the index](../README.md)

# Commands: physics

## `physics.raycast`

Cast a ray against colliders (2D segment or 3D ray) and return the first hit.

2D: {from:[x,y], to:[x,y]}. 3D: {dimension:"3d", origin:[x,y,z], direction:[x,y,z], maxDistance}. Options, the same as physics.shape_cast and the script API physics.raycast(a, b, {mask, ignore, ignoreTriggers}): mask = collision layer bit mask (bit i = layer i, -1 = all layers); ignore = id (or name) of an entity whose colliders, and its children's, are skipped (usually the caster, so a ray starting at a body's edge does not hit the body itself); ignoreTriggers (default true) skips trigger colliders, false hits them too. A collider that contains the ray origin is always skipped. Result: {hit:false} or {hit:true, entity, point, normal, distance}. Example: physics.raycast {"from":[0,300],"to":[0,-300],"ignore":"player","ignoreTriggers":false}

| Argument | Type | Required | Description |
|---|---|---|---|
| `dimension` | string ["2d","3d"] | no |  Default "2d". |
| `from` | array | no | 2D start [x,y]. |
| `to` | array | no | 2D end [x,y]. |
| `origin` | array | no | 3D origin [x,y,z]. |
| `direction` | array | no | 3D direction. |
| `maxDistance` | number | no |  Default 1000. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

## `physics.shape_cast`

Sweep a circle, sphere or box from one point to another and return the first collider it touches.

Like physics.raycast, but the shape has size: use it to ask whether a character fits or how far a box can move before it hits something. 2 numbers in from/to = 2D, 3 numbers = 3D. shape: 2D {"shape":"circle","radius":8} or {"shape":"box","size":[16,24]}; 3D {"shape":"sphere","radius":0.5} or {"shape":"box","size":[1,2,1]} (2D pixels, 3D meters, full sizes). The shape is centred on the cast position and axis-aligned. Result: {hit:false} or {hit:true, entity, point, normal, distance}: distance is how far the CENTRE travels before contact, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped (like a ray starting inside one); a collider it only touches blocks the cast only if it moves towards it. Options as for physics.raycast: mask; ignore = id of an entity whose colliders (and its children's) are skipped, usually the caster; triggers are skipped unless ignoreTriggers=false. Example: physics.shape_cast {"shape":{"shape":"box","size":[32,48]},"from":[0,100],"to":[0,-300],"ignore":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `shape` | object | yes | 2D: {shape:"circle",radius} or {shape:"box",size:[w,h]}. 3D: {shape:"sphere",radius} or {shape:"box",size:[x,y,z]}. |
| `from` | array | yes | Start of the shape's centre, [x,y] (2D) or [x,y,z] (3D). |
| `to` | array | yes | End of the shape's centre, same dimension as from. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

