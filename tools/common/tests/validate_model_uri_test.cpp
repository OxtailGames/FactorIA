// project.validate: the uris of a glTF/glb are resolved against the model's folder and the message names the real path.
#include <doctest.h>

#include <filesystem>
#include <fstream>

#include "asset_test_helpers.h"
#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/validate.h"

using namespace fa;
using namespace fa::testing;
namespace stdfs = std::filesystem;

namespace {

struct ModelGame {
    TempDir tmp;
    std::string dir;

    ModelGame() {
        dir = tmp.sub("game");
        REQUIRE(create_project(dir, "2d-empty").ok());
    }
    void file(const std::string& rel, const std::string& text = "x") {
        const stdfs::path p = stdfs::path(dir) / rel;
        stdfs::create_directories(p.parent_path());
        std::ofstream(p, std::ios::binary) << text;
    }
    void model(const std::string& rel, const std::string& imageUri, const char* key = "images") {
        file(rel, std::string("{\"asset\":{\"version\":\"2.0\"},\"") + key + "\":[{\"uri\":\"" + imageUri + "\"}]}");
    }
    // The model-file errors of one model.
    std::vector<ValidationIssue> errors(const std::string& modelRel) const {
        std::vector<ValidationIssue> found;
        for (const ValidationIssue& e : validate_project(dir).errors)
            if (e.file == modelRel) found.push_back(e);
        return found;
    }
};

}  // namespace

TEST_CASE("validate model uri: a uri that climbs out of the project names the climb and the corrected uri") {
    ModelGame g;
    g.file("assets/textures/bookcloth.png");
    g.model("assets/models/book3d/book_closed.gltf", "../../../../assets/textures/bookcloth.png");
    const auto found = g.errors("assets/models/book3d/book_closed.gltf");
    REQUIRE(found.size() == 1);
    CHECK(found[0].pointer == "/images/0/uri");
    CHECK(found[0].message.find("climbs out of the project folder") != std::string::npos);
    CHECK(found[0].message.find("'assets/models/book3d/'") != std::string::npos);
    CHECK(found[0].message.find("does not exist") == std::string::npos);
    CHECK(found[0].hint.find("Did you mean '../../textures/bookcloth.png'") != std::string::npos);
    CHECK(found[0].hint.find("assets.import") != std::string::npos);
}

TEST_CASE("validate model uri: a missing file in an existing folder names the resolved path") {
    ModelGame g;
    g.model("assets/models/book3d/book.gltf", "tex/cloth.png");
    const auto found = g.errors("assets/models/book3d/book.gltf");
    REQUIRE(found.size() == 1);
    CHECK(found[0].message.find("'assets/models/book3d/tex/cloth.png' does not exist") != std::string::npos);
    CHECK(found[0].hint.find("Did you mean") == std::string::npos);
}

TEST_CASE("validate model uri: a same-name file elsewhere is suggested, several are listed") {
    ModelGame g;
    g.file("assets/textures/cloth.png");
    g.model("assets/models/book.gltf", "cloth.png");
    auto found = g.errors("assets/models/book.gltf");
    REQUIRE(found.size() == 1);
    CHECK(found[0].message.find("'assets/models/cloth.png' does not exist") != std::string::npos);
    CHECK(found[0].hint.find("Did you mean '../textures/cloth.png'") != std::string::npos);

    g.file("assets/other/cloth.png");
    found = g.errors("assets/models/book.gltf");
    REQUIRE(found.size() == 1);
    CHECK(found[0].hint.find("Files with that name") != std::string::npos);
    CHECK(found[0].hint.find("'../textures/cloth.png'") != std::string::npos);
    CHECK(found[0].hint.find("'../other/cloth.png'") != std::string::npos);
}

TEST_CASE("validate model uri: buffers get the same message") {
    ModelGame g;
    g.file("assets/bin/mesh.bin");
    g.model("assets/models/m/m.gltf", "../../../../assets/bin/mesh.bin", "buffers");
    const auto found = g.errors("assets/models/m/m.gltf");
    REQUIRE(found.size() == 1);
    CHECK(found[0].pointer == "/buffers/0/uri");
    CHECK(found[0].message.find("buffer") != std::string::npos);
    CHECK(found[0].hint.find("Did you mean '../../bin/mesh.bin'") != std::string::npos);
}

TEST_CASE("validate model uri: correct uris give no error, percent-encoded ones included") {
    ModelGame g;
    g.file("assets/textures/book cloth.png");
    g.file("assets/models/b/own.png");
    g.model("assets/models/b/a.gltf", "../../textures/book%20cloth.png");
    g.model("assets/models/b/c.gltf", "own.png");
    g.model("assets/models/b/d.gltf", "../../../assets/textures/book%20cloth.png");  // reaches the root, then back in
    CHECK(g.errors("assets/models/b/a.gltf").empty());
    CHECK(g.errors("assets/models/b/c.gltf").empty());
    CHECK(g.errors("assets/models/b/d.gltf").empty());
}
