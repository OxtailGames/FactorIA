// A small Ogg Vorbis encoder: WAV in, .ogg out, for `assets.convert_audio` and `assets.generate_loop`.
//
// No encoder is vendored (stb_vorbis only decodes), so this writes the simplest valid Vorbis I stream that stb_vorbis and every
// other decoder read:
//   * one block size (2048) with the Vorbis power-sine window, so no window switching;
//   * floor type 1 with two posts and no classes: a flat floor whose level is set per frame and channel, so each frame is
//     quantized with a step of its own (about the same signal-to-noise ratio in loud and quiet passages);
//   * residue type 1 in partitions of 16 coefficients, class 0 = all zero (one bit), class 1 = one scalar codebook of integer
//     levels whose Huffman code lengths are computed from this very file and written into the setup header;
//   * one channel or two; two channels are coded independently (no stereo coupling).
// It is a straightforward lossy coder, not libvorbis: expect about 4 to 6 times smaller than 16-bit WAV at the default
// quality, not 10. The output depends only on the input and the quality: the same bytes on every machine.
#include "fa/audio/convert.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <memory>
#include <queue>
#include <string>

#include "dr_wav.h"

namespace fa {

namespace {

constexpr int kBlock = 2048;               // window length
constexpr int kHalf = kBlock / 2;          // spectrum size = hop of the stream
constexpr int kBlockExponent = 11;         // 2^11
constexpr int kPartitionSize = 16;
constexpr int kPartitions = kHalf / kPartitionSize;
constexpr double kPi = 3.14159265358979323846;
constexpr std::uint32_t kSerial = 0x46414F47;  // "FAOG": one logical stream, a fixed serial keeps the file deterministic

// floor1_inverse_dB_table of the Vorbis I specification (what a floor value of 0..255 multiplies the residue by).
constexpr float kDbTable[256] = {
    1.0649863e-07f, 1.1341951e-07f, 1.2079015e-07f, 1.2863978e-07f, 1.3699951e-07f, 1.4590251e-07f,
    1.5538408e-07f, 1.6548181e-07f, 1.7623575e-07f, 1.8768855e-07f, 1.9988561e-07f, 2.1287530e-07f,
    2.2670913e-07f, 2.4144197e-07f, 2.5713223e-07f, 2.7384213e-07f, 2.9163793e-07f, 3.1059021e-07f,
    3.3077411e-07f, 3.5226968e-07f, 3.7516214e-07f, 3.9954229e-07f, 4.2550680e-07f, 4.5315863e-07f,
    4.8260743e-07f, 5.1396998e-07f, 5.4737065e-07f, 5.8294187e-07f, 6.2082472e-07f, 6.6116941e-07f,
    7.0413592e-07f, 7.4989464e-07f, 7.9862701e-07f, 8.5052630e-07f, 9.0579828e-07f, 9.6466216e-07f,
    1.0273513e-06f, 1.0941144e-06f, 1.1652161e-06f, 1.2409384e-06f, 1.3215816e-06f, 1.4074654e-06f,
    1.4989305e-06f, 1.5963394e-06f, 1.7000785e-06f, 1.8105592e-06f, 1.9282195e-06f, 2.0535261e-06f,
    2.1869758e-06f, 2.3290978e-06f, 2.4804557e-06f, 2.6416497e-06f, 2.8133190e-06f, 2.9961443e-06f,
    3.1908506e-06f, 3.3982101e-06f, 3.6190449e-06f, 3.8542308e-06f, 4.1047004e-06f, 4.3714470e-06f,
    4.6555282e-06f, 4.9580707e-06f, 5.2802740e-06f, 5.6234160e-06f, 5.9888572e-06f, 6.3780469e-06f,
    6.7925283e-06f, 7.2339451e-06f, 7.7040476e-06f, 8.2047000e-06f, 8.7378876e-06f, 9.3057248e-06f,
    9.9104632e-06f, 1.0554501e-05f, 1.1240392e-05f, 1.1970856e-05f, 1.2748789e-05f, 1.3577278e-05f,
    1.4459606e-05f, 1.5399272e-05f, 1.6400004e-05f, 1.7465768e-05f, 1.8600792e-05f, 1.9809576e-05f,
    2.1096914e-05f, 2.2467911e-05f, 2.3928002e-05f, 2.5482978e-05f, 2.7139006e-05f, 2.8902651e-05f,
    3.0780908e-05f, 3.2781225e-05f, 3.4911534e-05f, 3.7180282e-05f, 3.9596466e-05f, 4.2169667e-05f,
    4.4910090e-05f, 4.7828601e-05f, 5.0936773e-05f, 5.4246931e-05f, 5.7772202e-05f, 6.1526565e-05f,
    6.5524908e-05f, 6.9783085e-05f, 7.4317983e-05f, 7.9147585e-05f, 8.4291040e-05f, 8.9768747e-05f,
    9.5602426e-05f, 0.00010181521f, 0.00010843174f, 0.00011547824f, 0.00012298267f, 0.00013097477f,
    0.00013948625f, 0.00014855085f, 0.00015820453f, 0.00016848555f, 0.00017943469f, 0.00019109536f,
    0.00020351382f, 0.00021673929f, 0.00023082423f, 0.00024582449f, 0.00026179955f, 0.00027881276f,
    0.00029693158f, 0.00031622787f, 0.00033677814f, 0.00035866388f, 0.00038197188f, 0.00040679456f,
    0.00043323036f, 0.00046138411f, 0.00049136745f, 0.00052329927f, 0.00055730621f, 0.00059352311f,
    0.00063209358f, 0.00067317058f, 0.00071691700f, 0.00076350630f, 0.00081312324f, 0.00086596457f,
    0.00092223983f, 0.00098217216f, 0.0010459992f, 0.0011139742f, 0.0011863665f, 0.0012634633f,
    0.0013455702f, 0.0014330129f, 0.0015261382f, 0.0016253153f, 0.0017309374f, 0.0018434235f,
    0.0019632195f, 0.0020908006f, 0.0022266726f, 0.0023713743f, 0.0025254795f, 0.0026895994f,
    0.0028643847f, 0.0030505286f, 0.0032487691f, 0.0034598925f, 0.0036847358f, 0.0039241906f,
    0.0041792066f, 0.0044507950f, 0.0047400328f, 0.0050480668f, 0.0053761186f, 0.0057254891f,
    0.0060975636f, 0.0064938176f, 0.0069158225f, 0.0073652516f, 0.0078438871f, 0.0083536271f,
    0.0088964928f, 0.009474637f, 0.010090352f, 0.010746080f, 0.011444421f, 0.012188144f,
    0.012980198f, 0.013823725f, 0.014722068f, 0.015678791f, 0.016697687f, 0.017782797f,
    0.018938423f, 0.020169149f, 0.021479854f, 0.022875735f, 0.024362330f, 0.025945531f,
    0.027631618f, 0.029427276f, 0.031339626f, 0.033376252f, 0.035545228f, 0.037855157f,
    0.040315199f, 0.042935108f, 0.045725273f, 0.048696758f, 0.051861348f, 0.055231591f,
    0.058820850f, 0.062643361f, 0.066714279f, 0.071049749f, 0.075666962f, 0.080584227f,
    0.085821044f, 0.091398179f, 0.097337747f, 0.10366330f, 0.11039993f, 0.11757434f,
    0.12521498f, 0.13335215f, 0.14201813f, 0.15124727f, 0.16107617f, 0.17154380f,
    0.18269168f, 0.19456402f, 0.20720788f, 0.22067342f, 0.23501402f, 0.25028656f,
    0.26655159f, 0.28387361f, 0.30232132f, 0.32196786f, 0.34289114f, 0.36517414f,
    0.38890521f, 0.41417847f, 0.44109412f, 0.46975890f, 0.50028648f, 0.53279791f,
    0.56742212f, 0.60429640f, 0.64356699f, 0.68538959f, 0.72993007f, 0.77736504f,
    0.82788260f, 0.88168307f, 0.9389798f, 1.0f,
};

class BitWriter {
public:
    void put(std::uint32_t value, int bits) {
        for (int i = 0; i < bits; ++i) {
            if (used_ == 0) bytes_.push_back(0);
            if ((value >> i) & 1u) bytes_.back() |= static_cast<std::uint8_t>(1u << used_);
            used_ = (used_ + 1) & 7;
        }
    }
    // A Huffman codeword: its first bit is the most significant one of `code`.
    void put_code(std::uint32_t code, int length) {
        for (int i = length - 1; i >= 0; --i) put((code >> i) & 1u, 1);
    }
    std::vector<std::uint8_t>& bytes() { return bytes_; }

private:
    std::vector<std::uint8_t> bytes_;
    int used_ = 0;  // bits used in the last byte (0 = it is full)
};

std::uint32_t float32_pack(double x) {  // the Vorbis codebook float: 21 bit mantissa, 10 bit exponent, sign
    if (x == 0) return 0;
    const std::uint32_t sign = x < 0 ? 0x80000000u : 0;
    int exponent = 0;
    const double m = std::frexp(std::fabs(x), &exponent);  // |x| = m * 2^exponent, m in [0.5, 1)
    const std::uint32_t mantissa = static_cast<std::uint32_t>(std::lround(std::ldexp(m, 21)));
    return sign | (static_cast<std::uint32_t>(exponent - 21 + 788) << 21) | mantissa;
}

// ---- the Huffman code of the residue values ------------------------------------------------------------------------

struct Code {
    std::vector<int> length;           // per value index
    std::vector<std::uint32_t> code;   // per value index
    std::vector<int> entryOf;          // value index -> entry number (entries are in order of length)
    std::vector<int> valueOf;          // entry number -> value index
};

std::vector<int> huffman_lengths(std::vector<std::uint64_t> counts) {
    for (;;) {
        struct Node {
            std::uint64_t weight;
            int id;
        };
        const auto later = [](const Node& a, const Node& b) { return a.weight != b.weight ? a.weight > b.weight : a.id > b.id; };
        std::priority_queue<Node, std::vector<Node>, decltype(later)> heap(later);
        const int n = static_cast<int>(counts.size());
        std::vector<int> parent(static_cast<std::size_t>(n) * 2, -1);
        for (int i = 0; i < n; ++i) heap.push({counts[static_cast<std::size_t>(i)], i});
        int next = n;
        while (heap.size() > 1) {
            const Node a = heap.top();
            heap.pop();
            const Node b = heap.top();
            heap.pop();
            parent[static_cast<std::size_t>(a.id)] = parent[static_cast<std::size_t>(b.id)] = next;
            heap.push({a.weight + b.weight, next++});
        }
        std::vector<int> lengths(static_cast<std::size_t>(n), 0);
        int longest = 0;
        for (int i = 0; i < n; ++i) {
            int depth = 0;
            for (int at = i; parent[static_cast<std::size_t>(at)] >= 0; at = parent[static_cast<std::size_t>(at)]) ++depth;
            lengths[static_cast<std::size_t>(i)] = std::max(1, depth);
            longest = std::max(longest, depth);
        }
        if (longest <= 24) return lengths;
        for (std::uint64_t& c : counts) c = (c + 1) / 2 + 1;  // flatten the tail until the longest code is short
    }
}

Code make_code(const std::vector<std::uint64_t>& counts) {
    Code c;
    const std::size_t n = counts.size();
    const std::vector<int> lengths = huffman_lengths(counts);
    c.valueOf.resize(n);
    for (std::size_t i = 0; i < n; ++i) c.valueOf[i] = static_cast<int>(i);
    std::stable_sort(c.valueOf.begin(), c.valueOf.end(),
                     [&](int a, int b) { return lengths[static_cast<std::size_t>(a)] < lengths[static_cast<std::size_t>(b)]; });
    c.length.assign(n, 0);
    c.code.assign(n, 0);
    c.entryOf.assign(n, 0);
    // canonical codes over entries sorted by length: the lowest free codeword of each length, as the Vorbis spec assigns them
    std::uint32_t code = 0;
    int previous = lengths[static_cast<std::size_t>(c.valueOf[0])];
    for (std::size_t e = 0; e < n; ++e) {
        const std::size_t v = static_cast<std::size_t>(c.valueOf[e]);
        const int len = lengths[v];
        code <<= (len - previous);
        previous = len;
        c.length[v] = len;
        c.code[v] = code;
        c.entryOf[v] = static_cast<int>(e);
        ++code;
    }
    return c;
}

// ---- Ogg ---------------------------------------------------------------------------------------------------------------

std::array<std::uint32_t, 256> make_crc_table() {
    std::array<std::uint32_t, 256> t{};
    for (std::uint32_t i = 0; i < 256; ++i) {
        std::uint32_t r = i << 24;
        for (int k = 0; k < 8; ++k) r = (r & 0x80000000u) ? (r << 1) ^ 0x04C11DB7u : (r << 1);
        t[i] = r;
    }
    return t;
}

class OggWriter {
public:
    // Packets of one page are added with add(); flush() writes the page. `granule` is the position after the last packet.
    void add(const std::vector<std::uint8_t>& packet, std::int64_t granule) {
        const std::size_t segments = packet.size() / 255 + 1;
        if (segments_.size() + segments > 255 || data_.size() + packet.size() > 8000) flush(false);
        for (std::size_t i = 0; i + 1 < segments; ++i) segments_.push_back(255);
        segments_.push_back(static_cast<std::uint8_t>(packet.size() % 255));
        data_.insert(data_.end(), packet.begin(), packet.end());
        granule_ = granule;
    }
    void flush(bool last) {
        if (segments_.empty()) return;
        std::vector<std::uint8_t> page = {'O', 'g', 'g', 'S', 0, static_cast<std::uint8_t>((first_ ? 2 : 0) | (last ? 4 : 0))};
        const auto le = [&](std::uint64_t v, int bytes) {
            for (int i = 0; i < bytes; ++i) page.push_back(static_cast<std::uint8_t>((v >> (8 * i)) & 255));
        };
        le(static_cast<std::uint64_t>(granule_), 8);
        le(kSerial, 4);
        le(sequence_++, 4);
        const std::size_t crcAt = page.size();
        le(0, 4);
        page.push_back(static_cast<std::uint8_t>(segments_.size()));
        page.insert(page.end(), segments_.begin(), segments_.end());
        page.insert(page.end(), data_.begin(), data_.end());
        static const std::array<std::uint32_t, 256> table = make_crc_table();
        std::uint32_t crc = 0;
        for (std::uint8_t b : page) crc = (crc << 8) ^ table[((crc >> 24) & 255) ^ b];
        for (int i = 0; i < 4; ++i) page[crcAt + static_cast<std::size_t>(i)] = static_cast<std::uint8_t>((crc >> (8 * i)) & 255);
        out_.insert(out_.end(), page.begin(), page.end());
        segments_.clear();
        data_.clear();
        first_ = false;
    }
    std::vector<std::uint8_t> take() { return std::move(out_); }

private:
    std::vector<std::uint8_t> out_, segments_, data_;
    std::int64_t granule_ = 0;
    std::uint32_t sequence_ = 0;
    bool first_ = true;
};

// ---- headers -------------------------------------------------------------------------------------------------------------

void put_string(BitWriter& w, const char* s) {
    for (; *s; ++s) w.put(static_cast<std::uint8_t>(*s), 8);
}

std::vector<std::uint8_t> identification_header(int channels, int rate) {
    BitWriter w;
    w.put(1, 8);
    put_string(w, "vorbis");
    w.put(0, 32);
    w.put(static_cast<std::uint32_t>(channels), 8);
    w.put(static_cast<std::uint32_t>(rate), 32);
    w.put(0, 32);  // bitrate maximum, nominal and minimum: not given
    w.put(0, 32);
    w.put(0, 32);
    w.put(kBlockExponent, 4);  // blocksize_0
    w.put(kBlockExponent, 4);  // blocksize_1
    w.put(1, 1);
    return std::move(w.bytes());
}

std::vector<std::uint8_t> comment_header() {
    BitWriter w;
    w.put(3, 8);
    put_string(w, "vorbis");
    const char* vendor = "FactorIA";
    w.put(8, 32);
    put_string(w, vendor);
    w.put(0, 32);  // no comments
    w.put(1, 1);
    return std::move(w.bytes());
}

// The setup header: codebook 0 chooses the class of a partition, codebook 1 holds the residue values.
std::vector<std::uint8_t> setup_header(int channels, const Code& code, int valueRange) {
    BitWriter w;
    w.put(5, 8);
    put_string(w, "vorbis");
    w.put(1, 8);  // two codebooks
    // codebook 0: two entries of one bit, no lookup
    w.put(0x564342, 24);
    w.put(1, 16);
    w.put(2, 24);
    w.put(0, 1);  // not ordered
    w.put(0, 1);  // not sparse
    w.put(0, 5);  // entry 0: length 1
    w.put(0, 5);  // entry 1: length 1
    w.put(0, 4);  // no lookup
    // codebook 1: one dimension, lookup type 1: entry e is multiplicand[e] - valueRange
    const int entries = 2 * valueRange + 1;
    w.put(0x564342, 24);
    w.put(1, 16);
    w.put(static_cast<std::uint32_t>(entries), 24);
    w.put(0, 1);
    w.put(0, 1);
    for (int e = 0; e < entries; ++e) {
        const int value = code.valueOf[static_cast<std::size_t>(e)];
        w.put(static_cast<std::uint32_t>(code.length[static_cast<std::size_t>(value)] - 1), 5);
    }
    w.put(1, 4);
    w.put(float32_pack(-valueRange), 32);
    w.put(float32_pack(1.0), 32);
    w.put(7, 4);  // value_bits - 1
    w.put(0, 1);  // sequence_p
    for (int e = 0; e < entries; ++e) w.put(static_cast<std::uint32_t>(code.valueOf[static_cast<std::size_t>(e)]), 8);
    // time domain transforms: one, the placeholder value 0
    w.put(0, 6);
    w.put(0, 16);
    // floors: one, type 1, no partitions, multiplier 1 (range 256), x list bits 8
    w.put(0, 6);
    w.put(1, 16);
    w.put(0, 5);
    w.put(0, 2);
    w.put(8, 4);
    // residues: one, type 1
    w.put(0, 6);
    w.put(1, 16);
    w.put(0, 24);                       // begin
    w.put(kHalf, 24);                   // end
    w.put(kPartitionSize - 1, 24);
    w.put(1, 6);                        // two classes
    w.put(0, 8);                        // classbook: codebook 0
    w.put(0, 3);                        // class 0: no book
    w.put(0, 1);
    w.put(1, 3);                        // class 1: a book in pass 0
    w.put(0, 1);
    w.put(1, 8);                        // ... codebook 1
    // mappings: one, type 0, one submap, no coupling
    w.put(0, 6);
    w.put(0, 16);
    w.put(0, 1);  // one submap
    w.put(0, 1);  // no coupling
    w.put(0, 2);  // reserved
    w.put(0, 8);  // time (unused)
    w.put(0, 8);  // floor 0
    w.put(0, 8);  // residue 0
    // modes: one, long block, mapping 0
    w.put(0, 6);
    w.put(0, 1);
    w.put(0, 16);
    w.put(0, 16);
    w.put(0, 8);
    w.put(1, 1);
    (void)channels;
    return std::move(w.bytes());
}

}  // namespace

Result<std::vector<std::uint8_t>> encode_vorbis(std::span<const std::uint8_t> wav, double quality) {
    if (!(quality >= 0.0 && quality <= 1.0)) return make_error("quality must be a number from 0 to 1", "0.5 is the default; 0.8 for music.");
    unsigned channels = 0, rate = 0;
    drwav_uint64 frames = 0;
    float* pcm = drwav_open_memory_and_read_pcm_frames_f32(wav.data(), wav.size(), &channels, &rate, &frames, nullptr);
    if (!pcm) return make_error("not a valid WAV file", "Use 8/16/24/32-bit PCM or float WAV.");
    std::unique_ptr<float, void (*)(void*)> release{pcm, [](void* p) { drwav_free(p, nullptr); }};
    if (channels < 1 || channels > 2)
        return make_error("Ogg output here holds one or two channels, the WAV has " + std::to_string(channels), "Mix the sound down to mono or stereo first.");
    if (frames == 0 || frames > 0x7fffffffull || rate < 8000 || rate > 192000)
        return make_error("the WAV has no samples, or a sample rate outside 8000 to 192000 Hz", "Check the file with assets.analyze_audio.");

    const int ch = static_cast<int>(channels);
    const std::int64_t length = static_cast<std::int64_t>(frames);
    const int valueRange = 127;
    const int levels = static_cast<int>(std::lround(4 + 96 * quality));  // quantization steps per frame peak
    const double smallestStep = 1.0 / 65536.0;                           // below this the PCM would round to zero anyway
    const std::int64_t hops = (length + kHalf - 1) / kHalf;               // hops that hold the stream
    const std::int64_t windows = hops + 1;
    // The stream's sample 0 sits kHalf into the first window (the decoder drops the first half-window).
    std::vector<std::vector<float>> timeline(static_cast<std::size_t>(ch),
                                             std::vector<float>(static_cast<std::size_t>((windows + 1) * kHalf), 0.0f));
    for (std::int64_t i = 0; i < length; ++i)
        for (int c = 0; c < ch; ++c)
            timeline[static_cast<std::size_t>(c)][static_cast<std::size_t>(kHalf + i)] = pcm[i * ch + c];

    std::vector<float> window(kBlock);
    for (int n = 0; n < kBlock; ++n) {
        const double s = std::sin(kPi * (n + 0.5) / kBlock);
        window[static_cast<std::size_t>(n)] = static_cast<float>(std::sin(kPi / 2 * s * s));
    }
    // cosines of the MDCT: cosines[k * kBlock + n] = cos(2 pi / N (n + 1/2 + N/4) (k + 1/2)), the transform the decoder inverts
    std::vector<float> cosines(static_cast<std::size_t>(kHalf) * kBlock);
    for (int k = 0; k < kHalf; ++k)
        for (int n = 0; n < kBlock; ++n)
            cosines[static_cast<std::size_t>(k) * kBlock + static_cast<std::size_t>(n)] =
                static_cast<float>(std::cos(2 * kPi / kBlock * (n + 0.5 + kBlock / 4.0) * (k + 0.5)));

    struct Frame {
        int floor = 0;
        std::array<std::int16_t, kHalf> q{};
    };
    std::vector<Frame> coded(static_cast<std::size_t>(windows) * static_cast<std::size_t>(ch));
    std::vector<std::uint64_t> counts(static_cast<std::size_t>(2 * valueRange + 1), 1);
    std::vector<float> block(kBlock);
    std::array<float, kHalf> spectrum{};
    for (std::int64_t j = 0; j < windows; ++j) {
        for (int c = 0; c < ch; ++c) {
            const float* src = &timeline[static_cast<std::size_t>(c)][static_cast<std::size_t>(j * kHalf)];
            for (int n = 0; n < kBlock; ++n) block[static_cast<std::size_t>(n)] = src[n] * window[static_cast<std::size_t>(n)];
            float peak = 0;
            for (int k = 0; k < kHalf; ++k) {
                const float* row = &cosines[static_cast<std::size_t>(k) * kBlock];
                float acc = 0;
                for (int n = 0; n < kBlock; ++n) acc += block[static_cast<std::size_t>(n)] * row[n];
                spectrum[static_cast<std::size_t>(k)] = acc * (4.0f / kBlock);
                peak = std::max(peak, std::fabs(spectrum[static_cast<std::size_t>(k)]));
            }
            const double wanted = std::max<double>(peak / levels, smallestStep);
            int y = 0;
            while (y < 255 && kDbTable[y] < wanted) ++y;
            Frame& f = coded[static_cast<std::size_t>(j * ch + c)];
            f.floor = y;
            const float step = kDbTable[y];
            for (int k = 0; k < kHalf; ++k) {
                const int q = std::clamp(static_cast<int>(std::lround(spectrum[static_cast<std::size_t>(k)] / step)), -valueRange, valueRange);
                f.q[static_cast<std::size_t>(k)] = static_cast<std::int16_t>(q);
            }
            for (int p = 0; p < kPartitions; ++p) {
                bool any = false;
                for (int i = 0; i < kPartitionSize; ++i) any = any || f.q[static_cast<std::size_t>(p * kPartitionSize + i)] != 0;
                if (!any) continue;
                for (int i = 0; i < kPartitionSize; ++i) ++counts[static_cast<std::size_t>(f.q[static_cast<std::size_t>(p * kPartitionSize + i)] + valueRange)];
            }
        }
    }
    const Code code = make_code(counts);

    OggWriter ogg;
    ogg.add(identification_header(ch, static_cast<int>(rate)), 0);
    ogg.flush(false);
    ogg.add(comment_header(), 0);
    ogg.add(setup_header(ch, code, valueRange), 0);
    ogg.flush(false);
    for (std::int64_t j = 0; j < windows; ++j) {
        BitWriter w;
        w.put(0, 1);  // an audio packet; one mode, so no mode number
        for (int c = 0; c < ch; ++c) {
            w.put(1, 1);  // floor in use
            const std::uint32_t y = static_cast<std::uint32_t>(coded[static_cast<std::size_t>(j * ch + c)].floor);
            w.put(y, 8);
            w.put(y, 8);
        }
        for (int p = 0; p < kPartitions; ++p) {
            std::array<bool, 2> coded_part{};
            for (int c = 0; c < ch; ++c) {
                const Frame& f = coded[static_cast<std::size_t>(j * ch + c)];
                bool any = false;
                for (int i = 0; i < kPartitionSize; ++i) any = any || f.q[static_cast<std::size_t>(p * kPartitionSize + i)] != 0;
                coded_part[static_cast<std::size_t>(c)] = any;
                w.put(any ? 1 : 0, 1);
            }
            for (int c = 0; c < ch; ++c) {
                if (!coded_part[static_cast<std::size_t>(c)]) continue;
                const Frame& f = coded[static_cast<std::size_t>(j * ch + c)];
                for (int i = 0; i < kPartitionSize; ++i) {
                    const std::size_t v = static_cast<std::size_t>(f.q[static_cast<std::size_t>(p * kPartitionSize + i)] + valueRange);
                    w.put_code(code.code[v], code.length[v]);
                }
            }
        }
        const bool last = j + 1 == windows;
        ogg.add(w.bytes(), last ? length : j * kHalf);
        if (last) ogg.flush(true);
    }
    return ogg.take();
}

}  // namespace fa
