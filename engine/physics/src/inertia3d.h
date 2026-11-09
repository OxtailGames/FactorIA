// Private: the inertia of the solid shapes a dynamic 3D body can be (uniform density), as principal moments about the
// body's centre in the entity's own axes. A rigid body keeps one diagonal tensor (Physics3D::Body::invI), so each shape
// gives the moments about its three axes.
#pragma once

#include <vector>

#include "fa/core/math.h"
#include "shape3d.h"

namespace fa::detail {

// Solid capsule standing on Y: a cylinder of radius `radius` and height 2 * segHalf plus two hemispheres, the mass shared by
// volume. segHalf 0 is a sphere.
Vec3 capsule_inertia(float mass, float radius, float segHalf);

// The volume of a closed triangle mesh and the integrals of x^2, y^2 and z^2 over it (the second moments about the origin
// of its space), summed over the tetrahedra (origin, a, b, c) of every triangle. `indices` are counter-clockwise seen from
// outside, as ModelHull's are. Computed in double; the build compiles with -ffp-contract=off, so the answer is the same
// on every machine.
SolidMoments solid_moments(const std::vector<Vec3>& points, const std::vector<std::uint32_t>& indices);

// The inertia of a convex hull body of `mass` whose model is scaled per axis by `scale`, about the model's origin (the body
// turns about it: the origin is the centre of mass of a well-made model). False when the hull has no volume (the caller
// keeps the bounding box).
bool hull_inertia(float mass, const ShapeData& data, Vec3 scale, Vec3& out);

}  // namespace fa::detail
