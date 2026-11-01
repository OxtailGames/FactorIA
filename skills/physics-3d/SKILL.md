---
name: physics-3d
description: Rolling, colliders, sleeping and platforms in 3D. Read when building a 3D game.
---

# 3D physics and lighting

`RigidBody3D.angularVelocity`, `rollWithMotion` and `rollingFriction` (a rolling ball slows by that, not by
sliding friction; with `rollWithMotion` off a sphere is a rigid body that real friction rolls and spins);
box colliders follow `Transform.rotation` and fast bodies do not tunnel; dynamic boxes are
rigid bodies (collisions turn them: they tip, tumble and settle), so give a box-shaped character or an upright
crate `"lockRotation": true`; calm bodies fall asleep and wake when touched or written to; kinematic platforms
carry the bodies on them (3D, and 2D: a kinematic `RigidBody2D` with a script-set `velocity` carries the dynamic
bodies resting on it, and their own `velocity` is relative to the platform, so a player writing `velocity.x = 0`
stays put on it; moving the `Transform` instead teleports and carries nothing); `Shape2D.lit` shades a placeholder
shape with `Light2D` like `Sprite.lit`;
`Light.castShadows`; `settings.fogDensity` and `fogColor`.
