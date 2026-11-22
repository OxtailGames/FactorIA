#include "fa/scene/foliage.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <format>

#include "fa/core/fs.h"

namespace fa {

namespace {

constexpr char kMagic[4] = {'F', 'A', 'F', 'O'};

void put16(std::uint8_t* p, std::uint16_t v) {
    p[0] = std::uint8_t(v & 0xff);
    p[1] = std::uint8_t(v >> 8);
}
void put32(std::uint8_t* p, std::uint32_t v) {
    for (int i = 0; i < 4; ++i) p[i] = std::uint8_t(v >> (8 * i));
}
void putf(std::uint8_t* p, float f) {
    std::uint32_t u;
    std::memcpy(&u, &f, sizeof u);
    put32(p, u);
}
std::uint16_t get16(const std::uint8_t* p) { return std::uint16_t(p[0] | (p[1] << 8)); }
std::uint32_t get32(const std::uint8_t* p) {
    return std::uint32_t(p[0]) | std::uint32_t(p[1]) << 8 | std::uint32_t(p[2]) << 16 | std::uint32_t(p[3]) << 24;
}
float getf(const std::uint8_t* p) {
    const std::uint32_t u = get32(p);
    float f;
    std::memcpy(&f, &u, sizeof f);
    return f;
}

std::string where(std::string_view file) { return file.empty() ? std::string("foliage data") : "foliage file '" + std::string(file) + "'"; }

Error fail(std::string_view file, std::size_t offset, const std::string& what, const std::string& hint) {
    return Error{std::format("{} at byte {}: {}", where(file), offset, what), hint};
}

std::int8_t quantise(float v) { return std::int8_t(std::lround(std::clamp(v, -1.0f, 1.0f) * 127.0f)); }

}  // namespace

Result<std::vector<std::uint8_t>> encode_foliage(const std::vector<FoliageInstance>& instances, std::uint32_t meshCount) {
    if (instances.size() > kMaxFoliageInstances)
        return Error{std::format("foliage data has {} instances, but one file holds at most {}", instances.size(),
                                 kMaxFoliageInstances),
                     "Split them over several Foliage entities (each with its own file): they are also culled and faded separately."};
    if (meshCount == 0 || meshCount > 65535)
        return Error{std::format("foliage data is written for {} meshes, but it must be 1 to 65535 (a Foliage has at most 16)", meshCount),
                     "Pass Foliage.meshes.size()."};
    std::vector<std::uint8_t> out(foliage_file_bytes(instances.size()), 0);
    std::memcpy(out.data(), kMagic, 4);
    put16(out.data() + 4, kFoliageVersion);
    put16(out.data() + 6, 0);
    put32(out.data() + 8, std::uint32_t(instances.size()));
    put32(out.data() + 12, meshCount);
    std::uint8_t* p = out.data() + kFoliageHeaderBytes;
    for (std::size_t i = 0; i < instances.size(); ++i, p += kFoliageRecordBytes) {
        const FoliageInstance& in = instances[i];
        const std::string at = "/instances/" + std::to_string(i);
        if (!std::isfinite(in.position.x) || !std::isfinite(in.position.y) || !std::isfinite(in.position.z) ||
            !std::isfinite(in.yaw) || !std::isfinite(in.scale) || !std::isfinite(in.up.x) || !std::isfinite(in.up.y) ||
            !std::isfinite(in.up.z))
            return Error{std::format("{}: the position, yaw, scale or up axis is not a finite number", at),
                         "A NaN or infinity came out of a calculation; fix it before writing."};
        if (!(in.scale > 0.0f))
            return Error{std::format("{}: scale is {}, it must be above 0", at, in.scale), "Use a positive uniform scale such as 1."};
        if (in.mesh >= meshCount)
            return Error{std::format("{}: mesh index {} is not below the {} meshes of the Foliage", at, in.mesh, meshCount),
                         "A mesh index counts from 0 in Foliage.meshes."};
        putf(p, in.position.x);
        putf(p + 4, in.position.y);
        putf(p + 8, in.position.z);
        putf(p + 12, in.yaw);
        putf(p + 16, in.scale);
        put16(p + 20, in.mesh);
        // (0, 1, 0) is upright and stored as the zero vector would also read: keep it explicit so a reader needs no special case
        const float len = std::sqrt(in.up.x * in.up.x + in.up.y * in.up.y + in.up.z * in.up.z);
        const Vec3 u = len > 1e-6f ? Vec3{in.up.x / len, in.up.y / len, in.up.z / len} : Vec3{0, 1, 0};
        p[22] = std::uint8_t(quantise(u.x));
        p[23] = std::uint8_t(quantise(u.y));
        p[24] = std::uint8_t(quantise(u.z));
        p[25] = 0;
    }
    return out;
}

Result<std::vector<FoliageInstance>> decode_foliage(const std::uint8_t* data, std::size_t size, std::size_t meshes,
                                                    std::string_view file) {
    if (size < kFoliageHeaderBytes)
        return fail(file, size, std::format("the file has {} bytes but the header alone takes {}: it is cut off or not a foliage file", size, kFoliageHeaderBytes),
                    "Write the file again with foliage.scatter or foliage.paint.");
    if (std::memcmp(data, kMagic, 4) != 0)
        return fail(file, 0, "it does not start with the foliage magic \"FAFO\": this is not a foliage instances file",
                    "Foliage.instances must name a file written by foliage.scatter or foliage.paint (fa::write_foliage).");
    const std::uint16_t version = get16(data + 4);
    if (version != kFoliageVersion)
        return fail(file, 4, std::format("version {} is not one this engine reads (it reads {})", version, kFoliageVersion),
                    version > kFoliageVersion ? "The file comes from a newer FactorIA: update the engine, or write the file again with this one."
                                              : "Write the file again with foliage.scatter or foliage.paint.");
    const std::uint16_t flags = get16(data + 6);
    if (flags != 0)
        return fail(file, 6, std::format("flags are {} but version 1 defines none", flags), "Write the file again with foliage.scatter or foliage.paint.");
    const std::uint32_t count = get32(data + 8);
    const std::uint32_t writtenFor = get32(data + 12);
    if (count > kMaxFoliageInstances)
        return fail(file, 8, std::format("the header says {} instances, more than the {} one file holds", count, kMaxFoliageInstances),
                    "The header is damaged, or the data was made for something else. Write the file again, or split the instances over several Foliage entities.");
    const std::size_t expected = foliage_file_bytes(count);
    if (size < expected) {
        const std::size_t whole = (size - kFoliageHeaderBytes) / kFoliageRecordBytes;
        return fail(file, size, std::format("the file is cut off: the header promises {} instances ({} bytes) but only {} bytes are there ({} whole instances)", count, expected, size, whole),
                    "The write was interrupted or the file was copied only in part: write it again with foliage.scatter or foliage.paint.");
    }
    if (size > expected)
        return fail(file, expected, std::format("{} bytes follow the {} instances of the header", size - expected, count),
                    "The file has data nobody wrote: write it again with foliage.scatter or foliage.paint.");
    std::vector<FoliageInstance> out(count);
    const std::uint8_t* p = data + kFoliageHeaderBytes;
    for (std::uint32_t i = 0; i < count; ++i, p += kFoliageRecordBytes) {
        const std::size_t at = kFoliageHeaderBytes + std::size_t(i) * kFoliageRecordBytes;
        FoliageInstance& in = out[i];
        in.position = {getf(p), getf(p + 4), getf(p + 8)};
        in.yaw = getf(p + 12);
        in.scale = getf(p + 16);
        in.mesh = get16(p + 20);
        if (!std::isfinite(in.position.x) || !std::isfinite(in.position.y) || !std::isfinite(in.position.z) || !std::isfinite(in.yaw) || !std::isfinite(in.scale))
            return fail(file, at, std::format("instance {} has a position, yaw or scale that is not a finite number", i), "The file is damaged: write it again.");
        if (!(in.scale > 0.0f))
            return fail(file, at + 16, std::format("instance {} has scale {}, it must be above 0", i, in.scale), "The file is damaged: write it again.");
        if (in.mesh >= meshes)
            return fail(file, at + 20, std::format("instance {} uses mesh index {}, but Foliage.meshes has {} mesh(es) (the file was written for {})", i, in.mesh, meshes, writtenFor),
                        "Add the missing meshes to Foliage.meshes in the order the file was written for, or scatter again.");
        const float nx = float(std::int8_t(p[22])), ny = float(std::int8_t(p[23])), nz = float(std::int8_t(p[24]));
        const float len = std::sqrt(nx * nx + ny * ny + nz * nz);
        in.up = len > 0.0f ? Vec3{nx / len, ny / len, nz / len} : Vec3{0, 1, 0};
    }
    return out;
}

Result<std::vector<FoliageInstance>> read_foliage(std::string_view path, std::size_t meshes) {
    auto bytes = fs::read_bytes(path);
    if (!bytes) return Error{std::format("foliage file '{}' cannot be read: {}", path, bytes.error().message), bytes.error().hint.empty() ? "Check the path in Foliage.instances." : bytes.error().hint};
    return decode_foliage(bytes->data(), bytes->size(), meshes, path);
}

Result<void> write_foliage(std::string_view path, const std::vector<FoliageInstance>& instances, std::uint32_t meshCount) {
    auto bytes = encode_foliage(instances, meshCount);
    if (!bytes) return bytes.error();
    return fs::write_bytes(path, bytes->data(), bytes->size());
}

}  // namespace fa
