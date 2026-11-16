#include "script_storage.h"

#include <algorithm>
#include <cstdio>

#include "fa/core/compress.h"
#include "fa/core/fs.h"
#include "fa/core/strings.h"

namespace fa::storage_files {

std::filesystem::path dir() { return fs::user_dir() / "storage"; }

namespace {
bool reserved_windows_name(const std::string& n) {
    static const char* const names[] = {"con", "prn", "aux", "nul"};
    for (const char* r : names)
        if (n == r) return true;
    if (n.size() == 4 && (n.compare(0, 3, "com") == 0 || n.compare(0, 3, "lpt") == 0) && n[3] >= '0' && n[3] <= '9')
        return true;
    return false;
}
std::uint64_t fnv1a(const std::string& s) {
    std::uint64_t h = 1469598103934665603ull;
    for (unsigned char c : s) {
        h ^= c;
        h *= 1099511628211ull;
    }
    return h;
}
}  // namespace

std::string file_name(const std::string& key) {
    std::string out;
    for (unsigned char c : key) {
        if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_' || c == '-') {
            out.push_back(static_cast<char>(c));
        } else {
            char buf[4];
            std::snprintf(buf, sizeof buf, "%%%02X", c);
            out += buf;
        }
    }
    if (out.size() > 100) {
        // Cut on a character boundary of the encoded text (never inside a %XX), then add the hash of the whole key.
        std::size_t cut = 90;
        while (cut > 0 && (out[cut - 1] == '%' || (cut >= 2 && out[cut - 2] == '%'))) --cut;
        char buf[24];
        std::snprintf(buf, sizeof buf, "~%016llx", static_cast<unsigned long long>(fnv1a(key)));
        out = out.substr(0, cut) + buf;
    }
    if (reserved_windows_name(out)) {
        char buf[4];
        std::snprintf(buf, sizeof buf, "%%%02X", static_cast<unsigned char>(out[0]));
        out = std::string(buf) + out.substr(1);
    }
    return out + ".json";
}

namespace {
constexpr const char* kEncName = "chacha20poly1305";
constexpr const char* kContext = "factoria.storage.v1:";
constexpr std::size_t kMinSecretSize = 16;  // a random secret is 43 characters; shorter is a typed word, not a key
}  // namespace

Result<crypto::Key> derive_key(const KeyMaterial& material, const std::string& key) {
    if (material.secret.empty())
        return make_error(
            "this project has no storage encryption secret, so a value cannot be encrypted or decrypted",
            "Create it once with `factoria call project.create_storage_secret` (the same command runs from the editor "
            "console or MCP): it writes a random \"storage\": {\"encryptionSecret\"} into factoria.json. Commit that "
            "file "
            "and keep the secret: saves written with another one cannot be opened. "
            "docs/scripting/SCRIPTING_UI_SCENES.md, "
            "\"Encrypted saves\".");
    if (material.secret.size() < kMinSecretSize)
        return make_error("storage.encryptionSecret in factoria.json is too short to be a key (" +
                              std::to_string(material.secret.size()) + " characters, at least 16 needed)",
                          "Run `factoria call project.create_storage_secret {\"replace\": true}` for a random one "
                          "(saves written with the old secret cannot be opened afterwards).");
    auto okm = crypto::hkdf_sha256(crypto::as_bytes(material.secret), crypto::as_bytes(material.gameId),
                                   crypto::as_bytes(std::string(kContext) + key), crypto::kKeySize);
    if (!okm) return okm.error();
    crypto::Key k{};
    std::copy(okm.value().begin(), okm.value().end(), k.begin());
    crypto::secure_zero(okm.value().data(), okm.value().size());
    return k;
}

Result<std::string> encode(const std::string& key, const std::string& valueText, bool compress,
                           const crypto::Key* sealKey) {
    const std::string keyText = Json(key).dump(-1, ' ', false, Json::error_handler_t::replace);
    if (!sealKey) {
        if (!compress) return "{\"key\": " + keyText + ", \"value\": " + valueText + "}\n";
        const std::string z = zlib_compress(valueText);
        return "{\"key\": " + keyText + ", \"z\": \"zlib\", \"n\": " + std::to_string(valueText.size()) +
               ", \"data\": \"" + base64_encode(z.data(), z.size()) + "\"}\n";
    }
    const std::string body = compress ? zlib_compress(valueText) : valueText;
    auto blob = crypto::seal_blob(*sealKey, crypto::as_bytes(std::string_view(compress ? "zlib" : "json")), body);
    if (!blob) return blob.error();
    std::string out = "{\"key\": " + keyText + ", \"enc\": \"" + kEncName + "\"";
    if (compress) out += ", \"z\": \"zlib\", \"n\": " + std::to_string(valueText.size());
    out += ", \"data\": \"" + base64_encode(blob.value().data(), blob.value().size()) + "\"}\n";
    return out;
}

bool decode(const std::string& text, Decoded& out, std::string& problem, const KeyMaterial* material) {
    Json j = parse_json_lenient(text);
    if (!j.is_object()) {
        problem = "it is not a JSON object";
        return false;
    }
    if (!j.contains("key") || !j["key"].is_string() || j["key"].get<std::string>().empty()) {
        problem = "it has no \"key\" string";
        return false;
    }
    out.key = j["key"].get<std::string>();
    const bool zlibbed = j.contains("z");
    if (zlibbed && (!j["z"].is_string() || j["z"].get<std::string>() != "zlib")) {
        problem = "its \"z\" is not \"zlib\"";
        return false;
    }
    if (!zlibbed && !j.contains("enc")) {
        if (!j.contains("value")) {
            problem = "it has no \"value\"";
            return false;
        }
        out.value = std::move(j["value"]);
        out.compressed = false;
        return true;
    }
    if (!j.contains("data") || !j["data"].is_string()) {
        problem = zlibbed ? "its compressed value is not {\"z\": \"zlib\", \"data\": \"<base64>\"}"
                          : "its encrypted value has no \"data\" string";
        return false;
    }
    std::vector<unsigned char> raw = base64_decode(j["data"].get<std::string>());
    std::string body(reinterpret_cast<const char*>(raw.data()), raw.size());
    const bool encrypted = j.contains("enc");
    if (encrypted) {
        if (!j["enc"].is_string() || j["enc"].get<std::string>() != kEncName) {
            problem = "its \"enc\" is not \"" + std::string(kEncName) +
                      "\" (a save from a newer engine version, or a hand edit)";
            return false;
        }
        if (!material) {
            problem = "it is encrypted and this reader has no key";
            return false;
        }
        auto key = derive_key(*material, out.key);
        if (!key) {
            problem = "it is encrypted and cannot be opened: " + key.error().message + " " + key.error().hint;
            return false;
        }
        auto opened =
            crypto::open_blob(key.value(), crypto::as_bytes(std::string_view(zlibbed ? "zlib" : "json")), body);
        crypto::secure_zero(key.value());
        if (!opened) {
            problem =
                "its encrypted value failed authentication: the save was modified or damaged, or it was written with "
                "another storage.encryptionSecret or another game id (\"id\" in factoria.json), or it was copied from "
                "another storage key (" +
                opened.error().message + ")";
            return false;
        }
        body = std::move(opened.value());
    }
    std::string plain;
    if (zlibbed) {
        const std::size_t n = j.contains("n") && j["n"].is_number_unsigned() ? j["n"].get<std::size_t>() : 0;
        auto z = zlib_decompress(body, n);
        if (!z) {
            problem = z.error().message;
            return false;
        }
        plain = std::move(z.value());
    } else {
        plain = std::move(body);
    }
    out.value = parse_json_lenient(plain);
    if (out.value.is_discarded()) {
        problem =
            zlibbed ? "its compressed value does not parse as JSON" : "its encrypted value does not parse as JSON";
        return false;
    }
    out.compressed = zlibbed;
    out.encrypted = encrypted;
    return true;
}

// ---------------------------------------------------------------------------------------------------------------------

Writer::~Writer() {
    drain();
    {
        std::lock_guard<std::mutex> lock(mutex_);
        stop_ = true;
    }
    wake_.notify_all();
    if (worker_.joinable()) worker_.join();
}

void Writer::run(Job& job) {
    auto encoded = encode(job.key, job.valueText, job.compress, job.encrypt ? &job.sealKey : nullptr);
    crypto::secure_zero(job.sealKey);
    if (!encoded) {
        job.ok = false;
        job.error = encoded.error().message;
        return;
    }
    const std::string& text = encoded.value();
    job.bytes = text.size();
    if (!job.persist) return;
    auto r = fs::write_bytes(job.file.generic_string(), text.data(), text.size());  // temporary file, then rename
    if (!r) {
        job.ok = false;
        job.error = r.error().message;
    }
}

void Writer::submit(Job job, bool threaded) {
#if defined(__EMSCRIPTEN__)
    threaded = false;
#endif
    {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push_back(std::move(job));
        if (threaded && !worker_.joinable()) {
            workerMode_ = true;
            worker_ = std::thread([this] { worker_main(); });
        }
    }
    wake_.notify_one();
}

void Writer::worker_main() {
    std::unique_lock<std::mutex> lock(mutex_);
    for (;;) {
        wake_.wait(lock, [this] { return stop_ || !queue_.empty(); });
        if (queue_.empty()) {
            if (stop_) return;
            continue;
        }
        Job job = std::move(queue_.front());
        queue_.pop_front();
        busy_ = true;
        lock.unlock();
        run(job);
        lock.lock();
        done_.push_back(std::move(job));
        busy_ = false;
        idleCv_.notify_all();
    }
}

void Writer::pump() {
    for (;;) {
        Job job;
        {
            std::lock_guard<std::mutex> lock(mutex_);
            if (workerMode_ || queue_.empty()) return;
            job = std::move(queue_.front());
            queue_.pop_front();
        }
        run(job);
        std::lock_guard<std::mutex> lock(mutex_);
        done_.push_back(std::move(job));
    }
}

void Writer::drain() {
    pump();
    std::unique_lock<std::mutex> lock(mutex_);
    idleCv_.wait(lock, [this] { return queue_.empty() && !busy_; });
}

std::vector<Job> Writer::take_done() {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<Job> out;
    out.swap(done_);
    return out;
}

bool Writer::idle() {
    std::lock_guard<std::mutex> lock(mutex_);
    return queue_.empty() && !busy_ && done_.empty();
}

}  // namespace fa::storage_files
