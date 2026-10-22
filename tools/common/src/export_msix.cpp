// The MSIX package of a Windows export (`factoria export --platform windows --format msix`, docs/EXPORTING.md, "Microsoft
// Store"): <out>/<slug>-windows.msix, written next to the export folder from the files of that folder. MSIX is an Open Packaging
// Conventions zip; this writes the same parts as Microsoft's MakeAppx.exe, so it works on any host:
//
//   <payload files>        the export folder (the exe, game/ or game.pak, FACTORIA_NOTICES.txt, plugins) and Assets/*.png
//   AppxManifest.xml       identity, logos, the executable (a full-trust desktop app), the capabilities
//   AppxBlockMap.xml       the SHA-256 of every 64 KiB block of every file above, which Windows checks as it reads the package
//   [Content_Types].xml    the media type of each part; last, as MakeAppx writes it
//
// Every entry is stored (not deflated): the block map then needs no compressed sizes, and the Store recompresses what it serves.
// The zip ends with a ZIP64 end of central directory, as MakeAppx writes it, and is deterministic: sorted names, a fixed date.
// The package is unsigned; the Microsoft Store signs what is uploaded and `sign.windows` signs it for installing on a PC
// (docs/EXPORTING.md).
#include <algorithm>
#include <cctype>
#include <cstdint>
#include <map>
#include <set>

#include "export_internal.h"
#include "export_zip.h"
#include "fa/core/hash.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/tooling/ai_disclosure.h"

namespace fa::export_detail {

namespace {

constexpr std::size_t kBlockSize = 64 * 1024;  // the block map hashes the (uncompressed) file in blocks of this size
constexpr const char* kManifestName = "AppxManifest.xml";
constexpr const char* kBlockMapName = "AppxBlockMap.xml";
constexpr const char* kContentTypesName = "[Content_Types].xml";
constexpr const char* kBlockMapNs = "http://schemas.microsoft.com/appx/2010/blockmap";
constexpr const char* kTypesNs = "http://schemas.openxmlformats.org/package/2006/content-types";
constexpr const char* kMaxVersionTested = "10.0.26100.0";  // Windows 11 24H2; never below minVersion (see manifest)

std::string slug_of(const Project& p) { return slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-'); }

// SHA-256 of the block, as the raw 32 bytes in base64 (what the block map holds).
std::string block_hash(const char* data, std::size_t size) {
    const std::string hex = sha256_hex(data, size);
    std::string raw;
    for (std::size_t i = 0; i + 1 < hex.size(); i += 2) raw += static_cast<char>(std::stoi(hex.substr(i, 2), nullptr, 16));
    return base64_encode(raw.data(), raw.size());
}

// The name of a part inside the zip: percent-encoded like Microsoft's packager does (a space is %20), so every byte of it is
// plain ASCII. The block map and the manifest use the unencoded name.
std::string encode_part_name(const std::string& name) {
    static const std::string special = " !#$%&'()+,;=@[]^`{}";
    std::string out;
    for (const char c : name) {
        const auto u = static_cast<unsigned char>(c);
        if (u < 0x20 || u >= 0x7F || special.find(c) != std::string::npos) {
            static const char* hex = "0123456789ABCDEF";
            out += '%';
            out += hex[u >> 4];
            out += hex[u & 15];
        } else {
            out += c;
        }
    }
    return out;
}

// "10.0.17763.0" -> the four numbers; used to keep MaxVersionTested at or above MinVersion.
std::vector<long> version_numbers(const std::string& v) {
    std::vector<long> out;
    for (const std::string& part : split(v, '.')) out.push_back(std::atol(part.c_str()));
    out.resize(4, 0);
    return out;
}

std::string content_type_of(const std::string& extension) {
    static const std::map<std::string, std::string> types = {
        {"png", "image/png"},          {"jpg", "image/jpeg"},        {"jpeg", "image/jpeg"},
        {"gif", "image/gif"},          {"bmp", "image/bmp"},         {"ico", "image/x-icon"},
        {"exe", "application/x-msdownload"}, {"dll", "application/x-msdownload"},
        {"json", "application/json"}, {"xml", "application/xml"},   {"txt", "text/plain"},
        {"md", "text/markdown"},       {"js", "text/javascript"},    {"html", "text/html"},
        {"css", "text/css"},           {"wav", "audio/wav"},         {"ogg", "audio/ogg"},
        {"mp3", "audio/mpeg"},         {"ttf", "application/x-font-ttf"}, {"otf", "application/vnd.ms-opentype"},
        {"woff", "application/font-woff"}, {"woff2", "font/woff2"},   {"mp4", "video/mp4"},
        {"ktx2", "image/ktx2"},        {"pak", "application/octet-stream"}};
    const auto it = types.find(extension);
    return it == types.end() ? "application/octet-stream" : it->second;
}

// [Content_Types].xml: a Default per extension, an Override for the parts that need their own type (the manifest and the block
// map, files without an extension or with an odd one).
std::string content_types_xml(const std::vector<std::string>& names) {
    std::set<std::string> defaults;
    std::string overrides;
    for (const std::string& name : names) {
        const std::string part = encode_part_name(name);
        const std::size_t slash = part.find_last_of('/');
        const std::string file = slash == std::string::npos ? part : part.substr(slash + 1);
        const std::size_t dot = file.find_last_of('.');
        std::string ext = dot == std::string::npos ? std::string() : to_lower(file.substr(dot + 1));
        const bool plain = !ext.empty() && std::all_of(ext.begin(), ext.end(), [](char c) { return std::isalnum(static_cast<unsigned char>(c)) != 0; });
        if (name == kManifestName) {
            overrides += std::string("<Override ContentType=\"application/vnd.ms-appx.manifest+xml\" PartName=\"/") + kManifestName + "\"/>";
        } else if (name == kBlockMapName) {
            overrides += std::string("<Override ContentType=\"application/vnd.ms-appx.blockmap+xml\" PartName=\"/") + kBlockMapName + "\"/>";
        } else if (plain) {
            defaults.insert(ext);
        } else {
            overrides += "<Override ContentType=\"application/octet-stream\" PartName=\"/" + xml_escape(part) + "\"/>";
        }
    }
    std::string out = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<Types xmlns=\"" + std::string(kTypesNs) + "\">";
    for (const std::string& ext : defaults) out += "<Default ContentType=\"" + content_type_of(ext) + "\" Extension=\"" + ext + "\"/>";
    return out + overrides + "</Types>\n";
}

struct Logo {
    std::string name;  // "Assets/Square44x44Logo.targetsize-16.png"
    int size;          // square, in pixels
};

// The logos the manifest names, plus the scale and target-size variants Windows picks from. There is no resources.pri (MakeAppx
// builds it on Windows only), so the plain name the manifest points at must exist; the qualified files are what the Start menu,
// the taskbar and the Store use when it reads them.
std::vector<Logo> logo_list() {
    std::vector<Logo> logos = {{"Assets/StoreLogo.png", 50}, {"Assets/Square44x44Logo.png", 44}, {"Assets/Square150x150Logo.png", 150}};
    for (const auto& [scale, size] : std::vector<std::pair<int, int>>{{100, 50}, {200, 100}, {400, 200}})
        logos.push_back({"Assets/StoreLogo.scale-" + std::to_string(scale) + ".png", size});
    for (const auto& [scale, size] : std::vector<std::pair<int, int>>{{100, 44}, {125, 55}, {150, 66}, {200, 88}, {400, 176}})
        logos.push_back({"Assets/Square44x44Logo.scale-" + std::to_string(scale) + ".png", size});
    for (const int size : {16, 24, 32, 48, 256}) {
        logos.push_back({"Assets/Square44x44Logo.targetsize-" + std::to_string(size) + ".png", size});
        logos.push_back({"Assets/Square44x44Logo.targetsize-" + std::to_string(size) + "_altform-unplated.png", size});
    }
    for (const auto& [scale, size] : std::vector<std::pair<int, int>>{{100, 150}, {125, 188}, {150, 225}, {200, 300}, {400, 600}})
        logos.push_back({"Assets/Square150x150Logo.scale-" + std::to_string(scale) + ".png", size});
    return logos;
}

// A name that cannot be a part of an MSIX package: Windows file name rules (no \ : * ? " < > |, no trailing dot or space).
std::string bad_part_name(const std::string& name) {
    for (const std::string& segment : split(name, '/')) {
        if (segment.empty() || segment == "." || segment == "..") return "has an empty or relative path segment";
        if (segment.find_first_of("\\:*?\"<>|") != std::string::npos) return "has a character Windows does not allow in a file name (\\ : * ? \" < > |)";
        if (segment.back() == '.' || segment.back() == ' ') return "ends with a dot or a space";
        for (const char c : segment)
            if (static_cast<unsigned char>(c) < 0x20) return "has a control character";
    }
    return {};
}

std::string backslashes(std::string s) {
    std::replace(s.begin(), s.end(), '/', '\\');
    return s;
}

}  // namespace

std::string msix_manifest(const Project& p, bool& placeholderIdentity) {
    const WindowsMsixSettings& m = p.settings.windows.msix;
    const std::string slug = slug_of(p);
    std::string name = m.identityName;
    std::string publisher = m.publisher;
    std::string publisherDisplay = m.publisherDisplayName;
    placeholderIdentity = name.empty() || publisher.empty() || publisherDisplay.empty();
    if (name.empty()) {
        std::string alnum;
        for (const char c : slug)
            if (std::isalnum(static_cast<unsigned char>(c))) alnum += c;
        name = "FactorIA." + (alnum.empty() ? std::string("Game") : alnum);
        if (name.size() > 50) name.resize(50);
    }
    if (publisher.empty()) publisher = "CN=FactorIA Developer";
    if (publisherDisplay.empty()) publisherDisplay = "FactorIA Developer";
    const std::string displayName = m.displayName.empty() ? p.name : m.displayName;
    const std::string description = m.description.empty() ? displayName : m.description;
    std::string maxTested = kMaxVersionTested;
    if (version_numbers(maxTested) < version_numbers(m.minVersion)) maxTested = m.minVersion;

    std::string x;
    x += "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
    x += "<Package xmlns=\"http://schemas.microsoft.com/appx/manifest/foundation/windows10\"\n"
         "         xmlns:uap=\"http://schemas.microsoft.com/appx/manifest/uap/windows10\"\n"
         "         xmlns:rescap=\"http://schemas.microsoft.com/appx/manifest/foundation/windows10/restrictedcapabilities\"\n"
         "         IgnorableNamespaces=\"uap rescap\">\n";
    x += "  <Identity Name=\"" + xml_escape(name) + "\" Publisher=\"" + xml_escape(publisher) + "\" Version=\"" + p.settings.msix_version() +
         "\" ProcessorArchitecture=\"x64\"/>\n";
    x += "  <Properties>\n";
    x += "    <DisplayName>" + xml_escape(displayName) + "</DisplayName>\n";
    x += "    <PublisherDisplayName>" + xml_escape(publisherDisplay) + "</PublisherDisplayName>\n";
    x += "    <Description>" + xml_escape(description) + "</Description>\n";
    x += "    <Logo>Assets\\StoreLogo.png</Logo>\n";
    x += "  </Properties>\n";
    x += "  <Resources>\n";
    for (const std::string& language : p.settings.msix_languages()) x += "    <Resource Language=\"" + xml_escape(language) + "\"/>\n";
    x += "  </Resources>\n";
    x += "  <Dependencies>\n";
    x += "    <TargetDeviceFamily Name=\"Windows.Desktop\" MinVersion=\"" + m.minVersion + "\" MaxVersionTested=\"" + maxTested + "\"/>\n";
    x += "  </Dependencies>\n";
    x += "  <Applications>\n";
    x += "    <Application Id=\"App\" Executable=\"" + xml_escape(desktop_exe_name(slug, "windows")) + "\" EntryPoint=\"Windows.FullTrustApplication\">\n";
    x += "      <uap:VisualElements DisplayName=\"" + xml_escape(displayName) + "\" Description=\"" + xml_escape(description) +
         "\" BackgroundColor=\"" + m.backgroundColor + "\" Square150x150Logo=\"Assets\\Square150x150Logo.png\" Square44x44Logo=\"Assets\\Square44x44Logo.png\"/>\n";
    x += "    </Application>\n";
    x += "  </Applications>\n";
    x += "  <Capabilities>\n";
    x += "    <rescap:Capability Name=\"runFullTrust\"/>\n";
    x += "  </Capabilities>\n";
    x += "</Package>\n";
    return x;
}

Result<MsixPlan> plan_msix(const ExportOptions&, const Project& p, const stdfs::path& outParent, std::vector<std::string>& warnings) {
    MsixPlan plan;
    plan.enabled = true;
    plan.artifact = outParent / (slug_of(p) + "-windows.msix");
    const WindowsMsixSettings& m = p.settings.windows.msix;
    std::vector<std::string> missing;
    if (m.identityName.empty()) missing.push_back("identityName");
    if (m.publisher.empty()) missing.push_back("publisher");
    if (m.publisherDisplayName.empty()) missing.push_back("publisherDisplayName");
    if (!missing.empty())
        warnings.push_back("export.windows.msix has no " + join(missing, ", ") + ", so the package gets a placeholder identity: it installs on your own PC "
                           "(sign.windows) but the Microsoft Store rejects it. Copy them from Partner Center > your app > Product management > Product identity "
                           "(Package/Identity/Name, Package/Identity/Publisher, Package/Properties/PublisherDisplayName) into export.windows.msix of factoria.json");
    return plan;
}

Result<void> build_msix(const ExportOptions& o, const Project& p, const MsixPlan& plan, const stdfs::path& outRoot, const Image& icon,
                        ExportReport& report) {
    const std::string slug = slug_of(p);
    const std::string exe = desktop_exe_name(slug, "windows");

    // The payload: the export folder's files but for what is for the developer (not for players).
    std::vector<std::string> names;
    {
        std::error_code ec;
        const stdfs::path base = os_path(outRoot);
        for (stdfs::recursive_directory_iterator it(base, ec), end; !ec && it != end; it.increment(ec))
            if (it->is_regular_file(ec)) names.push_back(generic(it->path().lexically_relative(base)));
    }
    names.erase(std::remove_if(names.begin(), names.end(), [](const std::string& n) { return n == kExportMarkerFile || n == kAiDisclosureFile; }), names.end());
    if (std::find(names.begin(), names.end(), exe) == names.end())
        return err("export: the export folder " + generic(outRoot) + " has no " + exe + " (the game's executable), so there is nothing to package",
                   "Export the game again (project.export {\"platform\":\"windows\"}).");

    // Logos: from the Windows icon (a plain placeholder when the game has none).
    Image source = icon;
    if (source.width <= 0 || source.rgba.empty()) {
        source = placeholder_icon_image();
        report.warnings.push_back("No icon is set, so the MSIX package gets a plain placeholder logo (the Store asks for real ones). Set \"icon\" in factoria.json "
                                  "(a square PNG or JPG, 1024x1024 recommended).");
    }
    std::vector<std::pair<std::string, std::string>> payload;  // part name -> bytes (the logos); files are read as they are written
    std::map<int, std::string> pngBySize;
    for (const Logo& logo : logo_list()) {
        auto it = pngBySize.find(logo.size);
        if (it == pngBySize.end()) {
            const std::vector<std::uint8_t> png = encode_png(fit_image(source, logo.size, 1.0f, Color::clear()));
            it = pngBySize.emplace(logo.size, std::string(reinterpret_cast<const char*>(png.data()), png.size())).first;
        }
        payload.emplace_back(logo.name, it->second);
    }

    std::set<std::string> taken;
    for (const auto& [name, bytes] : payload) taken.insert(to_lower(name));
    std::vector<std::string> files;  // names read from disk
    for (const std::string& name : names) {
        if (name == kManifestName || name == kBlockMapName || name == kContentTypesName || starts_with(name, "AppxMetadata/") || name == "AppxSignature.p7x")
            return err("export: the export folder holds " + name + ", a name an MSIX package keeps for itself", "Rename or remove that file from the project.");
        if (const std::string bad = bad_part_name(name); !bad.empty())
            return err("export: " + name + " " + bad + ", so it cannot be part of an MSIX package",
                       "Rename the file in the project (docs/EXPORTING.md, \"Microsoft Store\"); letters, digits, spaces and . _ - ( ) are always fine.");
        if (!taken.insert(to_lower(name)).second)
            return err("export: two files of the package differ only in upper and lower case (" + name + "), which Windows cannot hold",
                       "Rename one of them in the project.");
        files.push_back(name);
    }
    std::vector<std::string> order;  // sorted by name: the same game gives the same package
    for (const auto& [name, bytes] : payload) order.push_back(name);
    for (const std::string& name : files) order.push_back(name);
    std::sort(order.begin(), order.end());

    std::map<std::string, const std::string*> logoBytes;
    for (const auto& [name, bytes] : payload) logoBytes[name] = &bytes;

    std::error_code ec;
    stdfs::create_directories(os_path(plan.artifact.parent_path()), ec);
    ZipWriter zip(plan.artifact, ZipStyle::opc);
    std::string blockMap = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n<BlockMap xmlns=\"" + std::string(kBlockMapNs) +
                           "\" HashMethod=\"http://www.w3.org/2001/04/xmlenc#sha256\">";
    auto add_file = [&](const std::string& name, std::string_view data) -> Result<void> {
        if (auto r = zip.add(encode_part_name(name), data, false); !r.ok()) return r;
        const ZipEntry& e = zip.entries().back();
        blockMap += "<File Name=\"" + xml_escape(backslashes(name)) + "\" Size=\"" + std::to_string(data.size()) + "\" LfhSize=\"" +
                    std::to_string(e.headerSize) + "\">";
        for (std::size_t at = 0; at < data.size(); at += kBlockSize)
            blockMap += "<Block Hash=\"" + block_hash(data.data() + at, std::min(kBlockSize, data.size() - at)) + "\"/>";
        blockMap += "</File>";
        return {};
    };
    for (const std::string& name : order) {
        if (is_cancelled(o.cancel)) return err("export: cancelled while the MSIX package was being written");
        if (const auto it = logoBytes.find(name); it != logoBytes.end()) {
            if (auto r = add_file(name, *it->second); !r.ok()) return r;
            continue;
        }
        const stdfs::path file = outRoot / name;
        auto data = read_file(file);
        if (!data) return err("export: cannot read " + generic(file) + " to put it in the MSIX package");
        if (auto r = add_file(name, *data); !r.ok()) return r;
    }
    bool placeholder = false;
    const std::string manifest = msix_manifest(p, placeholder);
    if (auto r = add_file(kManifestName, manifest); !r.ok()) return r;
    blockMap += "</BlockMap>\n";
    if (auto r = zip.add(kBlockMapName, blockMap, false); !r.ok()) return r;
    std::vector<std::string> partNames = order;
    partNames.push_back(kManifestName);
    partNames.push_back(kBlockMapName);
    if (auto r = zip.add(kContentTypesName, content_types_xml(partNames), false); !r.ok()) return r;
    if (auto r = zip.finish(); !r.ok()) return r;

    report.format = "msix";
    report.artifact = generic(plan.artifact);
    const std::string file = plan.artifact.filename().string();
    std::vector<std::string> steps;
    steps.push_back("Microsoft Store: upload " + generic(plan.artifact) + " in Partner Center (your app > Submission > Packages), unsigned: the Store signs it. "
                    "`publish.microsoft` uploads it with the Microsoft Store Developer CLI (docs/PUBLISHING.md)");
    steps.push_back("Try it on a Windows PC: in PowerShell on that PC, `'{\"testCertificate\":true}' | factoria call sign.windows -` signs " + file +
                    " with a test certificate; its next steps trust the certificate (as Administrator, once) and install it with "
                    "Add-AppxPackage -Path \"" + file + "\" (docs/EXPORTING.md, \"Microsoft Store\")");
    report.nextSteps.insert(report.nextSteps.begin(), steps.begin(), steps.end());
    return {};
}

}  // namespace fa::export_detail
