#include "fa/audio/midi.h"

#include <algorithm>
#include <format>

namespace fa {

namespace {

constexpr std::size_t kMaxEvents = 4000000;
constexpr std::int64_t kMaxTick = 0x0FFFFFFFFLL * 4;

std::string hex(std::uint8_t b) { return std::format("0x{:02X}", b); }

struct Reader {
    const std::vector<std::uint8_t>& b;
    std::string label;
    std::size_t pos = 0;
    std::size_t end = 0;

    Error fail(std::size_t at, const std::string& message, const std::string& hint) const {
        return make_error(std::format("{}: byte offset {}: {}", label, at, message), hint);
    }
    std::size_t left() const { return end > pos ? end - pos : 0; }
};

std::uint32_t be32(const std::vector<std::uint8_t>& b, std::size_t at) {
    return (std::uint32_t(b[at]) << 24) | (std::uint32_t(b[at + 1]) << 16) | (std::uint32_t(b[at + 2]) << 8) |
           std::uint32_t(b[at + 3]);
}

int data_bytes(std::uint8_t kind) { return (kind == 0xC0 || kind == 0xD0) ? 1 : 2; }

const char* kind_name(std::uint8_t kind) {
    switch (kind) {
        case 0x80: return "note off";
        case 0x90: return "note on";
        case 0xA0: return "key pressure";
        case 0xB0: return "controller";
        case 0xC0: return "program change";
        case 0xD0: return "channel pressure";
        default: return "pitch bend";
    }
}

Result<MidiTrack> read_track(Reader& r, std::size_t index, std::size_t& totalEvents) {
    MidiTrack track;
    std::int64_t tick = 0;
    int running = -1;  // status byte of the last channel message
    bool sawEnd = false;
    while (r.pos < r.end && !sawEnd) {
        const std::size_t eventStart = r.pos;
        // delta time: a variable-length number of up to 4 bytes
        std::int64_t delta = 0;
        int n = 0;
        while (true) {
            if (r.pos >= r.end)
                return r.fail(r.pos, std::format("track {} ends inside a delta time", index + 1),
                              "The file is cut short: re-export it, or check that the whole file was copied.");
            const std::uint8_t byte = r.b[r.pos++];
            delta = (delta << 7) | (byte & 0x7F);
            ++n;
            if (!(byte & 0x80)) break;
            if (n == 4)
                return r.fail(eventStart, "a delta time is longer than 4 bytes",
                              "A variable-length number has at most 4 bytes (the last has its top bit clear). The "
                              "track data is damaged.");
        }
        tick += delta;
        if (tick > kMaxTick)
            return r.fail(eventStart, "the track is longer than any song can be",
                          "The delta times add up to over a billion ticks: the file is damaged.");
        if (r.pos >= r.end)
            return r.fail(r.pos, std::format("track {} ends after a delta time, before the event", index + 1),
                          "Every delta time is followed by an event. The file is cut short.");
        if (++totalEvents > kMaxEvents)
            return r.fail(eventStart, "the file has more than 4 million events",
                          "Import a shorter piece, or split the file.");
        MidiEvent e;
        e.tick = tick;
        e.offset = eventStart;
        std::uint8_t status = r.b[r.pos];
        if (status & 0x80) {
            ++r.pos;
        } else {
            if (running < 0)
                return r.fail(r.pos,
                              std::format("expected a status byte (0x80 or more), found data byte {}", hex(status)),
                              "Running status (leaving the status byte out) is only allowed after a channel message of "
                              "the same track. The track data is damaged.");
            status = std::uint8_t(running);  // running status: this byte is the first data byte
        }
        if (status == 0xFF) {
            running = -1;
            if (r.left() < 2)
                return r.fail(r.pos, "a meta event is cut short",
                              "A meta event is FF, a type byte, a length and the data.");
            e.kind = 0xFF;
            e.metaType = r.b[r.pos++];
            std::uint32_t len = 0;
            int m = 0;
            while (true) {
                if (r.pos >= r.end) return r.fail(r.pos, "a meta event length is cut short", "The file is cut short.");
                const std::uint8_t byte = r.b[r.pos++];
                len = (len << 7) | (byte & 0x7F);
                if (!(byte & 0x80)) break;
                if (++m == 4)
                    return r.fail(r.pos - 1, "a meta event length is longer than 4 bytes",
                                  "The track data is damaged.");
            }
            if (len > r.left())
                return r.fail(
                    r.pos,
                    std::format("a meta event (type {}) says it has {} bytes but only {} are left in the track",
                                hex(e.metaType), len, r.left()),
                    "The file is cut short or the length is wrong.");
            e.data.assign(r.b.begin() + std::ptrdiff_t(r.pos), r.b.begin() + std::ptrdiff_t(r.pos + len));
            r.pos += len;
            if (e.metaType == kMetaEndOfTrack) sawEnd = true;
        } else if (status == 0xF0 || status == 0xF7) {
            running = -1;
            std::uint32_t len = 0;
            int m = 0;
            while (true) {
                if (r.pos >= r.end)
                    return r.fail(r.pos, "a system exclusive length is cut short", "The file is cut short.");
                const std::uint8_t byte = r.b[r.pos++];
                len = (len << 7) | (byte & 0x7F);
                if (!(byte & 0x80)) break;
                if (++m == 4)
                    return r.fail(r.pos - 1, "a system exclusive length is longer than 4 bytes",
                                  "The track data is damaged.");
            }
            if (len > r.left())
                return r.fail(
                    r.pos,
                    std::format("a system exclusive message says it has {} bytes but only {} are left in the track",
                                len, r.left()),
                    "The file is cut short or the length is wrong.");
            e.kind = 0xF0;
            e.data.assign(r.b.begin() + std::ptrdiff_t(r.pos), r.b.begin() + std::ptrdiff_t(r.pos + len));
            r.pos += len;
        } else if (status >= 0xF1) {
            return r.fail(
                eventStart,
                std::format(
                    "expected a channel message, a meta event or a system exclusive message, found the system byte {}",
                    hex(status)),
                "Real-time and system common messages are not stored in a MIDI file. The track data is damaged.");
        } else {
            e.kind = std::uint8_t(status & 0xF0);
            e.channel = std::uint8_t(status & 0x0F);
            running = status;
            const int need = data_bytes(e.kind);
            // when running status was used the first data byte is the byte at pos already (we did not consume it)
            if (r.left() < std::size_t(need))
                return r.fail(r.pos,
                              std::format("a {} event is cut short: it needs {} data byte(s)", kind_name(e.kind), need),
                              "The file is cut short.");
            e.data1 = r.b[r.pos++];
            if (e.data1 & 0x80)
                return r.fail(
                    r.pos - 1,
                    std::format("expected a data byte (under 0x80) for the {}, found {}", kind_name(e.kind),
                                hex(e.data1)),
                    "A data byte has its top bit clear; the track data is damaged or an event is missing its data.");
            if (need == 2) {
                e.data2 = r.b[r.pos++];
                if (e.data2 & 0x80)
                    return r.fail(r.pos - 1,
                                  std::format("expected a data byte (under 0x80) for the {}, found {}",
                                              kind_name(e.kind), hex(e.data2)),
                                  "A data byte has its top bit clear; the track data is damaged or an event is missing "
                                  "its data.");
            }
        }
        track.events.push_back(std::move(e));
    }
    return track;
}

void put_vlq(std::vector<std::uint8_t>& out, std::uint32_t v) {
    std::uint8_t buf[5];
    int n = 0;
    buf[n++] = std::uint8_t(v & 0x7F);
    while (v >>= 7) buf[n++] = std::uint8_t((v & 0x7F) | 0x80);
    while (n > 0) out.push_back(buf[--n]);
}

void put32(std::vector<std::uint8_t>& out, std::uint32_t v) {
    for (int s = 24; s >= 0; s -= 8) out.push_back(std::uint8_t(v >> s));
}

}  // namespace

Result<MidiFile> parse_midi(const std::vector<std::uint8_t>& bytes, std::string_view label) {
    Reader r{bytes, std::string(label)};
    r.end = bytes.size();
    if (bytes.size() < 14)
        return r.fail(
            0, std::format("expected the 14-byte header chunk (\"MThd\"), the file has {} byte(s)", bytes.size()),
            "This is not a Standard MIDI File (.mid). Export one from your DAW or tracker.");
    if (std::string(bytes.begin(), bytes.begin() + 4) != "MThd")
        return r.fail(0,
                      std::format("expected \"MThd\" (a Standard MIDI File starts with it), found \"{}\"",
                                  [&] {
                                      std::string s;
                                      for (int i = 0; i < 4; ++i)
                                          s += (bytes[std::size_t(i)] >= 32 && bytes[std::size_t(i)] < 127)
                                                   ? char(bytes[std::size_t(i)])
                                                   : '?';
                                      return s;
                                  }()),
                      "This is not a Standard MIDI File (.mid). A RIFF/RMID wrapper or another format is not read; "
                      "export the song as a plain .mid.");
    const std::uint32_t headerLen = be32(bytes, 4);
    if (headerLen < 6)
        return r.fail(4, std::format("expected a header length of 6 or more, found {}", headerLen),
                      "The header chunk is damaged.");
    MidiFile file;
    file.format = (int(bytes[8]) << 8) | bytes[9];
    const int ntrks = (int(bytes[10]) << 8) | bytes[11];
    const int division = (int(bytes[12]) << 8) | bytes[13];
    if (file.format > 2)
        return r.fail(8, std::format("expected a format of 0, 1 or 2, found {}", file.format),
                      "The header chunk is damaged.");
    if (file.format == 2)
        return r.fail(
            8, "this is a format 2 file (independent sequences), which songs cannot hold",
            "Export it again as format 1 (all tracks together) or format 0 (one track) from the program that made it.");
    if (division & 0x8000)
        return r.fail(12, "the time division is SMPTE frames, but songs count quarter notes (ticks per quarter)",
                      "Export the file again with a tempo-based resolution (e.g. 480 or 960 ticks per quarter note).");
    if (division == 0)
        return r.fail(12, "the time division is 0 ticks per quarter note",
                      "The header chunk is damaged. Use 96, 240, 480, 960...");
    file.division = division;
    if (file.format == 0 && ntrks != 1)
        return r.fail(10, std::format("a format 0 file has one track, but the header says {}", ntrks),
                      "Re-export it, or set the format to 1.");
    r.pos = 8 + headerLen;
    std::size_t totalEvents = 0;
    while (r.pos + 8 <= bytes.size() && int(file.tracks.size()) < ntrks) {
        const std::string id(bytes.begin() + std::ptrdiff_t(r.pos), bytes.begin() + std::ptrdiff_t(r.pos + 4));
        const std::uint32_t len = be32(bytes, r.pos + 4);
        const std::size_t body = r.pos + 8;
        if (len > bytes.size() - body)
            return r.fail(r.pos + 4,
                          std::format("the \"{}\" chunk says it has {} bytes but only {} are left in the file", id, len,
                                      bytes.size() - body),
                          "The file is cut short (an interrupted download or export?). Export it again.");
        if (id == "MTrk") {
            Reader tr{bytes, r.label, body, body + len};
            auto track = read_track(tr, file.tracks.size(), totalEvents);
            if (!track) return track.error();
            file.tracks.push_back(std::move(*track));
        }
        r.pos = body + len;
    }
    if (file.tracks.empty())
        return r.fail(r.pos, "expected an \"MTrk\" track chunk after the header, found none",
                      "The file holds no tracks, so there is nothing to import.");
    return file;
}

Result<std::vector<std::uint8_t>> write_midi(const MidiFile& file) {
    if (file.division < 1 || file.division > 0x7FFF)
        return make_error("the MIDI division must be 1 to 32767, got " + std::to_string(file.division),
                          "Use 480 or 960 ticks per quarter note.");
    if (file.tracks.size() > 0xFFFF) return make_error("a MIDI file holds at most 65535 tracks", "Write fewer tracks.");
    std::vector<std::uint8_t> out = {'M',
                                     'T',
                                     'h',
                                     'd',
                                     0,
                                     0,
                                     0,
                                     6,
                                     0,
                                     std::uint8_t(file.format),
                                     std::uint8_t(file.tracks.size() >> 8),
                                     std::uint8_t(file.tracks.size()),
                                     std::uint8_t(file.division >> 8),
                                     std::uint8_t(file.division)};
    for (std::size_t ti = 0; ti < file.tracks.size(); ++ti) {
        std::vector<std::uint8_t> body;
        std::int64_t last = 0;
        bool ended = false;
        for (const MidiEvent& e : file.tracks[ti].events) {
            if (e.tick < last)
                return make_error(
                    std::format("MIDI track {}: an event at tick {} comes after one at tick {}", ti + 1, e.tick, last),
                    "Sort the events by tick.");
            if (e.tick - last > 0x0FFFFFFF)
                return make_error("a gap of over 268 million ticks does not fit a MIDI delta time",
                                  "Shorten the song.");
            put_vlq(body, std::uint32_t(e.tick - last));
            last = e.tick;
            if (e.kind == kMidiMeta) {
                body.push_back(0xFF);
                body.push_back(e.metaType);
                put_vlq(body, std::uint32_t(e.data.size()));
                body.insert(body.end(), e.data.begin(), e.data.end());
                if (e.metaType == kMetaEndOfTrack) ended = true;
            } else if (e.kind == kMidiSysex) {
                body.push_back(0xF0);
                put_vlq(body, std::uint32_t(e.data.size()));
                body.insert(body.end(), e.data.begin(), e.data.end());
            } else {
                if (e.channel > 15 || e.data1 > 127 || e.data2 > 127)
                    return make_error("a MIDI channel message is out of range (channel 0..15, data 0..127)",
                                      "Check channel, key and velocity.");
                body.push_back(std::uint8_t(e.kind | e.channel));
                body.push_back(e.data1);
                if (data_bytes(e.kind) == 2) body.push_back(e.data2);
            }
            if (ended) break;
        }
        if (!ended) {
            put_vlq(body, 0);
            body.push_back(0xFF);
            body.push_back(kMetaEndOfTrack);
            body.push_back(0);
        }
        out.insert(out.end(), {'M', 'T', 'r', 'k'});
        put32(out, std::uint32_t(body.size()));
        out.insert(out.end(), body.begin(), body.end());
    }
    return out;
}

}  // namespace fa
