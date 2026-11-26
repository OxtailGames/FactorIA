// The vendor SDKs of a Windows game (M78): `setup streamline`, `setup xess` and `setup fidelityfx`, which fetch the
// redistributable x64 DLLs of NVIDIA Streamline (DLSS, Reflex), Intel XeSS and AMD FidelityFX, and the helpers an export asks
// for (which SDKs a project can use, where the installed ones are). The pinned releases, files and hashes are in
// fa/tooling/setup.h (VendorSdk); docs/exporting/EXPORTING_SETUP.md, "Vendor SDK licences", says what each license asks.
//
//   <home>/tools/<id>/<version>/<the DLLs, flat> + the license texts (NVIDIA: nvngx_dlss.license.txt, reflex.license.txt,
//                                sl.license.txt, 3rd-party-licenses.md; Intel: LICENSE.txt, third-party-programs.txt;
//                                AMD: license.md, 3rdpartynotice.md)
//
// Nothing is committed to FactorIA and nothing is fetched before the user accepted the license: the install refuses with
// `license_required` until acceptLicenses is set, and the status lists the license text (fetched from the vendor's repository
// at the pinned tag and checked against a pinned SHA-256) for the user to read. A Streamline or XeSS release is one .zip
// checked against the pinned SHA-256 of the archive; AMD publishes no archive, so each of its files is downloaded alone and
// checked against its own pinned hash. Only the files of the table are kept (never the Streamline profiler, the development
// builds or the denoiser). Of an archive only the listed entries are unpacked (the whole Streamline zip is 500 MB in 500 files,
// some nested deep enough to pass Windows' MAX_PATH once placed under a long user folder), and every file is checked against
// its own pinned SHA-256 after unpacking and again, by verify_installed_vendor_sdk, before an export copies it. Any host can
// install them (a Windows export made on a Mac copies them); off Windows the component is "unsupported" in the status,
// installed only when asked for by name. The folders of OLDER pinned versions (a folder named like a version, lower than this
// one) and the `<version>.old-<pid>-<n>` leftovers of replaced installs (of a version up to this one) are removed once the new
// one is in place, except the leftovers of another install that is still running; anything else under tools/<id>/ (a newer version a
// newer factoria installed side by side, a folder somebody made) stays. The DLLs are never loaded by FactorIA, so no running editor keeps one open.
#include <algorithm>
#include <filesystem>

#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "setup_internal.h"

namespace fa {

const VendorSdk* find_vendor_sdk(const std::string& id) {
    for (const VendorSdk* sdk : kSetupVendorSdks)
        if (id == sdk->id) return sdk;
    return nullptr;
}

std::vector<std::string> vendor_sdk_ids() {
    std::vector<std::string> ids;
    for (const VendorSdk* sdk : kSetupVendorSdks) ids.push_back(sdk->id);
    return ids;
}

std::string vendor_sdk_file_name(const VendorSdkFile& file) {
    if (file.dst) return file.dst;
    const std::string src = file.src;
    const std::size_t slash = src.find_last_of('/');
    return slash == std::string::npos ? src : src.substr(slash + 1);
}

bool vendor_sdk_file_is_library(const VendorSdkFile& file) {
    const std::string name = to_lower(vendor_sdk_file_name(file));
    return name.size() > 4 && name.compare(name.size() - 4, 4, ".dll") == 0;
}

std::string vendor_sdk_install_dir(const SetupContext& context, const VendorSdk& sdk) {
    return fs::path_to_utf8(fs::path_from_utf8(context.home_dir()) / "tools" / sdk.id / sdk.version);
}

std::string installed_vendor_sdk_dir(const SetupContext& context, const VendorSdk& sdk) {
    const std::filesystem::path dir = fs::path_from_utf8(vendor_sdk_install_dir(context, sdk));
    for (int i = 0; i < sdk.fileCount; ++i)
        if (!setup_detail::is_file(dir / fs::path_from_utf8(vendor_sdk_file_name(sdk.files[i])))) return {};
    return fs::path_to_utf8(dir);
}

Result<void> verify_installed_vendor_sdk(const SetupContext& context, const VendorSdk& sdk) {
    if (!context.verifyVendorSdkFiles) return {};
    const std::filesystem::path dir = fs::path_from_utf8(vendor_sdk_install_dir(context, sdk));
    const std::string fix =
        "Run `factoria setup " + std::string(sdk.id) +
        " --force` to install it again (it shows the license and asks you to accept it again: add "
        "--accept-licenses once you have read it), then export again; or set export.pack.vendorSdks "
        "to \"none\" to ship the game without it.";
    for (int i = 0; i < sdk.fileCount; ++i) {
        const std::string name = vendor_sdk_file_name(sdk.files[i]);
        if (!*sdk.files[i].sha256) continue;
        const std::filesystem::path file = dir / fs::path_from_utf8(name);
        auto actual = sha256_file_hex(fs::os_path(file));
        if (!actual.ok())
            return make_error("The installed " + std::string(sdk.id) + " file " + fs::path_to_utf8(file) +
                                  " cannot be read: " + actual.error().message,
                              fix);
        if (to_lower(*actual) != to_lower(sdk.files[i].sha256))
            return make_error("The installed " + std::string(sdk.id) + " file " + fs::path_to_utf8(file) +
                                  " is not the one FactorIA pinned (SHA-256 " + *actual + ", expected " +
                                  sdk.files[i].sha256 + "): it is damaged or was changed after the install.",
                              fix);
    }
    return {};
}

// ---- which SDKs a project can use -----------------------------------------------------------------------------------------

namespace {

// The string at /render/<section>/mode, or "" when any step is missing or is not what is expected.
std::string render_mode(const Json& project, const char* section) {
    if (!project.is_object()) return {};
    const auto render = project.find("render");
    if (render == project.end() || !render->is_object()) return {};
    const auto sec = render->find(section);
    if (sec == render->end() || !sec->is_object()) return {};
    const auto mode = sec->find("mode");
    if (mode == sec->end() || !mode->is_string()) return {};
    return to_lower(mode->get<std::string>());
}

}  // namespace

std::vector<std::string> vendor_sdks_used_by_project(const Json& projectJson,
                                                     std::vector<std::pair<std::string, std::string>>* reasons) {
    bool used[3] = {false, false, false};  // streamline, xess, fidelityfx (the order of kSetupVendorSdks)
    std::string why[3];
    auto mark = [&](int index, const char* section, const std::string& mode) {
        if (!used[index]) why[index] = std::string("/render/") + section + "/mode = \"" + mode + "\"";
        used[index] = true;
    };
    for (const char* section : {"upscaler", "frameGeneration"}) {
        const std::string mode = render_mode(projectJson, section);
        if (mode == "auto") {
            for (int i = 0; i < 3; ++i) mark(i, section, mode);
        } else if (mode == "dlss") {
            mark(0, section, mode);
        } else if (mode == "xess") {
            mark(1, section, mode);
        } else if (mode == "fsr") {
            mark(2, section, mode);
        }
    }
    const std::string latency = render_mode(projectJson, "latency");
    if (latency == "auto") {
        mark(0, "latency", latency);
        mark(1, "latency", latency);
    } else if (latency == "reflex") {
        mark(0, "latency", latency);
    } else if (latency == "xell") {
        mark(1, "latency", latency);
    }
    std::vector<std::string> ids;
    for (int i = 0; i < 3; ++i)
        if (used[i]) {
            ids.emplace_back(kSetupVendorSdks[i]->id);
            if (reasons) reasons->emplace_back(kSetupVendorSdks[i]->id, why[i]);
        }
    return ids;
}

}  // namespace fa

namespace fa::setup_detail {

namespace {

// "NVIDIA Streamline" out of "NVIDIA Streamline (DLSS, ...)": the name for steps and messages.
std::string short_name(const VendorSdk& sdk) {
    const std::string title = sdk.title;
    const std::size_t paren = title.find(" (");
    return paren == std::string::npos ? title : title.substr(0, paren);
}

// A file the tables must never name: the Streamline profiler (its own, non-redistributable Nsight Perf SDK license) and the
// development builds (unsigned: Streamline says to ship the signed production ones only).
bool file_is_forbidden(const std::string& src) {
    const std::string lower = to_lower(src);
    return lower.find("nvperf") != std::string::npos || lower.find("/development/") != std::string::npos ||
           lower.rfind("development/", 0) == 0 || lower.find("_artifacts") != std::string::npos;
}

std::string only_utf8(std::string text) {
    if (is_valid_utf8(text)) return text;
    text.erase(std::remove_if(text.begin(), text.end(), [](char c) { return static_cast<unsigned char>(c) >= 0x80; }),
               text.end());
    return text;
}

// The license of `sdk` ready to show (the obligations first, then the vendor's text), or why it could not be fetched.
std::optional<std::string> fetch_license_text(const SetupContext& ctx, const VendorSdk& sdk, SetupLicense& out) {
    auto scratch = fs::make_temp_dir("fa_setup_status");
    if (!scratch.ok())
        return "Could not fetch the license text: there is no temporary folder to download it into (" +
               scratch.error().message + "). The license is at " + sdk.licenseUrl + ".";
    std::string body;
    std::optional<std::string> problem;
    if (auto f = fetch_text(ctx, sdk.licenseUrl, std::string(sdk.licenseTitle), *scratch, body))
        problem = "Could not fetch the license text from " + std::string(sdk.licenseUrl) + ": " + f->error.message +
                  " The license is also shown by the vendor's repository at that address.";
    else if (sha256_hex(body) != sdk.licenseSha256)
        problem = std::string("The text at ") + sdk.licenseUrl +
                  " is not the license FactorIA's maintainers pinned (SHA-256 " + sha256_hex(body) + ", expected " +
                  sdk.licenseSha256 + "), so it is not shown: report it to FactorIA; it is also at that address.";
    std::error_code ec;
    fs::remove_tree(*scratch, ec);
    if (problem) return problem;
    if (*sdk.licenseEnd) {
        const std::size_t cut = body.find(sdk.licenseEnd);
        if (cut != std::string::npos) {
            body.resize(cut);
            body +=
                std::string("[The rest of the file lists source files that are under other licenses; the whole text is "
                            "copied next to the DLLs by the install and by an export.]\n");
        }
    }
    out.id = sdk.licenseId;
    out.title = sdk.licenseTitle;
    out.text = std::string("What this license asks of your game: ") + sdk.obligations + "\n\n" + std::string(60, '-') +
               "\n\n" + only_utf8(std::move(body));
    return std::nullopt;
}

std::string license_required_message(const VendorSdk& sdk) {
    return "The " + std::string(sdk.licenseTitle) + " has not been accepted yet. Installing " + short_name(sdk) +
           " means agreeing to it: " + sdk.obligations;
}

std::string license_required_hint(const VendorSdk& sdk, bool force) {
    // --force installs again, which is an install like the first: the license is asked for again.
    return std::string(force ? "--force installs it again, so it needs the license accepted again, also when it was "
                               "accepted for the files that are there now. "
                             : "") +
           "Show the license text to the user (setup.status lists it under components[].licenses; it is also at " +
           sdk.licenseUrl + ") and, once they have read it and agree, run `factoria setup " + sdk.id +
           (force ? " --force" : "") + " --accept-licenses` (setup.install {\"component\":\"" + sdk.id + "\"" +
           (force ? ",\"force\":true" : "") + ",\"acceptLicenses\":true}). An AI must ask the user first.";
}

// "2.14.16" -> {2, 14, 16}; empty when the name is not dotted numbers (a leftover "2.14.16.old-1-2" is an aside folder; "notes" is
// neither).
std::vector<long> version_numbers(const std::string& name) {
    std::vector<long> out;
    std::size_t digits = 0;
    long value = 0;
    for (const char c : name) {
        if (c >= '0' && c <= '9') {
            if (++digits > 9) return {};
            value = value * 10 + (c - '0');
        } else if (c == '.' && digits > 0) {
            out.push_back(value);
            value = 0;
            digits = 0;
        } else {
            return {};
        }
    }
    if (digits == 0) return {};
    out.push_back(value);
    return out;
}

// "2.14.16.old-4242-3" -> "2.14.16" (the folder replace_dir moves a replaced install to and could not delete: a program had a
// file of it open); "" when `name` is not of that form (the pid and the counter are digits).
std::string aside_base_name(const std::string& name) {
    const std::size_t at = name.rfind(".old-");
    if (at == std::string::npos || at == 0) return {};
    const std::string rest = name.substr(at + 5);
    const std::size_t dash = rest.find('-');
    if (dash == std::string::npos || dash == 0 || dash + 1 >= rest.size()) return {};
    for (std::size_t i = 0; i < rest.size(); ++i)
        if (i != dash && (rest[i] < '0' || rest[i] > '9')) return {};
    return name.substr(0, at);
}

// The <pid> of "2.14.16.old-4242-3" (4242), 0 when `name` is not an aside folder or the pid does not fit an int.
int aside_pid(const std::string& name) {
    if (aside_base_name(name).empty()) return 0;
    const std::string rest = name.substr(name.rfind(".old-") + 5);
    const std::string digits = rest.substr(0, rest.find('-'));
    if (digits.size() > 9) return 0;
    return std::stoi(digits);
}

// Is the folder `name` of tools/<id>/ one an install of `current` may remove? A folder named like an OLDER pinned version, and
// the leftover `<v>.old-<pid>-<n>` of a replaced install of a version that is not newer than `current` (a replaced install
// that could not be deleted on Windows stays aside; the next install sweeps it), unless a process other than this one that is
// running owns it (<pid>): it may be between the two renames of its own replace_dir, and its old install is still in that folder.
// A newer version, a name that is no version and a folder somebody else made stay.
bool is_removable_version_folder(const std::string& name, const std::string& current) {
    std::vector<long> b = version_numbers(current);
    if (b.empty()) return false;
    std::vector<long> a = version_numbers(name);
    const bool aside = a.empty();
    if (aside) a = version_numbers(aside_base_name(name));
    if (a.empty()) return false;
    const std::size_t n = std::max(a.size(), b.size());
    a.resize(n, 0);
    b.resize(n, 0);
    if (!aside) return a < b;
    const int pid = aside_pid(name);
    return a <= b && (pid == setup_detail::current_process_id() || !process_alive(pid));
}

// What a failed download, unpack or copy adds to its hint: how much free disk space the install needs.
Fail with_disk_hint(Fail f, const SetupContext& ctx, const VendorSdk& sdk) {
    if ((f.code == "failed" || f.code == "network") && sdk.diskMb > 0) {
        if (!f.error.hint.empty()) f.error.hint += " ";
        f.error.hint += "The install needs about " + std::to_string(sdk.diskMb) + " MB of free disk space in " +
                        fs::path_to_utf8(fs::path_from_utf8(ctx.home_dir()) / "staging") +
                        " (the download, the files it keeps and a copy of them).";
    }
    return f;
}

}  // namespace

SetupComponent vendor_sdk_status(const SetupContext& ctx, const VendorSdk& sdk, bool fetchLicenses) {
    SetupComponent c;
    c.id = sdk.id;
    c.title = std::string(sdk.title) + ": the DLLs a Windows game ships with it";
    c.canInstall = true;
    // The license text is listed whenever the caller asks for it, also for an installed SDK: a reinstall (`--force`, the
    // editor's Reinstall) shows and asks for it again.
    auto add_license = [&] {
        if (!fetchLicenses) return;
        SetupLicense lic;
        if (auto problem = fetch_license_text(ctx, sdk, lic))
            c.problems.push_back(*problem);
        else
            c.licenses.push_back(std::move(lic));
    };
    if (const std::string dir = installed_vendor_sdk_dir(ctx, sdk); !dir.empty()) {
        c.state = "installed";
        c.paths.emplace_back(sdk.id, dir);
        c.details = short_name(sdk) + " " + sdk.version + " is in " + dir +
                    ". A Windows export whose project can use it (export.pack.vendorSdks, default \"auto\") copies the "
                    "DLLs next to the game and their license texts to licenses/" +
                    sdk.id + "/. " + sdk.obligations;
        add_license();
        return c;
    }
    c.installSizeMb = sdk.sizeMb;
    c.details =
        std::string("The install shows the ") + sdk.licenseTitle + ", which you must accept, then downloads " +
        short_name(sdk) + " " + sdk.version + " (SHA-256 checked) and keeps its x64 DLLs and license texts in " +
        vendor_sdk_install_dir(ctx, sdk) + "." +
        (sdk.diskMb > 0
             ? " It needs about " + std::to_string(sdk.diskMb) +
                   " MB of free disk space while it installs (the download is " + std::to_string(sdk.sizeMb) + " MB)."
             : std::string());
    add_license();
    if (ctx.host_os() != "windows") {
        // Not needed here: nothing on this computer runs them. `factoria setup <id>` still installs them, for a Windows
        // export made on this computer.
        c.state = "unsupported";
        c.details = std::string("Not needed on this computer (these DLLs are for Windows games). ") + c.details +
                    " Install it here only to make Windows exports that ship it on this computer: `factoria setup " +
                    sdk.id + "`.";
        return c;
    }
    c.state = "missing";
    c.problems.push_back(std::string("The ") + sdk.licenseTitle +
                         " is not accepted yet (the install asks for it). A "
                         "Windows export whose project can use " +
                         short_name(sdk) + " ships the game without it until it is installed: run `factoria setup " +
                         sdk.id + "`.");
    return c;
}

SetupResult vendor_sdk_install(const SetupContext& ctx, const SetupInstallOptions& opt, const VendorSdk& sdk) {
    Installer in(ctx, sdk.id);
    StepTimer timer;
    SetupStep s;
    s.id = sdk.id;
    s.title = short_name(sdk) + " " + sdk.version;
    const stdfs::path dir = fs::path_from_utf8(vendor_sdk_install_dir(ctx, sdk));
    if (const std::string found = installed_vendor_sdk_dir(ctx, sdk); !opt.force && !found.empty()) {
        s.outcome = "skipped";
        s.detail = "already installed: " + found;
        s.path = found;
        in.add_step(s);
        in.report.paths = {{sdk.id, found}};
        return in.finish();
    }
    // The license first: nothing is downloaded before the user has agreed.
    if (!opt.acceptLicenses)
        return in.fail("license_required",
                       make_error(license_required_message(sdk), license_required_hint(sdk, opt.force)));
    for (int i = 0; i < sdk.fileCount; ++i)
        if (file_is_forbidden(sdk.files[i].src))
            return in.fail("failed",
                           make_error(std::string("The pinned file list of ") + sdk.id + " names " + sdk.files[i].src +
                                          ", which FactorIA never installs (a profiler or a development build)",
                                      "This is a bug in FactorIA's pin; please report it."));

    const std::string what = short_name(sdk) + " " + sdk.version;
    const stdfs::path ready = in.make_staging_subdir("ready");
    std::uint64_t bytes = 0;
    std::error_code ec;
    const char* const writable = "Check that the folder is writable and the disk is not full.";
    if (*sdk.archiveUrl) {
        const stdfs::path file = in.staging() / (std::string(sdk.id) + ".zip");
        if (auto f = download_file(ctx, sdk.archiveUrl, file, what, std::uint64_t(sdk.sizeMb) << 20, &bytes))
            return in.fail(with_disk_hint(*f, ctx, sdk));
        if (auto f = verify_checksum(file, "sha256", sdk.archiveSha256, what)) return in.fail(*f);
        const stdfs::path unpacked = in.make_staging_subdir("unpacked");
        // Only what the table keeps: the release holds hundreds of other files, some nested deeper than Windows' MAX_PATH.
        std::vector<std::string> wanted;
        for (int i = 0; i < sdk.fileCount; ++i) wanted.emplace_back(sdk.files[i].src);
        if (auto f = extract_archive(ctx, file, unpacked, wanted)) return in.fail(with_disk_hint(*f, ctx, sdk));
        for (int i = 0; i < sdk.fileCount; ++i) {
            const VendorSdkFile& entry = sdk.files[i];
            const std::string name = vendor_sdk_file_name(entry);
            const stdfs::path from = unpacked / fs::path_from_utf8(entry.src);
            if (!is_file(fs::os_path(from)))
                return in.fail("failed",
                               make_error(what + " has no " + entry.src + " (the release's layout changed)",
                                          "This is a bug in FactorIA's pin of the release; please report it."));
            const stdfs::path to = ready / fs::path_from_utf8(name);
            stdfs::copy_file(fs::os_path(from), fs::os_path(to), stdfs::copy_options::overwrite_existing, ec);
            if (ec)
                return in.fail(with_disk_hint(
                    Fail{"failed",
                         make_error("Cannot copy " + name + " into " + fs::path_to_utf8(ready) + ": " + ec.message(),
                                    writable)},
                    ctx, sdk));
            // The archive matched its pin, so a file that does not is a wrong pin of FactorIA's: nothing is installed.
            if (*entry.sha256) {
                auto actual = sha256_file_hex(fs::os_path(to));
                if (!actual.ok()) return in.fail("failed", actual.error());
                if (to_lower(*actual) != to_lower(entry.sha256))
                    return in.fail("checksum_mismatch",
                                   make_error(what + " holds " + entry.src + " with SHA-256 " + *actual +
                                                  ", but FactorIA pinned " + entry.sha256,
                                              "Nothing was installed. This is a bug in FactorIA's pin of the release; "
                                              "please report it."));
            }
        }
    } else {
        // No archive: every file alone, each against its own pinned hash.
        for (int i = 0; i < sdk.fileCount; ++i) {
            const VendorSdkFile& entry = sdk.files[i];
            const std::string name = vendor_sdk_file_name(entry);
            const stdfs::path to = ready / fs::path_from_utf8(name);
            std::uint64_t one = 0;
            const std::string fileWhat = what + " " + name;
            if (auto f = download_file(ctx, std::string(sdk.baseUrl) + "/" + entry.src, to, fileWhat, 0, &one))
                return in.fail(with_disk_hint(*f, ctx, sdk));
            bytes += one;
            if (auto f = verify_checksum(to, "sha256", entry.sha256, fileWhat)) return in.fail(*f);
        }
    }
    if (auto f = replace_dir(ready, dir)) return in.fail(with_disk_hint(*f, ctx, sdk));
    in.report.changed = true;
    s.outcome = "installed";
    s.detail = std::to_string(sdk.fileCount) +
               " files (the x64 DLLs and their license texts) from the vendor's release "
               "(SHA-256 checked)";
    s.path = fs::path_to_utf8(dir);
    s.downloadedBytes = bytes;
    s.seconds = timer.seconds();
    in.add_step(s);
    // The folders of older pinned versions are no longer used (best effort: a failure leaves the old folder), and so are the
    // leftovers of replaced installs (`<version>.old-<pid>-<n>`) of this version or an older one, except those of another
    // process that is still running (its install may be between the two renames of replace_dir). A newer version belongs to a newer
    // factoria that shares this home, and whatever else is there was not made by this setup.
    for (stdfs::directory_iterator it(dir.parent_path(), ec), end; !ec && it != end; it.increment(ec))
        if (it->is_directory() && is_removable_version_folder(fs::path_to_utf8(it->path().filename()), sdk.version)) {
            std::error_code rm;
            fs::remove_tree(it->path(), rm);
        }
    in.report.paths = {{sdk.id, fs::path_to_utf8(dir)}};
    in.report.nextSteps.push_back(
        "A Windows export (`factoria export --platform windows`) copies the DLLs next to the game, and the license "
        "texts "
        "to licenses/" +
        std::string(sdk.id) +
        "/, when the project's render settings can use it (export.pack.vendorSdks, default \"auto\"; \"none\" ships "
        "nothing).");
    in.report.nextSteps.push_back(sdk.obligations);
    return in.finish();
}

SetupComponent vendor_sdk_status_by_id(const SetupContext& ctx, const std::string& id, bool fetchLicenses) {
    return vendor_sdk_status(ctx, *find_vendor_sdk(id), fetchLicenses);
}

SetupResult vendor_sdk_install_by_id(const SetupContext& ctx, const SetupInstallOptions& opt) {
    return vendor_sdk_install(ctx, opt, *find_vendor_sdk(opt.component));
}

}  // namespace fa::setup_detail
