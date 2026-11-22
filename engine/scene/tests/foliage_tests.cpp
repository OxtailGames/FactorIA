// M75-P6a: the instances file of a Foliage (fa/scene/foliage.h): the layout, the round trip and every error a reader gives.
#include <doctest.h>

#include <cmath>
#include <cstring>
#include <filesystem>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/scene/foliage.h"

using namespace fa;

namespace {

std::vector<FoliageInstance> sample(std::size_t n, std::uint16_t meshes) {
    std::vector<FoliageInstance> v(n);
    for (std::size_t i = 0; i < n; ++i) {
        v[i].position = {float(i) * 1.5f - 20.0f, float(i % 7) * 0.25f, -float(i) * 0.75f};
        v[i].yaw = float(i) * 0.3f;
        v[i].scale = 0.5f + float(i % 5) * 0.25f;
        v[i].mesh = std::uint16_t(i % meshes);
        if (i % 3 == 0) v[i].up = normalize(Vec3{0.3f, 1.0f, -0.2f});
    }
    return v;
}

std::string error_of(const Result<std::vector<FoliageInstance>>& r) {
    REQUIRE_FALSE(r.ok());
    return r.error().message + " | " + r.error().hint;
}

bool has(const std::string& text, const std::string& part) { return text.find(part) != std::string::npos; }

}  // namespace

TEST_CASE("foliage file: the size is 16 + 26 bytes per instance and the header is little endian") {
    const auto bytes = encode_foliage(sample(3, 2), 2);
    REQUIRE(bytes.ok());
    CHECK(bytes->size() == 16 + 26 * 3);
    CHECK(foliage_file_bytes(3) == bytes->size());
    CHECK(std::memcmp(bytes->data(), "FAFO", 4) == 0);
    CHECK((*bytes)[4] == 1);  // version, low byte first
    CHECK((*bytes)[5] == 0);
    CHECK((*bytes)[8] == 3);  // count
    CHECK((*bytes)[9] == 0);
    CHECK((*bytes)[12] == 2);  // meshCount
}

TEST_CASE("foliage file: an encoded file decodes to the same instances") {
    const std::vector<FoliageInstance> in = sample(50, 3);
    const auto bytes = encode_foliage(in, 3);
    REQUIRE(bytes.ok());
    const auto out = decode_foliage(bytes->data(), bytes->size(), 3);
    REQUIRE(out.ok());
    REQUIRE(out->size() == in.size());
    for (std::size_t i = 0; i < in.size(); ++i) {
        CAPTURE(i);
        CHECK((*out)[i].position.x == in[i].position.x);
        CHECK((*out)[i].position.y == in[i].position.y);
        CHECK((*out)[i].position.z == in[i].position.z);
        CHECK((*out)[i].yaw == in[i].yaw);
        CHECK((*out)[i].scale == in[i].scale);
        CHECK((*out)[i].mesh == in[i].mesh);
        CHECK(std::fabs((*out)[i].up.x - in[i].up.x) < 0.02f);  // 1/127 steps
        CHECK(std::fabs((*out)[i].up.y - in[i].up.y) < 0.02f);
        CHECK(std::fabs((*out)[i].up.z - in[i].up.z) < 0.02f);
        CHECK(std::fabs(length((*out)[i].up) - 1.0f) < 1e-4f);
    }
}

TEST_CASE("foliage file: an empty file is valid, and a zero up axis reads as upright") {
    const auto none = encode_foliage({}, 1);
    REQUIRE(none.ok());
    const auto back = decode_foliage(none->data(), none->size(), 1);
    REQUIRE(back.ok());
    CHECK(back->empty());

    FoliageInstance f;
    f.up = {0, 0, 0};
    const auto bytes = encode_foliage({f}, 1);
    REQUIRE(bytes.ok());
    const auto out = decode_foliage(bytes->data(), bytes->size(), 1);
    REQUIRE(out.ok());
    CHECK((*out)[0].up.y == doctest::Approx(1.0f));
}

TEST_CASE("foliage file: write_foliage and read_foliage go through a file") {
    auto dir = fs::make_temp_dir("fa_foliage");
    REQUIRE(dir.ok());
    const std::string file = fs::path_to_utf8(*dir / fs::path_from_utf8("trees.foliage"));
    const auto in = sample(10, 2);
    REQUIRE(write_foliage(file, in, 2).ok());
    const auto out = read_foliage(file, 2);
    REQUIRE(out.ok());
    CHECK(out->size() == 10);
    const auto missing = read_foliage(fs::path_to_utf8(*dir / fs::path_from_utf8("missing.foliage")), 2);
    REQUIRE_FALSE(missing.ok());
    CHECK(has(missing.error().message, "missing.foliage"));
    CHECK_FALSE(missing.error().hint.empty());
    std::error_code ec;
    std::filesystem::remove_all(*dir, ec);
}

TEST_CASE("foliage file: a file shorter than its header says it is cut off, with the byte it ends at") {
    const auto bytes = encode_foliage(sample(4, 1), 1);
    REQUIRE(bytes.ok());
    SUBCASE("inside the header") {
        const std::string e = error_of(decode_foliage(bytes->data(), 7, 1, "forest.foliage"));
        CHECK(has(e, "forest.foliage"));
        CHECK(has(e, "byte 7"));
        CHECK(has(e, "header"));
        CHECK(has(e, "Write the file again"));
    }
    SUBCASE("inside the records") {
        const std::size_t size = bytes->size() - 10;
        const std::string e = error_of(decode_foliage(bytes->data(), size, 1, "forest.foliage"));
        CHECK(has(e, "byte " + std::to_string(size)));
        CHECK(has(e, "cut off"));
        CHECK(has(e, "4 instances"));
        CHECK(has(e, "3 whole instances"));
    }
    SUBCASE("no bytes at all") {
        const std::string e = error_of(decode_foliage(bytes->data(), 0, 1));
        CHECK(has(e, "byte 0"));
        CHECK(has(e, "foliage data"));  // no file name was given
    }
}

TEST_CASE("foliage file: bytes after the last record are an error") {
    auto bytes = encode_foliage(sample(2, 1), 1);
    REQUIRE(bytes.ok());
    bytes->push_back(0);
    bytes->push_back(0);
    const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
    CHECK(has(e, "byte " + std::to_string(foliage_file_bytes(2))));
    CHECK(has(e, "2 bytes follow"));
}

TEST_CASE("foliage file: a wrong magic names byte 0 and what the file must be") {
    auto bytes = encode_foliage(sample(1, 1), 1);
    REQUIRE(bytes.ok());
    (*bytes)[0] = 'X';
    const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "notes.txt"));
    CHECK(has(e, "notes.txt"));
    CHECK(has(e, "byte 0"));
    CHECK(has(e, "FAFO"));
    CHECK(has(e, "foliage.scatter"));
}

TEST_CASE("foliage file: a version this engine does not read says whether the file is newer") {
    auto bytes = encode_foliage(sample(1, 1), 1);
    REQUIRE(bytes.ok());
    SUBCASE("newer") {
        (*bytes)[4] = 9;
        const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
        CHECK(has(e, "byte 4"));
        CHECK(has(e, "version 9"));
        CHECK(has(e, "newer FactorIA"));
    }
    SUBCASE("older") {
        (*bytes)[4] = 0;
        const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
        CHECK(has(e, "version 0"));
        CHECK_FALSE(has(e, "newer FactorIA"));
    }
    SUBCASE("flags") {
        (*bytes)[6] = 1;
        const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
        CHECK(has(e, "byte 6"));
        CHECK(has(e, "flags"));
    }
}

TEST_CASE("foliage file: a count past the most one file holds is refused before anything is read") {
    auto bytes = encode_foliage(sample(1, 1), 1);
    REQUIRE(bytes.ok());
    const std::uint32_t count = kMaxFoliageInstances + 1;
    for (int i = 0; i < 4; ++i) (*bytes)[8 + std::size_t(i)] = std::uint8_t(count >> (8 * i));
    const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
    CHECK(has(e, "byte 8"));
    CHECK(has(e, std::to_string(count)));
}

TEST_CASE("foliage file: a mesh index past Foliage.meshes names the instance, the byte and the count the file was "
          "written for") {
    std::vector<FoliageInstance> in = sample(5, 3);
    in[2].mesh = 0;
    in[4].mesh = 2;
    const auto bytes = encode_foliage(in, 3);
    REQUIRE(bytes.ok());
    CHECK(decode_foliage(bytes->data(), bytes->size(), 3).ok());
    const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 2, "f.foliage"));
    CHECK(has(e, "instance 4"));
    CHECK(has(e, "mesh index 2"));
    CHECK(has(e, "2 mesh(es)"));
    CHECK(has(e, "written for 3"));
    CHECK(has(e, "byte " + std::to_string(foliage_file_bytes(4) + 20)));
}

TEST_CASE("foliage file: a damaged number or a scale that is not above 0 is refused with its byte") {
    auto bytes = encode_foliage(sample(3, 1), 1);
    REQUIRE(bytes.ok());
    SUBCASE("NaN position") {
        const float nan = std::nanf("");
        std::memcpy(bytes->data() + foliage_file_bytes(1) + 4, &nan, 4);
        const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
        CHECK(has(e, "instance 1"));
        CHECK(has(e, "not a finite number"));
        CHECK(has(e, "byte " + std::to_string(foliage_file_bytes(1))));
    }
    SUBCASE("scale 0") {
        const float zero = 0.0f;
        std::memcpy(bytes->data() + foliage_file_bytes(2) + 16, &zero, 4);
        const std::string e = error_of(decode_foliage(bytes->data(), bytes->size(), 1, "f.foliage"));
        CHECK(has(e, "instance 2"));
        CHECK(has(e, "scale"));
        CHECK(has(e, "byte " + std::to_string(foliage_file_bytes(2) + 16)));
    }
}

TEST_CASE("foliage file: the writer refuses what the reader would refuse, with the instance's path") {
    SUBCASE("mesh past meshCount") {
        std::vector<FoliageInstance> in = sample(3, 1);
        in[2].mesh = 1;
        const auto r = encode_foliage(in, 1);
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "/instances/2"));
        CHECK(has(r.error().message, "mesh index 1"));
    }
    SUBCASE("scale") {
        std::vector<FoliageInstance> in = sample(2, 1);
        in[1].scale = -1.0f;
        const auto r = encode_foliage(in, 1);
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "/instances/1"));
        CHECK(has(r.error().message, "scale"));
    }
    SUBCASE("NaN") {
        std::vector<FoliageInstance> in = sample(2, 1);
        in[0].yaw = std::nanf("");
        const auto r = encode_foliage(in, 1);
        REQUIRE_FALSE(r.ok());
        CHECK(has(r.error().message, "/instances/0"));
    }
    SUBCASE("no meshes") { CHECK_FALSE(encode_foliage({}, 0).ok()); }
}
