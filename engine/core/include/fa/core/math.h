// FactorIA math library (header-only).
//
// Conventions — memorise these, every module and every script relies on them:
//   * Right-handed, +Y up. 3D cameras look down -Z. 2D: +X right, +Y up.
//   * Angles in the public API (components, JSON, scripts) are DEGREES.
//     Internal trig helpers take radians and say so in their name (_rad).
//   * Euler rotation vec3 = (pitch about X, yaw about Y, roll about Z) in degrees.
//     Rotation matrix R = Ry(yaw) * Rx(pitch) * Rz(roll). In 2D only .z matters.
//   * Mat4 is column-major (m[col * 4 + row]) and multiplies column vectors:
//     v' = M * v. Matrices compose right-to-left: world = parent * local.
//   * Clip space depth: pass `zero_to_one = true` for Metal/D3D11/WebGPU style
//     [0,1] depth, false for OpenGL [-1,1]. fa_render picks it per backend.
#pragma once

#include <algorithm>
#include <cmath>
#include <cstdint>

namespace fa {

inline constexpr float kPi = 3.14159265358979323846f;
inline constexpr float kTau = 2.0f * kPi;
inline constexpr float kDegToRad = kPi / 180.0f;
inline constexpr float kRadToDeg = 180.0f / kPi;
inline constexpr float kEpsilon = 1e-6f;

inline float radians(float deg) { return deg * kDegToRad; }
inline float degrees(float rad) { return rad * kRadToDeg; }
inline float clamp(float v, float lo, float hi) { return v < lo ? lo : (v > hi ? hi : v); }
inline float saturate(float v) { return clamp(v, 0.0f, 1.0f); }
inline float lerp(float a, float b, float t) { return a + (b - a) * t; }
inline float inverse_lerp(float a, float b, float v) { return (b - a) != 0.0f ? (v - a) / (b - a) : 0.0f; }
inline float remap(float v, float a0, float a1, float b0, float b1) { return lerp(b0, b1, inverse_lerp(a0, a1, v)); }
inline float sign(float v) { return v > 0.0f ? 1.0f : (v < 0.0f ? -1.0f : 0.0f); }
inline bool approx_equal(float a, float b, float eps = 1e-4f) { return std::fabs(a - b) <= eps; }
// Frame-rate independent exponential smoothing: move `current` toward `target`.
inline float damp(float current, float target, float smoothing, float dt) {
    return lerp(current, target, 1.0f - std::exp(-smoothing * dt));
}
inline float move_towards(float current, float target, float maxDelta) {
    if (std::fabs(target - current) <= maxDelta) return target;
    return current + sign(target - current) * maxDelta;
}
// Wraps an angle in degrees to (-180, 180].
inline float wrap_angle_deg(float a) {
    a = std::fmod(a + 180.0f, 360.0f);
    if (a < 0.0f) a += 360.0f;
    return a - 180.0f;
}

// ---------------------------------------------------------------------------
// Vec2
// ---------------------------------------------------------------------------
struct Vec2 {
    float x = 0, y = 0;

    constexpr Vec2() = default;
    constexpr Vec2(float x_, float y_) : x(x_), y(y_) {}
    constexpr explicit Vec2(float s) : x(s), y(s) {}

    float& operator[](int i) { return (&x)[i]; }
    float operator[](int i) const { return (&x)[i]; }
    constexpr Vec2 operator+(Vec2 o) const { return {x + o.x, y + o.y}; }
    constexpr Vec2 operator-(Vec2 o) const { return {x - o.x, y - o.y}; }
    constexpr Vec2 operator*(Vec2 o) const { return {x * o.x, y * o.y}; }
    constexpr Vec2 operator/(Vec2 o) const { return {x / o.x, y / o.y}; }
    constexpr Vec2 operator*(float s) const { return {x * s, y * s}; }
    constexpr Vec2 operator/(float s) const { return {x / s, y / s}; }
    constexpr Vec2 operator-() const { return {-x, -y}; }
    Vec2& operator+=(Vec2 o) { x += o.x; y += o.y; return *this; }
    Vec2& operator-=(Vec2 o) { x -= o.x; y -= o.y; return *this; }
    Vec2& operator*=(float s) { x *= s; y *= s; return *this; }
    Vec2& operator/=(float s) { x /= s; y /= s; return *this; }
    constexpr bool operator==(const Vec2&) const = default;
};
constexpr Vec2 operator*(float s, Vec2 v) { return v * s; }

inline float dot(Vec2 a, Vec2 b) { return a.x * b.x + a.y * b.y; }
inline float cross(Vec2 a, Vec2 b) { return a.x * b.y - a.y * b.x; }  // z of 3D cross
inline float length_sq(Vec2 v) { return dot(v, v); }
inline float length(Vec2 v) { return std::sqrt(dot(v, v)); }
inline float distance(Vec2 a, Vec2 b) { return length(b - a); }
inline Vec2 normalize(Vec2 v) { float l = length(v); return l > kEpsilon ? v / l : Vec2{}; }
inline Vec2 lerp(Vec2 a, Vec2 b, float t) { return a + (b - a) * t; }
inline Vec2 perp(Vec2 v) { return {-v.y, v.x}; }  // 90 deg counter-clockwise
inline Vec2 rotate_deg(Vec2 v, float deg) {
    float c = std::cos(radians(deg)), s = std::sin(radians(deg));
    return {v.x * c - v.y * s, v.x * s + v.y * c};
}
inline Vec2 from_angle_deg(float deg) { return {std::cos(radians(deg)), std::sin(radians(deg))}; }
inline float angle_deg(Vec2 v) { return degrees(std::atan2(v.y, v.x)); }
inline Vec2 min(Vec2 a, Vec2 b) { return {std::min(a.x, b.x), std::min(a.y, b.y)}; }
inline Vec2 max(Vec2 a, Vec2 b) { return {std::max(a.x, b.x), std::max(a.y, b.y)}; }
inline Vec2 clamp_length(Vec2 v, float maxLen) {
    float l = length(v);
    return l > maxLen && l > kEpsilon ? v * (maxLen / l) : v;
}
inline Vec2 move_towards(Vec2 cur, Vec2 target, float maxDelta) {
    Vec2 d = target - cur;
    float l = length(d);
    return (l <= maxDelta || l < kEpsilon) ? target : cur + d / l * maxDelta;
}

// ---------------------------------------------------------------------------
// Vec3
// ---------------------------------------------------------------------------
struct Vec3 {
    float x = 0, y = 0, z = 0;

    constexpr Vec3() = default;
    constexpr Vec3(float x_, float y_, float z_) : x(x_), y(y_), z(z_) {}
    constexpr explicit Vec3(float s) : x(s), y(s), z(s) {}
    constexpr Vec3(Vec2 v, float z_) : x(v.x), y(v.y), z(z_) {}

    constexpr Vec2 xy() const { return {x, y}; }
    float& operator[](int i) { return (&x)[i]; }
    float operator[](int i) const { return (&x)[i]; }
    constexpr Vec3 operator+(Vec3 o) const { return {x + o.x, y + o.y, z + o.z}; }
    constexpr Vec3 operator-(Vec3 o) const { return {x - o.x, y - o.y, z - o.z}; }
    constexpr Vec3 operator*(Vec3 o) const { return {x * o.x, y * o.y, z * o.z}; }
    constexpr Vec3 operator/(Vec3 o) const { return {x / o.x, y / o.y, z / o.z}; }
    constexpr Vec3 operator*(float s) const { return {x * s, y * s, z * s}; }
    constexpr Vec3 operator/(float s) const { return {x / s, y / s, z / s}; }
    constexpr Vec3 operator-() const { return {-x, -y, -z}; }
    Vec3& operator+=(Vec3 o) { x += o.x; y += o.y; z += o.z; return *this; }
    Vec3& operator-=(Vec3 o) { x -= o.x; y -= o.y; z -= o.z; return *this; }
    Vec3& operator*=(float s) { x *= s; y *= s; z *= s; return *this; }
    Vec3& operator/=(float s) { x /= s; y /= s; z /= s; return *this; }
    constexpr bool operator==(const Vec3&) const = default;
};
constexpr Vec3 operator*(float s, Vec3 v) { return v * s; }

inline float dot(Vec3 a, Vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
inline Vec3 cross(Vec3 a, Vec3 b) { return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x}; }
inline float length_sq(Vec3 v) { return dot(v, v); }
inline float length(Vec3 v) { return std::sqrt(dot(v, v)); }
inline float distance(Vec3 a, Vec3 b) { return length(b - a); }
inline Vec3 normalize(Vec3 v) { float l = length(v); return l > kEpsilon ? v / l : Vec3{}; }
inline Vec3 lerp(Vec3 a, Vec3 b, float t) { return a + (b - a) * t; }
inline Vec3 min(Vec3 a, Vec3 b) { return {std::min(a.x, b.x), std::min(a.y, b.y), std::min(a.z, b.z)}; }
inline Vec3 max(Vec3 a, Vec3 b) { return {std::max(a.x, b.x), std::max(a.y, b.y), std::max(a.z, b.z)}; }
inline Vec3 reflect(Vec3 v, Vec3 n) { return v - n * (2.0f * dot(v, n)); }
inline Vec3 move_towards(Vec3 cur, Vec3 target, float maxDelta) {
    Vec3 d = target - cur;
    float l = length(d);
    return (l <= maxDelta || l < kEpsilon) ? target : cur + d / l * maxDelta;
}

inline constexpr Vec3 kUp{0, 1, 0};
inline constexpr Vec3 kRight{1, 0, 0};
inline constexpr Vec3 kForward{0, 0, -1};  // default camera/object forward

// ---------------------------------------------------------------------------
// Vec4
// ---------------------------------------------------------------------------
struct Vec4 {
    float x = 0, y = 0, z = 0, w = 0;

    constexpr Vec4() = default;
    constexpr Vec4(float x_, float y_, float z_, float w_) : x(x_), y(y_), z(z_), w(w_) {}
    constexpr Vec4(Vec3 v, float w_) : x(v.x), y(v.y), z(v.z), w(w_) {}

    constexpr Vec3 xyz() const { return {x, y, z}; }
    float& operator[](int i) { return (&x)[i]; }
    float operator[](int i) const { return (&x)[i]; }
    constexpr Vec4 operator+(Vec4 o) const { return {x + o.x, y + o.y, z + o.z, w + o.w}; }
    constexpr Vec4 operator-(Vec4 o) const { return {x - o.x, y - o.y, z - o.z, w - o.w}; }
    constexpr Vec4 operator*(float s) const { return {x * s, y * s, z * s, w * s}; }
    constexpr bool operator==(const Vec4&) const = default;
};
inline float dot(Vec4 a, Vec4 b) { return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w; }
inline Vec4 lerp(Vec4 a, Vec4 b, float t) { return a + (b - a) * t; }

// ---------------------------------------------------------------------------
// Color — linear float RGBA in [0,1]. JSON accepts [r,g,b], [r,g,b,a],
// "#rgb", "#rrggbb", "#rrggbbaa" and a few CSS names (see fa/core/json.h).
// ---------------------------------------------------------------------------
struct Color {
    float r = 1, g = 1, b = 1, a = 1;

    constexpr Color() = default;
    constexpr Color(float r_, float g_, float b_, float a_ = 1.0f) : r(r_), g(g_), b(b_), a(a_) {}

    static constexpr Color rgba8(std::uint8_t r, std::uint8_t g, std::uint8_t b, std::uint8_t a = 255) {
        return {r / 255.0f, g / 255.0f, b / 255.0f, a / 255.0f};
    }
    static constexpr Color hex(std::uint32_t rgb, float a = 1.0f) {
        return {((rgb >> 16) & 0xff) / 255.0f, ((rgb >> 8) & 0xff) / 255.0f, (rgb & 0xff) / 255.0f, a};
    }
    constexpr Color with_alpha(float alpha) const { return {r, g, b, alpha}; }
    constexpr Vec4 to_vec4() const { return {r, g, b, a}; }
    std::uint32_t to_rgba8() const {  // packed little-endian 0xAABBGGRR
        auto c = [](float v) { return std::uint32_t(saturate(v) * 255.0f + 0.5f); };
        return c(r) | (c(g) << 8) | (c(b) << 16) | (c(a) << 24);
    }
    constexpr Color operator*(const Color& o) const { return {r * o.r, g * o.g, b * o.b, a * o.a}; }
    constexpr Color operator*(float s) const { return {r * s, g * s, b * s, a * s}; }
    constexpr bool operator==(const Color&) const = default;

    static constexpr Color white() { return {1, 1, 1, 1}; }
    static constexpr Color black() { return {0, 0, 0, 1}; }
    static constexpr Color clear() { return {0, 0, 0, 0}; }
    static constexpr Color red() { return {1, 0, 0, 1}; }
    static constexpr Color green() { return {0, 1, 0, 1}; }
    static constexpr Color blue() { return {0, 0, 1, 1}; }
};
inline Color lerp(Color a, Color b, float t) {
    return {lerp(a.r, b.r, t), lerp(a.g, b.g, t), lerp(a.b, b.b, t), lerp(a.a, b.a, t)};
}

// ---------------------------------------------------------------------------
// Rect — axis-aligned, (x, y) is the minimum corner. Used for sprite regions
// (pixels in texture space, top-left origin) and 2D bounds (world space).
// ---------------------------------------------------------------------------
struct Rect {
    float x = 0, y = 0, w = 0, h = 0;

    constexpr Rect() = default;
    constexpr Rect(float x_, float y_, float w_, float h_) : x(x_), y(y_), w(w_), h(h_) {}
    static constexpr Rect from_center(Vec2 c, Vec2 size) { return {c.x - size.x * 0.5f, c.y - size.y * 0.5f, size.x, size.y}; }

    constexpr Vec2 min() const { return {x, y}; }
    constexpr Vec2 max() const { return {x + w, y + h}; }
    constexpr Vec2 center() const { return {x + w * 0.5f, y + h * 0.5f}; }
    constexpr Vec2 size() const { return {w, h}; }
    constexpr bool empty() const { return w <= 0 || h <= 0; }
    constexpr bool contains(Vec2 p) const { return p.x >= x && p.y >= y && p.x <= x + w && p.y <= y + h; }
    constexpr bool overlaps(const Rect& o) const { return x < o.x + o.w && o.x < x + w && y < o.y + o.h && o.y < y + h; }
    constexpr bool operator==(const Rect&) const = default;
};

// ---------------------------------------------------------------------------
// Quat — unit quaternion (x, y, z, w). Mostly internal (glTF, slerp); the
// public API uses euler degrees.
// ---------------------------------------------------------------------------
struct Quat {
    float x = 0, y = 0, z = 0, w = 1;

    constexpr Quat() = default;
    constexpr Quat(float x_, float y_, float z_, float w_) : x(x_), y(y_), z(z_), w(w_) {}

    static Quat axis_angle_deg(Vec3 axis, float deg) {
        Vec3 a = normalize(axis);
        float h = radians(deg) * 0.5f, s = std::sin(h);
        return {a.x * s, a.y * s, a.z * s, std::cos(h)};
    }
    Quat operator*(const Quat& q) const {
        return {w * q.x + x * q.w + y * q.z - z * q.y,
                w * q.y - x * q.z + y * q.w + z * q.x,
                w * q.z + x * q.y - y * q.x + z * q.w,
                w * q.w - x * q.x - y * q.y - z * q.z};
    }
    Quat conjugate() const { return {-x, -y, -z, w}; }
    Vec3 rotate(Vec3 v) const {
        Vec3 u{x, y, z};
        Vec3 t = cross(u, v) * 2.0f;
        return v + t * w + cross(u, t);
    }
    // Same order as the Euler convention: q = qy * qx * qz.
    static Quat from_euler_deg(Vec3 e) {
        return axis_angle_deg({0, 1, 0}, e.y) * axis_angle_deg({1, 0, 0}, e.x) * axis_angle_deg({0, 0, 1}, e.z);
    }
    Vec3 to_euler_deg() const;  // defined below (needs Mat4-free math)
};
inline float dot(Quat a, Quat b) { return a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w; }
inline Quat normalize(Quat q) {
    float l = std::sqrt(dot(q, q));
    return l > kEpsilon ? Quat{q.x / l, q.y / l, q.z / l, q.w / l} : Quat{};
}
inline Quat slerp(Quat a, Quat b, float t) {
    float d = dot(a, b);
    if (d < 0.0f) { b = {-b.x, -b.y, -b.z, -b.w}; d = -d; }
    if (d > 0.9995f) {
        return normalize(Quat{lerp(a.x, b.x, t), lerp(a.y, b.y, t), lerp(a.z, b.z, t), lerp(a.w, b.w, t)});
    }
    float th = std::acos(d), s = std::sin(th);
    float wa = std::sin((1.0f - t) * th) / s, wb = std::sin(t * th) / s;
    return {a.x * wa + b.x * wb, a.y * wa + b.y * wb, a.z * wa + b.z * wb, a.w * wa + b.w * wb};
}
inline Vec3 Quat::to_euler_deg() const {
    // Inverse of R = Ry * Rx * Rz.
    float sinPitch = clamp(2.0f * (w * x - y * z), -1.0f, 1.0f);
    float pitch = std::asin(sinPitch);
    float yaw, roll;
    if (std::fabs(sinPitch) < 0.9999f) {
        yaw = std::atan2(2.0f * (x * z + w * y), 1.0f - 2.0f * (x * x + y * y));
        roll = std::atan2(2.0f * (x * y + w * z), 1.0f - 2.0f * (x * x + z * z));
    } else {  // gimbal lock: fold roll into yaw
        yaw = std::atan2(-2.0f * (x * z - w * y), 1.0f - 2.0f * (y * y + z * z));
        roll = 0.0f;
    }
    return {degrees(pitch), degrees(yaw), degrees(roll)};
}

// ---------------------------------------------------------------------------
// Mat4 — column-major, column vectors.
// ---------------------------------------------------------------------------
struct Mat4 {
    float m[16] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1};

    static constexpr Mat4 identity() { return {}; }
    float& at(int col, int row) { return m[col * 4 + row]; }
    float at(int col, int row) const { return m[col * 4 + row]; }
    const float* data() const { return m; }

    Mat4 operator*(const Mat4& o) const {
        Mat4 r;
        for (int c = 0; c < 4; ++c)
            for (int rr = 0; rr < 4; ++rr) {
                float s = 0;
                for (int k = 0; k < 4; ++k) s += at(k, rr) * o.at(c, k);
                r.at(c, rr) = s;
            }
        return r;
    }
    Vec4 operator*(const Vec4& v) const {
        return {at(0, 0) * v.x + at(1, 0) * v.y + at(2, 0) * v.z + at(3, 0) * v.w,
                at(0, 1) * v.x + at(1, 1) * v.y + at(2, 1) * v.z + at(3, 1) * v.w,
                at(0, 2) * v.x + at(1, 2) * v.y + at(2, 2) * v.z + at(3, 2) * v.w,
                at(0, 3) * v.x + at(1, 3) * v.y + at(2, 3) * v.z + at(3, 3) * v.w};
    }
    Vec3 transform_point(Vec3 p) const {
        Vec4 r = (*this) * Vec4{p, 1.0f};
        return std::fabs(r.w) > kEpsilon && r.w != 1.0f ? r.xyz() / r.w : r.xyz();
    }
    Vec3 transform_dir(Vec3 d) const { return ((*this) * Vec4{d, 0.0f}).xyz(); }
    Vec3 translation() const { return {at(3, 0), at(3, 1), at(3, 2)}; }

    static Mat4 translate(Vec3 t) {
        Mat4 r;
        r.at(3, 0) = t.x; r.at(3, 1) = t.y; r.at(3, 2) = t.z;
        return r;
    }
    static Mat4 scale(Vec3 s) {
        Mat4 r;
        r.at(0, 0) = s.x; r.at(1, 1) = s.y; r.at(2, 2) = s.z;
        return r;
    }
    static Mat4 rotate_x_deg(float deg) {
        float c = std::cos(radians(deg)), s = std::sin(radians(deg));
        Mat4 r;
        r.at(1, 1) = c; r.at(1, 2) = s; r.at(2, 1) = -s; r.at(2, 2) = c;
        return r;
    }
    static Mat4 rotate_y_deg(float deg) {
        float c = std::cos(radians(deg)), s = std::sin(radians(deg));
        Mat4 r;
        r.at(0, 0) = c; r.at(0, 2) = -s; r.at(2, 0) = s; r.at(2, 2) = c;
        return r;
    }
    static Mat4 rotate_z_deg(float deg) {
        float c = std::cos(radians(deg)), s = std::sin(radians(deg));
        Mat4 r;
        r.at(0, 0) = c; r.at(0, 1) = s; r.at(1, 0) = -s; r.at(1, 1) = c;
        return r;
    }
    static Mat4 from_quat(Quat q) {
        Mat4 r;
        float xx = q.x * q.x, yy = q.y * q.y, zz = q.z * q.z;
        float xy = q.x * q.y, xz = q.x * q.z, yz = q.y * q.z, wx = q.w * q.x, wy = q.w * q.y, wz = q.w * q.z;
        r.at(0, 0) = 1 - 2 * (yy + zz); r.at(0, 1) = 2 * (xy + wz);     r.at(0, 2) = 2 * (xz - wy);
        r.at(1, 0) = 2 * (xy - wz);     r.at(1, 1) = 1 - 2 * (xx + zz); r.at(1, 2) = 2 * (yz + wx);
        r.at(2, 0) = 2 * (xz + wy);     r.at(2, 1) = 2 * (yz - wx);     r.at(2, 2) = 1 - 2 * (xx + yy);
        return r;
    }
    // R = Ry(yaw) * Rx(pitch) * Rz(roll), euler = (pitch, yaw, roll) degrees.
    static Mat4 rotate_euler_deg(Vec3 e) { return rotate_y_deg(e.y) * rotate_x_deg(e.x) * rotate_z_deg(e.z); }
    // Translation * Rotation * Scale — the local matrix of a Transform component.
    static Mat4 trs(Vec3 t, Vec3 eulerDeg, Vec3 s) { return translate(t) * rotate_euler_deg(eulerDeg) * scale(s); }

    static Mat4 perspective(float fovYDeg, float aspect, float zNear, float zFar, bool zeroToOne) {
        float f = 1.0f / std::tan(radians(fovYDeg) * 0.5f);
        Mat4 r;
        r.m[0] = f / aspect; r.m[5] = f; r.m[15] = 0.0f; r.at(2, 3) = -1.0f;
        if (zeroToOne) {
            r.at(2, 2) = zFar / (zNear - zFar);
            r.at(3, 2) = (zNear * zFar) / (zNear - zFar);
        } else {
            r.at(2, 2) = (zFar + zNear) / (zNear - zFar);
            r.at(3, 2) = (2.0f * zFar * zNear) / (zNear - zFar);
        }
        return r;
    }
    static Mat4 ortho(float left, float right, float bottom, float top, float zNear, float zFar, bool zeroToOne) {
        Mat4 r;
        r.at(0, 0) = 2.0f / (right - left);
        r.at(1, 1) = 2.0f / (top - bottom);
        r.at(3, 0) = -(right + left) / (right - left);
        r.at(3, 1) = -(top + bottom) / (top - bottom);
        if (zeroToOne) {
            r.at(2, 2) = -1.0f / (zFar - zNear);
            r.at(3, 2) = -zNear / (zFar - zNear);
        } else {
            r.at(2, 2) = -2.0f / (zFar - zNear);
            r.at(3, 2) = -(zFar + zNear) / (zFar - zNear);
        }
        return r;
    }
    // View matrix for a camera at `eye` looking at `target`.
    static Mat4 look_at(Vec3 eye, Vec3 target, Vec3 up = kUp) {
        Vec3 f = normalize(target - eye);
        Vec3 s = normalize(cross(f, up));
        Vec3 u = cross(s, f);
        Mat4 r;
        r.at(0, 0) = s.x; r.at(1, 0) = s.y; r.at(2, 0) = s.z;
        r.at(0, 1) = u.x; r.at(1, 1) = u.y; r.at(2, 1) = u.z;
        r.at(0, 2) = -f.x; r.at(1, 2) = -f.y; r.at(2, 2) = -f.z;
        r.at(3, 0) = -dot(s, eye); r.at(3, 1) = -dot(u, eye); r.at(3, 2) = dot(f, eye);
        return r;
    }

    Mat4 transposed() const {
        Mat4 r;
        for (int c = 0; c < 4; ++c)
            for (int rr = 0; rr < 4; ++rr) r.at(c, rr) = at(rr, c);
        return r;
    }
    // General 4x4 inverse. Returns identity if the matrix is singular.
    Mat4 inverse() const {
        const float* a = m;
        float inv[16];
        inv[0] = a[5] * a[10] * a[15] - a[5] * a[11] * a[14] - a[9] * a[6] * a[15] + a[9] * a[7] * a[14] + a[13] * a[6] * a[11] - a[13] * a[7] * a[10];
        inv[4] = -a[4] * a[10] * a[15] + a[4] * a[11] * a[14] + a[8] * a[6] * a[15] - a[8] * a[7] * a[14] - a[12] * a[6] * a[11] + a[12] * a[7] * a[10];
        inv[8] = a[4] * a[9] * a[15] - a[4] * a[11] * a[13] - a[8] * a[5] * a[15] + a[8] * a[7] * a[13] + a[12] * a[5] * a[11] - a[12] * a[7] * a[9];
        inv[12] = -a[4] * a[9] * a[14] + a[4] * a[10] * a[13] + a[8] * a[5] * a[14] - a[8] * a[6] * a[13] - a[12] * a[5] * a[10] + a[12] * a[6] * a[9];
        inv[1] = -a[1] * a[10] * a[15] + a[1] * a[11] * a[14] + a[9] * a[2] * a[15] - a[9] * a[3] * a[14] - a[13] * a[2] * a[11] + a[13] * a[3] * a[10];
        inv[5] = a[0] * a[10] * a[15] - a[0] * a[11] * a[14] - a[8] * a[2] * a[15] + a[8] * a[3] * a[14] + a[12] * a[2] * a[11] - a[12] * a[3] * a[10];
        inv[9] = -a[0] * a[9] * a[15] + a[0] * a[11] * a[13] + a[8] * a[1] * a[15] - a[8] * a[3] * a[13] - a[12] * a[1] * a[11] + a[12] * a[3] * a[9];
        inv[13] = a[0] * a[9] * a[14] - a[0] * a[10] * a[13] - a[8] * a[1] * a[14] + a[8] * a[2] * a[13] + a[12] * a[1] * a[10] - a[12] * a[2] * a[9];
        inv[2] = a[1] * a[6] * a[15] - a[1] * a[7] * a[14] - a[5] * a[2] * a[15] + a[5] * a[3] * a[14] + a[13] * a[2] * a[7] - a[13] * a[3] * a[6];
        inv[6] = -a[0] * a[6] * a[15] + a[0] * a[7] * a[14] + a[4] * a[2] * a[15] - a[4] * a[3] * a[14] - a[12] * a[2] * a[7] + a[12] * a[3] * a[6];
        inv[10] = a[0] * a[5] * a[15] - a[0] * a[7] * a[13] - a[4] * a[1] * a[15] + a[4] * a[3] * a[13] + a[12] * a[1] * a[7] - a[12] * a[3] * a[5];
        inv[14] = -a[0] * a[5] * a[14] + a[0] * a[6] * a[13] + a[4] * a[1] * a[14] - a[4] * a[2] * a[13] - a[12] * a[1] * a[6] + a[12] * a[2] * a[5];
        inv[3] = -a[1] * a[6] * a[11] + a[1] * a[7] * a[10] + a[5] * a[2] * a[11] - a[5] * a[3] * a[10] - a[9] * a[2] * a[7] + a[9] * a[3] * a[6];
        inv[7] = a[0] * a[6] * a[11] - a[0] * a[7] * a[10] - a[4] * a[2] * a[11] + a[4] * a[3] * a[10] + a[8] * a[2] * a[7] - a[8] * a[3] * a[6];
        inv[11] = -a[0] * a[5] * a[11] + a[0] * a[7] * a[9] + a[4] * a[1] * a[11] - a[4] * a[3] * a[9] - a[8] * a[1] * a[7] + a[8] * a[3] * a[5];
        inv[15] = a[0] * a[5] * a[10] - a[0] * a[6] * a[9] - a[4] * a[1] * a[10] + a[4] * a[2] * a[9] + a[8] * a[1] * a[6] - a[8] * a[2] * a[5];
        float det = a[0] * inv[0] + a[1] * inv[4] + a[2] * inv[8] + a[3] * inv[12];
        Mat4 r;
        if (std::fabs(det) < 1e-12f) return r;
        float invDet = 1.0f / det;
        for (int i = 0; i < 16; ++i) r.m[i] = inv[i] * invDet;
        return r;
    }
};

// ---------------------------------------------------------------------------
// Deterministic RNG (PCG32). The engine seeds one per World from the project
// seed so headless runs and tests are reproducible. Never use rand().
// ---------------------------------------------------------------------------
class Rng {
public:
    Rng() { reseed(0x853c49e6748fea9bULL); }
    explicit Rng(std::uint64_t seed) { reseed(seed); }
    void reseed(std::uint64_t seed) {
        state_ = 0;
        next_u32();
        state_ += seed;
        next_u32();
    }
    std::uint32_t next_u32() {
        std::uint64_t old = state_;
        state_ = old * 6364136223846793005ULL + 1442695040888963407ULL;
        std::uint32_t xorshifted = std::uint32_t(((old >> 18u) ^ old) >> 27u);
        std::uint32_t rot = std::uint32_t(old >> 59u);
        return (xorshifted >> rot) | (xorshifted << ((~rot + 1u) & 31));
    }
    float next_float() { return (next_u32() >> 8) * (1.0f / 16777216.0f); }  // [0,1)
    float range(float lo, float hi) { return lo + (hi - lo) * next_float(); }
    int range_int(int lo, int hiInclusive) {
        if (hiInclusive <= lo) return lo;
        return lo + int(next_u32() % std::uint32_t(hiInclusive - lo + 1));
    }
    bool chance(float probability) { return next_float() < probability; }
    Vec2 unit_vec2() { return from_angle_deg(range(0.0f, 360.0f)); }
    std::uint64_t state() const { return state_; }

private:
    std::uint64_t state_ = 0;
};

}  // namespace fa
