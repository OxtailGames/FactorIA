// patch_pe_icon on PE files built in memory (pe_test_helpers.h): a resource tree with RT_ICON / RT_GROUP_ICON entries, a fake
// Authenticode certificate table at the end, 32- and 64-bit headers. No Windows toolchain needed.
#include <doctest.h>

#include "fa/tooling/icons.h"
#include "fa/tooling/pe_icon.h"
#include "pe_test_helpers.h"

using namespace fa;
using namespace fa::testing::pe;

TEST_CASE("pe_icon: the BMP icon images are replaced in place, the signature is cut and the checksum is recomputed") {
    const Image red = solid(64, 255, 0, 0), blue = solid(64, 0, 0, 255);
    for (bool pe32plus : {true, false}) {
        CAPTURE(pe32plus);
        PeOptions o;
        o.pe32plus = pe32plus;
        o.certificate = 72;
        PeFile pe = build_pe(placeholder_blobs(red), o);
        const Bytes before = pe.bytes;
        const std::size_t signedSize = before.size();

        auto r = patch_pe_icon(pe.bytes, blue);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        CHECK(r->replaced == 3);
        CHECK(r->sizes == std::vector<int>{16, 32, 48});
        CHECK(r->skipped == 1);  // the PNG image
        CHECK(r->signatureRemoved);
        CHECK(r->truncated);

        // Exactly the three BMP images changed, to the game icon at their own size.
        const int sizes[] = {16, 32, 48};
        for (int i = 0; i < 3; ++i) {
            const Bytes want = bmp(blue, sizes[i]);
            CHECK_MESSAGE(std::equal(want.begin(), want.end(), pe.bytes.begin() + std::ptrdiff_t(pe.blobOffset[i])), "image " << sizes[i]);
            CHECK_FALSE(std::equal(want.begin(), want.end(), before.begin() + std::ptrdiff_t(pe.blobOffset[i])));
        }
        // The PNG image, the icon group, the other resource type and the code are untouched.
        for (std::size_t i = 3; i < 6; ++i)
            CHECK(std::equal(before.begin() + std::ptrdiff_t(pe.blobOffset[i]), before.begin() + std::ptrdiff_t(pe.blobOffset[i] + 30),
                             pe.bytes.begin() + std::ptrdiff_t(pe.blobOffset[i])));
        CHECK(std::equal(before.begin() + std::ptrdiff_t(pe.textOffset), before.begin() + std::ptrdiff_t(pe.textOffset + pe.textSize),
                         pe.bytes.begin() + std::ptrdiff_t(pe.textOffset)));

        // The certificate table is gone: directory 4 cleared and the file ends where the table began.
        const std::size_t dirs = pe.optOffset + (pe32plus ? 112 : 96);
        CHECK(get32(before, dirs + 4 * 8 + 4) == 72);
        CHECK(get32(pe.bytes, dirs + 4 * 8) == 0);
        CHECK(get32(pe.bytes, dirs + 4 * 8 + 4) == 0);
        CHECK(pe.bytes.size() == signedSize - 72);
        CHECK(pe.bytes.size() == pe.endOfSections);

        // The checksum is the loader's.
        const std::uint32_t sum = get32(pe.bytes, pe.optOffset + 64);
        CHECK(sum == reference_checksum(pe.bytes, pe.optOffset + 64));
        CHECK(sum == pe_checksum(pe.bytes, pe.optOffset + 64));
        CHECK(sum != 0xDEADBEEF);

        // Patching again with the same icon changes nothing (no signature left to remove).
        const Bytes once = pe.bytes;
        auto again = patch_pe_icon(pe.bytes, blue);
        REQUIRE(again.ok());
        CHECK(again->replaced == 3);
        CHECK_FALSE(again->signatureRemoved);
        CHECK(pe.bytes == once);
    }
}

TEST_CASE("pe_icon: a table that does not end the file is cleared but not cut; an unsigned file only changes the icon and checksum") {
    const Image red = solid(64, 255, 0, 0), blue = solid(64, 0, 0, 255);
    {
        PeOptions o;
        o.certificate = 40;
        o.overlayAfter = 16;
        PeFile pe = build_pe(placeholder_blobs(red), o);
        const std::size_t size = pe.bytes.size();
        auto r = patch_pe_icon(pe.bytes, blue);
        REQUIRE(r.ok());
        CHECK(r->signatureRemoved);
        CHECK_FALSE(r->truncated);
        CHECK(pe.bytes.size() == size);
        CHECK(get32(pe.bytes, pe.optOffset + 112 + 4 * 8 + 4) == 0);
    }
    {
        PeFile pe = build_pe(placeholder_blobs(red));
        const std::size_t size = pe.bytes.size();
        auto r = patch_pe_icon(pe.bytes, blue);
        REQUIRE(r.ok());
        CHECK(r->replaced == 3);
        CHECK_FALSE(r->signatureRemoved);
        CHECK(pe.bytes.size() == size);
        CHECK(get32(pe.bytes, pe.optOffset + 64) == reference_checksum(pe.bytes, pe.optOffset + 64));
    }
}

TEST_CASE("pe_icon: a player without the placeholder icon is left exactly as it was") {
    const Image blue = solid(64, 0, 0, 255), red = solid(64, 255, 0, 0);
    {
        // No resources at all.
        PeOptions o;
        o.resources = false;
        o.certificate = 24;
        PeFile pe = build_pe({}, o);
        const Bytes before = pe.bytes;
        auto r = patch_pe_icon(pe.bytes, blue);
        REQUIRE(r.ok());
        CHECK(r->replaced == 0);
        CHECK_FALSE(r->signatureRemoved);
        CHECK(pe.bytes == before);  // signature and stale checksum included
    }
    {
        // Resources, but only PNG icons, a 24-bit BMP and a BMP whose length is not the placeholder's.
        Bytes bmp24 = bmp(red, 32);
        put16(bmp24, 14, 24);
        Bytes wrongLength = bmp(red, 32);
        wrongLength.push_back(0);
        PeOptions o;
        o.certificate = 24;
        PeFile pe = build_pe({{3, 1, png_blob()}, {3, 2, bmp24}, {3, 3, wrongLength}, {14, 1, Bytes(20, 1)}}, o);
        const Bytes before = pe.bytes;
        auto r = patch_pe_icon(pe.bytes, blue);
        REQUIRE(r.ok());
        CHECK(r->replaced == 0);
        CHECK(r->skipped == 3);
        CHECK(pe.bytes == before);
    }
}

TEST_CASE("pe_icon: a file that is not a PE, or has a damaged resource table, is an error that teaches and changes nothing") {
    const Image blue = solid(64, 0, 0, 255);
    {
        Bytes script = {'#', '!', '/', 'b', 'i', 'n', '/', 's', 'h', '\n', 'e', 'x', 'i', 't', '\n'};
        const Bytes before = script;
        auto r = patch_pe_icon(script, blue);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("not a Windows executable") != std::string::npos);
        CHECK(r.error().hint.find("--player") != std::string::npos);
        CHECK(script == before);
    }
    {
        Bytes noPe(0x100, 0);
        noPe[0] = 'M', noPe[1] = 'Z';
        put32(noPe, 0x3C, 0x80);
        auto r = patch_pe_icon(noPe, blue);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("no PE header") != std::string::npos);
        Bytes truncated(10, 0);
        CHECK_FALSE(patch_pe_icon(truncated, blue).ok());
    }
    {
        // A data entry whose RVA points outside every section.
        PeFile pe = build_pe(placeholder_blobs(solid(64, 255, 0, 0)));
        const std::size_t rsrcRaw = 0x400;
        // The first data entry sits after the directories: find it by scanning for the RVA of the first image.
        const std::uint32_t firstImageRva = 0x2000 + std::uint32_t(pe.blobOffset[0] - rsrcRaw);
        std::size_t at = 0;
        for (std::size_t i = rsrcRaw; i + 4 <= pe.bytes.size(); i += 4)
            if (get32(pe.bytes, i) == firstImageRva) {
                at = i;
                break;
            }
        REQUIRE(at != 0);
        put32(pe.bytes, at, 0x90000);
        const Bytes before = pe.bytes;
        auto r = patch_pe_icon(pe.bytes, blue);
        REQUIRE_FALSE(r.ok());
        CHECK(r.error().message.find("resource table is damaged") != std::string::npos);
        CHECK_FALSE(r.error().hint.empty());
        CHECK(pe.bytes == before);
    }
    {
        // An empty icon image cannot be rendered.
        PeFile pe = build_pe(placeholder_blobs(solid(64, 255, 0, 0)));
        CHECK_FALSE(patch_pe_icon(pe.bytes, Image{}).ok());
    }
}

TEST_CASE("pe_icon: pe_checksum matches the loader's algorithm for odd lengths and any content") {
    Bytes b(1001);
    std::uint32_t x = 12345;
    for (auto& v : b) x = x * 1664525u + 1013904223u, v = std::uint8_t(x >> 24);
    for (std::size_t csOffset : {std::size_t(0), std::size_t(64), std::size_t(996)}) {
        CHECK(pe_checksum(b, csOffset) == reference_checksum(b, csOffset));
        b.push_back(0xFF);
        b.push_back(0xFF);
        CHECK(pe_checksum(b, csOffset) == reference_checksum(b, csOffset));
    }
    Bytes allOnes(64, 0xFF);  // the sum that wraps the most
    CHECK(pe_checksum(allOnes, 0) == reference_checksum(allOnes, 0));
}
