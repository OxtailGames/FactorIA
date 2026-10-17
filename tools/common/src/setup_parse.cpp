#include "fa/tooling/setup_parse.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>

#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"

namespace fa {

namespace {

bool starts_with_sv(std::string_view s, std::string_view prefix) { return s.substr(0, prefix.size()) == prefix; }

bool is_hex(std::string_view s, std::size_t length) {
    if (s.size() != length) return false;
    return std::all_of(s.begin(), s.end(), [](char c) { return std::isxdigit(static_cast<unsigned char>(c)) != 0; });
}

std::string lower(std::string s) {
    for (char& c : s) c = char(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

std::string str_of(const Json& j, const char* key) {
    auto it = j.find(key);
    return it != j.end() && it->is_string() ? it->get<std::string>() : std::string();
}

std::uint64_t size_of(const Json& j, const char* key) {
    auto it = j.find(key);
    return it != j.end() && it->is_number_unsigned() ? it->get<std::uint64_t>() : 0;
}

// ---- tiny XML scanning ------------------------------------------------------------------------------------

// Position of the next "<tag" followed by whitespace, '>' or '/', at or after `from`; npos when there is none.
std::size_t find_open_tag(std::string_view xml, std::string_view tag, std::size_t from) {
    const std::string needle = "<" + std::string(tag);
    for (std::size_t pos = xml.find(needle, from); pos != std::string_view::npos; pos = xml.find(needle, pos + 1)) {
        const std::size_t after = pos + needle.size();
        if (after >= xml.size()) return std::string_view::npos;
        const char c = xml[after];
        if (c == '>' || c == '/' || std::isspace(static_cast<unsigned char>(c))) return pos;
    }
    return std::string_view::npos;
}

// The value of attribute `name` in the text of an opening tag ("remotePackage obsolete=\"true\" path=\"x\""), or "".
std::string attribute(std::string_view openTag, std::string_view name) {
    for (std::size_t pos = 0; (pos = openTag.find(name, pos)) != std::string_view::npos; pos += name.size()) {
        if (pos == 0 || !std::isspace(static_cast<unsigned char>(openTag[pos - 1]))) continue;
        std::size_t i = pos + name.size();
        while (i < openTag.size() && std::isspace(static_cast<unsigned char>(openTag[i]))) ++i;
        if (i >= openTag.size() || openTag[i] != '=') continue;
        ++i;
        while (i < openTag.size() && std::isspace(static_cast<unsigned char>(openTag[i]))) ++i;
        if (i >= openTag.size() || (openTag[i] != '"' && openTag[i] != '\'')) continue;
        const char quote = openTag[i++];
        const std::size_t end = openTag.find(quote, i);
        if (end == std::string_view::npos) return {};
        return decode_xml_entities(openTag.substr(i, end - i));
    }
    return {};
}

struct Element {
    std::string_view openTag;  // between '<' and '>'
    std::string_view body;     // between '>' and the closing tag
    std::size_t end = 0;       // just after the closing tag
};

// The first <tag ...>body</tag> at or after `from` (no nesting of the same tag), or nullopt.
bool find_element(std::string_view xml, std::string_view tag, std::size_t from, Element& out) {
    const std::size_t open = find_open_tag(xml, tag, from);
    if (open == std::string_view::npos) return false;
    const std::size_t gt = xml.find('>', open);
    if (gt == std::string_view::npos) return false;
    out.openTag = xml.substr(open + 1, gt - open - 1);
    if (!out.openTag.empty() && out.openTag.back() == '/') {  // <tag .../>
        out.body = {};
        out.end = gt + 1;
        return true;
    }
    const std::string close = "</" + std::string(tag) + ">";
    const std::size_t closing = xml.find(close, gt + 1);
    if (closing == std::string_view::npos) return false;
    out.body = xml.substr(gt + 1, closing - gt - 1);
    out.end = closing + close.size();
    return true;
}

std::string text_of(std::string_view body, std::string_view tag) {
    Element e;
    if (!find_element(body, tag, 0, e)) return {};
    return std::string(trim(decode_xml_entities(e.body)));
}

const char* sdk_os_name(const std::string& hostOs) {
    if (hostOs == "macos") return "macosx";
    return hostOs == "windows" ? "windows" : "linux";
}

constexpr const char* kCommandLineToolsByHand =
    "Google changed the repository layout; update FactorIA, or install the Android command-line tools by hand "
    "(https://developer.android.com/studio#command-line-tools-only).";

// One <remotePackage path="..."> of the listing, as far as the install needs it.
struct CmdlinePackage {
    bool listed = false;    // a package with this path that is not obsolete
    bool obsolete = false;  // packages with this path exist, but all are marked obsolete
    std::string revision;   // "22.0"
    SdkArchive archive;     // the one for this OS and CPU; url is empty when the package has none
    std::string osesSeen;   // every OS/CPU the package lists, for the error that none fits
};

// Reads the package `path`. The Error is only for a damaged listing: an archive for this host without <url> or <checksum>.
Result<CmdlinePackage> read_cmdline_package(std::string_view xml, const std::string& path, const std::string& hostOs,
                                            const std::string& hostArch) {
    CmdlinePackage out;
    const std::string wantOs = sdk_os_name(hostOs);
    int bestScore = 0;
    for (std::size_t pos = 0;;) {
        Element pkg;
        if (!find_element(xml, "remotePackage", pos, pkg)) break;
        pos = pkg.end;
        if (attribute(pkg.openTag, "path") != path) continue;
        if (attribute(pkg.openTag, "obsolete") == "true") {
            out.obsolete = true;
            continue;
        }
        out.listed = true;
        out.obsolete = false;
        Element rev;
        if (find_element(pkg.body, "revision", 0, rev))
            out.revision = text_of(rev.body, "major") + "." + (text_of(rev.body, "minor").empty() ? "0" : text_of(rev.body, "minor"));
        for (std::size_t apos = 0;;) {
            Element archive;
            if (!find_element(pkg.body, "archive", apos, archive)) break;
            apos = archive.end;
            SdkArchive a;
            a.hostOs = text_of(archive.body, "host-os");
            a.hostArch = text_of(archive.body, "host-arch");
            const std::string rel = text_of(archive.body, "url");
            Element sum;
            if (find_element(archive.body, "checksum", 0, sum)) {
                a.checksumType = attribute(sum.openTag, "type");
                a.checksum = lower(std::string(trim(sum.body)));
            }
            a.size = std::strtoull(text_of(archive.body, "size").c_str(), nullptr, 10);
            if (!out.osesSeen.empty()) out.osesSeen += ", ";
            out.osesSeen += a.hostOs + (a.hostArch.empty() ? "" : "/" + a.hostArch);
            if (a.hostOs != wantOs) continue;
            const int score = a.hostArch == hostArch ? 2 : (a.hostArch.empty() ? 1 : 0);
            if (score == 0 || score <= bestScore) continue;
            if (rel.empty() || a.checksum.empty())
                return make_error(std::string(kSdkRepositoryUrl) + ": the " + path + " entry for " + a.hostOs + " has no <url> or <checksum>.", kCommandLineToolsByHand);
            a.url = rel.find("://") != std::string::npos ? rel : std::string(kSdkDownloadBase) + rel;
            bestScore = score;
            out.archive = a;
        }
        break;
    }
    return out;
}

}  // namespace

std::string decode_xml_entities(std::string_view text) {
    std::string out;
    out.reserve(text.size());
    for (std::size_t i = 0; i < text.size(); ++i) {
        if (text[i] != '&') {
            out += text[i];
            continue;
        }
        const std::size_t semi = text.find(';', i);
        if (semi == std::string_view::npos || semi - i > 10) {
            out += text[i];
            continue;
        }
        const std::string_view name = text.substr(i + 1, semi - i - 1);
        if (name == "amp") out += '&';
        else if (name == "lt") out += '<';
        else if (name == "gt") out += '>';
        else if (name == "quot") out += '"';
        else if (name == "apos") out += '\'';
        else if (!name.empty() && name[0] == '#') {
            const bool hex = name.size() > 1 && (name[1] == 'x' || name[1] == 'X');
            const long cp = std::strtol(std::string(name.substr(hex ? 2 : 1)).c_str(), nullptr, hex ? 16 : 10);
            if (cp > 0 && cp <= 0x10FFFF) utf8_append(out, char32_t(cp));
            else out.append(text.substr(i, semi - i + 1));
        } else {
            out.append(text.substr(i, semi - i + 1));  // an entity we do not know stays as written
        }
        i = semi;
    }
    return out;
}

bool is_trusted_download_url(const std::string& url) {
    const std::string repoPrefix = std::string("https://github.com/") + kSetupReleaseRepo + "/releases/download/";
    return starts_with_sv(url, "https://github.com/adoptium/") || starts_with_sv(url, kSdkDownloadBase) ||
           starts_with_sv(url, repoPrefix) || starts_with_sv(url, "https://github.com/Kitware/CMake/releases/download/");
}

// ---- Android SDK repository ------------------------------------------------------------------------------

Result<SdkRepositoryInfo> parse_sdk_repository(std::string_view xml, const std::string& hostOs, const std::string& hostArch) {
    const std::string where = std::string(kSdkRepositoryUrl);
    SdkRepositoryInfo info;

    // ---- the command-line tools: the pinned classic revision, else `latest` (the Android CLI front) with a warning
    const std::string pinnedPath = kSetupAndroidCmdlineTools, fallbackPath = kSetupAndroidCmdlineToolsFallback;
    auto pinned = read_cmdline_package(xml, pinnedPath, hostOs, hostArch);
    if (!pinned.ok()) return pinned.error();
    CmdlinePackage chosen;
    std::string why;  // why the pinned package is not used
    if (!pinned->listed) why = pinned->obsolete ? "it is marked obsolete in Google's package list" : "Google's package list does not have it";
    else if (pinned->archive.url.empty()) why = "it has no download for " + hostOs + "/" + hostArch + " (it lists: " + pinned->osesSeen + ")";
    if (why.empty()) {
        chosen = *pinned;
        info.cmdlineToolsPackage = pinnedPath;
        info.cmdlineToolsPinned = true;
    } else {
        auto fallback = read_cmdline_package(xml, fallbackPath, hostOs, hostArch);
        if (!fallback.ok()) return fallback.error();
        if (!fallback->listed && pinned->listed)  // only the pinned package exists, and not for this computer
            return make_error("The Android command-line tools have no download for " + hostOs + "/" + hostArch + " (the repository lists: " + pinned->osesSeen + ").",
                              "Install the command-line tools by hand (https://developer.android.com/studio#command-line-tools-only) or Android Studio.");
        if (!fallback->listed)
            return make_error(where + " has neither the package '" + pinnedPath + "' nor '" + fallbackPath + "'.", kCommandLineToolsByHand);
        chosen = *fallback;
        info.cmdlineToolsPackage = fallbackPath;
        if (chosen.archive.url.empty())
            return make_error("The Android command-line tools have no download for " + hostOs + "/" + hostArch + " (the repository lists: " + chosen.osesSeen + ").",
                              "Install the command-line tools by hand (https://developer.android.com/studio#command-line-tools-only) or Android Studio.");
        info.warnings.push_back(
            "FactorIA pins the Android command-line tools '" + pinnedPath + "' (the classic, Java-based sdkmanager), but " + why + ", so '" +
            fallbackPath + "' (revision " + chosen.revision + ") is installed instead. Those tools are Google's \"Android CLI\": it unpacks a copy of itself of about "
            "250 MB into the Android user folder on first use, shows Google's terms and sends Google usage statistics, and sdkmanager has no switch to turn that off. "
            "Update FactorIA to get a build that knows a newer classic revision, or install Android Studio.");
    }
    info.cmdlineToolsRevision = chosen.revision;
    info.cmdlineTools = chosen.archive;
    if (info.cmdlineTools.checksumType != "sha1" || !is_hex(info.cmdlineTools.checksum, 40))
        return make_error(where + ": the cmdline-tools checksum is not a SHA-1 ('" + info.cmdlineTools.checksumType + "': '" +
                              info.cmdlineTools.checksum + "').",
                          "Google changed the repository layout; update FactorIA.");
    if (!is_trusted_download_url(info.cmdlineTools.url))
        return make_error("The repository points the command-line tools at '" + info.cmdlineTools.url + "', which is not a Google download address.",
                          "FactorIA only downloads from dl.google.com; install the command-line tools by hand.");

    // ---- the license
    for (std::size_t pos = 0;;) {
        Element lic;
        if (!find_element(xml, "license", pos, lic)) break;
        pos = lic.end;
        if (attribute(lic.openTag, "id") != kSetupAndroidLicenseId) continue;
        std::string text = decode_xml_entities(lic.body);
        text.erase(std::remove(text.begin(), text.end(), '\r'), text.end());
        std::size_t begin = text.find_first_not_of("\n ");
        std::size_t end = text.find_last_not_of("\n \t");
        if (begin == std::string::npos) break;
        info.license.id = kSetupAndroidLicenseId;
        info.license.title = "Android Software Development Kit License Agreement";
        info.license.text = text.substr(begin, end - begin + 1);
        break;
    }
    if (info.license.text.empty())
        return make_error(where + " has no <license id=\"" + std::string(kSetupAndroidLicenseId) + "\"> text.",
                          "Google changed the repository layout; update FactorIA. The license is at https://developer.android.com/studio/terms.");
    return info;
}

std::string sdk_license_hash(std::string_view text) {
    // The Android SDK tools hash the text the way their XML reader hands it over (com.android.repository.impl.meta.TrimStringAdapter,
    // then Hashing.sha1() over the UTF-8 bytes):
    //   1. a space or tab right after any whitespace character is dropped (the indentation of the XML layout),
    //   2. a line break with no other line break next to it becomes one space (paragraphs are reflowed, blank lines stay),
    //   3. a run of spaces becomes one space,
    //   4. the ends are trimmed (String.trim: every character up to U+0020).
    auto is_white = [](char c) { return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r'; };
    std::string a;
    a.reserve(text.size());
    for (std::size_t i = 0; i < text.size(); ++i) {
        const char c = text[i];
        if ((c == ' ' || c == '\t') && i > 0 && is_white(text[i - 1])) continue;
        a += c;
    }
    std::string b;
    b.reserve(a.size());
    for (std::size_t i = 0; i < a.size(); ++i) {
        const bool lone = a[i] == '\n' && (i == 0 || a[i - 1] != '\n') && (i + 1 >= a.size() || a[i + 1] != '\n');
        b += lone ? ' ' : a[i];
    }
    std::string c;
    c.reserve(b.size());
    for (char ch : b)
        if (!(ch == ' ' && !c.empty() && c.back() == ' ')) c += ch;
    std::size_t begin = 0, end = c.size();
    while (begin < end && static_cast<unsigned char>(c[begin]) <= ' ') ++begin;
    while (end > begin && static_cast<unsigned char>(c[end - 1]) <= ' ') --end;
    return sha1_hex(std::string_view(c).substr(begin, end - begin));
}

// ---- Adoptium -----------------------------------------------------------------------------------------------

Result<JdkDownload> parse_adoptium_assets(const Json& reply) {
    if (!reply.is_array() || reply.empty())
        return make_error("Adoptium (api.adoptium.net) has no Eclipse Temurin JDK " + std::to_string(kSetupJdkMajor) + " for this operating system and CPU.",
                          "Install a JDK 17 or newer by hand (https://adoptium.net) and point FactorIA at it: Platform settings > Android, "
                          "or \"android\": {\"jdk\": \"<folder>\"} in ~/.factoria/export.json.");
    for (const Json& entry : reply) {
        if (!entry.is_object()) continue;
        auto bin = entry.find("binary");
        if (bin == entry.end() || !bin->is_object()) continue;
        auto pkg = bin->find("package");
        if (pkg == bin->end() || !pkg->is_object()) continue;
        JdkDownload d;
        d.name = str_of(*pkg, "name");
        d.url = str_of(*pkg, "link");
        d.sha256 = lower(str_of(*pkg, "checksum"));
        d.size = size_of(*pkg, "size");
        d.release = str_of(entry, "release_name");
        if (auto v = entry.find("version"); v != entry.end() && v->is_object()) d.version = str_of(*v, "openjdk_version");
        const bool archive = ends_with(d.name, ".tar.gz") || ends_with(d.name, ".zip");
        if (d.url.empty() || !archive) continue;
        if (!is_hex(d.sha256, 64))
            return make_error("Adoptium lists no SHA-256 checksum for " + d.name + ".", "Try again later, or install a JDK 17+ by hand (https://adoptium.net).");
        if (!is_trusted_download_url(d.url))
            return make_error("Adoptium points the JDK at '" + d.url + "', which is not an Adoptium download address.",
                              "FactorIA only downloads from github.com/adoptium; install a JDK 17+ by hand (https://adoptium.net).");
        return d;
    }
    return make_error("Adoptium lists no .tar.gz or .zip JDK package for this operating system and CPU.",
                      "Install a JDK 17 or newer by hand (https://adoptium.net).");
}

// ---- GitHub releases ------------------------------------------------------------------------------------------

const ReleaseAsset* ReleaseInfo::find(const std::string& assetName) const {
    for (const ReleaseAsset& a : assets)
        if (a.name == assetName) return &a;
    return nullptr;
}

Result<ReleaseInfo> parse_github_release(const Json& reply, const std::string& repo) {
    if (!reply.is_object() || str_of(reply, "tag_name").empty())
        return make_error("GitHub's answer is not a release (no tag_name).", "GitHub may be having problems: try again later.");
    ReleaseInfo info;
    info.tag = str_of(reply, "tag_name");
    const std::string prefix = "https://github.com/" + repo + "/releases/download/";
    if (auto assets = reply.find("assets"); assets != reply.end() && assets->is_array()) {
        for (const Json& a : *assets) {
            if (!a.is_object()) continue;
            ReleaseAsset asset;
            asset.name = str_of(a, "name");
            asset.url = str_of(a, "browser_download_url");
            asset.size = size_of(a, "size");
            const std::string digest = str_of(a, "digest");
            if (starts_with_sv(digest, "sha256:")) asset.sha256 = lower(digest.substr(7));
            if (asset.name.empty() || asset.url.empty()) continue;
            if (!starts_with_sv(asset.url, prefix))
                return make_error("Release " + info.tag + " points " + asset.name + " at '" + asset.url + "', which is not a download of " + repo + ".",
                                  "FactorIA only downloads releases from github.com/" + repo + ".");
            info.assets.push_back(std::move(asset));
        }
    }
    return info;
}

// ---- Kitware -------------------------------------------------------------------------------------------------

std::map<std::string, std::string> parse_sha256_sums(std::string_view text) {
    std::map<std::string, std::string> out;
    for (const std::string& rawLine : split(std::string(text), '\n')) {
        const std::string_view line = trim(rawLine);
        const std::size_t space = line.find_first_of(" \t");
        if (space == std::string_view::npos) continue;
        const std::string_view hash = line.substr(0, space);
        std::string_view name = trim(line.substr(space));
        if (!name.empty() && name.front() == '*') name.remove_prefix(1);  // binary-mode marker of sha256sum
        if (is_hex(hash, 64) && !name.empty()) out[std::string(name)] = lower(std::string(hash));
    }
    return out;
}

std::vector<int> parse_cmake_version(std::string_view output) {
    const std::string_view marker = "cmake version ";
    const std::size_t at = output.find(marker);
    if (at == std::string_view::npos) return {};
    std::vector<int> parts;
    std::size_t i = at + marker.size();
    while (i < output.size() && std::isdigit(static_cast<unsigned char>(output[i]))) {
        int n = 0;
        while (i < output.size() && std::isdigit(static_cast<unsigned char>(output[i]))) n = n * 10 + (output[i++] - '0');
        parts.push_back(n);
        if (i < output.size() && output[i] == '.') ++i;
        else break;
    }
    return parts;
}

bool version_at_least(const std::vector<int>& version, std::string_view minimum) {
    std::vector<int> want;
    for (const std::string& p : split(std::string(minimum), '.')) want.push_back(std::atoi(p.c_str()));
    if (version.empty()) return false;
    for (std::size_t i = 0; i < want.size(); ++i) {
        const int have = i < version.size() ? version[i] : 0;
        if (have != want[i]) return have > want[i];
    }
    return true;
}

}  // namespace fa
