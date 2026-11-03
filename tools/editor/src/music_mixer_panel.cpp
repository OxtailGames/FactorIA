// The Music panel's Arrangement and Mixer tabs (music_panel.cpp has the document, the transport, the piano roll and the drum grid): the sections
// of the song with their repeats, what each track plays in them, the layers the intensity fades, and the strips of the mixer. Every change is one
// music.edit op made by MusicModel, so it is one undo step and the Console and an AI make the same edit.
#include <algorithm>
#include <cmath>
#include <format>

#include "editor_internal.h"
#include "fa/audio/audio_doc.h"
#include "fa/audio/song_instruments.h"
#include "fa/core/strings.h"
#include "music_panel_util.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

using music_ui::kBad;
using music_ui::kWarn;

// A drag field that shows its own value while it is dragged and reports ONE edit when it is let go.
bool live_drag(MusicUi& u, const std::string& key, double model, double lo, double hi, float speed, const char* fmt, float width, double& out) {
    double v = u.liveKey == key ? u.liveValue : model;
    ImGui::SetNextItemWidth(width);
    const bool edited = ImGui::DragScalar(("##" + key).c_str(), ImGuiDataType_Double, &v, speed, &lo, &hi, fmt);
    if (edited || ImGui::IsItemActive()) {
        u.liveKey = key;
        u.liveValue = v;
    } else if (u.liveKey == key && !ImGui::IsItemDeactivatedAfterEdit()) {
        u.liveKey.clear();
    }
    if (ImGui::IsItemDeactivatedAfterEdit()) {
        out = v;
        u.liveKey.clear();
        return true;
    }
    return false;
}

// A text field that keeps what is typed until Enter or the focus leaves it, and reports it once.
bool live_text(MusicUi& u, const std::string& key, const std::string& model, float width, std::string& out) {
    std::string v = u.textKey == key ? u.text : model;
    ImGui::SetNextItemWidth(width);
    const bool edited = ImGui::InputText(("##" + key).c_str(), &v);
    if (edited || ImGui::IsItemActive()) {
        u.textKey = key;
        u.text = v;
    }
    if (ImGui::IsItemDeactivatedAfterEdit()) {
        out = v;
        u.textKey.clear();
        return true;
    }
    if (!ImGui::IsItemActive() && u.textKey == key) u.textKey.clear();
    return false;
}

std::string entries_text(const SongSection& s, const std::string& track) {
    for (const SongSectionTrack& t : s.play) {
        if (t.track != track) continue;
        std::string out;
        for (const SongPlayEntry& e : t.entries) {
            if (!out.empty()) out += ' ';
            out += e.pattern.empty() ? "rest" : e.pattern;
            if (e.repeat > 1) out += "*" + std::to_string(e.repeat);
        }
        return out;
    }
    return "";
}

std::vector<std::string> section_names_of(const SongDoc& doc) {
    std::vector<std::string> out;
    for (const SongSection& s : doc.sections) out.push_back(s.name);
    return out;
}

std::vector<std::string> track_names_of(const SongDoc& doc) {
    std::vector<std::string> out;
    for (const SongTrack& t : doc.tracks) out.push_back(t.name);
    return out;
}

// The effects chain of a track, a bus or the master as a list of steps with their fields. Returns the new list (as the song file writes it)
// when the user changed something, null otherwise. `raw` is the chain as the file has it.
Json effects_editor(MusicUi& u, const std::string& id, const std::vector<AudioStep>& steps, const Json& raw, bool canEdit) {
    Json list = raw.is_array() ? raw : Json::array();
    while (list.size() < steps.size()) list.push_back(Json::object({{"type", steps[list.size()].type}}));
    Json changed;
    int remove = -1;
    for (std::size_t i = 0; i < steps.size(); ++i) {
        const AudioStep& st = steps[i];
        const std::string key = id + ":" + std::to_string(i);
        ImGui::PushID(key.c_str());
        const bool open = ImGui::TreeNodeEx((st.type + "##fx").c_str(), ImGuiTreeNodeFlags_SpanAvailWidth);
        ImGui::SameLine();
        ImGui::BeginDisabled(!canEdit);
        if (ImGui::SmallButton("remove")) remove = int(i);
        ImGui::EndDisabled();
        if (open) {
            const AudioStepInfo* info = nullptr;
            for (const AudioStepInfo& si : audio_step_types())
                if (si.type == st.type) info = &si;
            if (info) {
                for (const AudioFieldInfo& f : info->fields) {
                    if (f.key == "type" || !st.params.is_object() || !st.params.contains(f.key)) continue;
                    const Json& cur = st.params[f.key];
                    ImGui::TextDisabled("%s", f.key.c_str());
                    ImGui::SameLine(96);
                    ImGui::BeginDisabled(!canEdit);
                    if ((f.type == "number" || f.type == "integer") && cur.is_number()) {
                        double out = 0;
                        const double lo = f.min.value_or(-1e6), hi = f.max.value_or(1e6);
                        const double span = (f.min && f.max) ? *f.max - *f.min : 100.0;
                        if (live_drag(u, key + ":" + f.key, cur.get<double>(), lo, hi, float(span / 200.0), f.type == "integer" ? "%.0f" : "%.3f", 90, out)) {
                            list[i][f.key] = f.type == "integer" ? Json(std::int64_t(std::llround(out))) : Json(out);
                            changed = list;
                        }
                    } else if (f.type == "boolean" && cur.is_boolean()) {
                        bool b = cur.get<bool>();
                        if (ImGui::Checkbox(("##" + f.key).c_str(), &b)) {
                            list[i][f.key] = b;
                            changed = list;
                        }
                    } else if (f.type == "string" && !f.choices.empty() && cur.is_string()) {
                        ImGui::SetNextItemWidth(110);
                        if (ImGui::BeginCombo(("##" + f.key).c_str(), cur.get<std::string>().c_str())) {
                            for (const std::string& c : f.choices)
                                if (ImGui::Selectable(c.c_str(), c == cur.get<std::string>())) {
                                    list[i][f.key] = c;
                                    changed = list;
                                }
                            ImGui::EndCombo();
                        }
                    } else {
                        ImGui::TextDisabled("%s", cur.dump().c_str());
                    }
                    ImGui::EndDisabled();
                    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled) && !f.doc.empty()) ImGui::SetTooltip("%s", f.doc.c_str());
                }
            }
            ImGui::TreePop();
        }
        ImGui::PopID();
    }
    if (remove >= 0) {
        list.erase(list.begin() + remove);
        changed = list;
    }
    // add
    ImGui::BeginDisabled(!canEdit);
    ImGui::SetNextItemWidth(110);
    if (ImGui::BeginCombo(("##addfx" + id).c_str(), "add effect...")) {
        for (const AudioStepInfo& si : audio_step_types()) {
            if (!audio_step_is_effect(si.type)) continue;
            if (ImGui::Selectable(si.type.c_str())) {
                list.push_back(Json::object({{"type", si.type}}));
                changed = list;
            }
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s", si.doc.c_str());
        }
        ImGui::EndCombo();
    }
    ImGui::EndDisabled();
    return changed;
}

const Json& json_at(const Json& root, const char* a, const std::string& b = "", const char* c = nullptr) {
    static const Json none;
    if (!root.is_object() || !root.contains(a)) return none;
    const Json& x = root[a];
    if (b.empty()) return x;
    if (!x.is_object() || !x.contains(b)) return none;
    if (!c) return x[b];
    return x[b].is_object() && x[b].contains(c) ? x[b][c] : none;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------- arrangement --
void Editor::draw_music_arrangement(MusicModel& m) {
    MusicUi& u = music_;
    const SongDoc* doc = m.doc();
    if (!doc) return;
    const bool canEdit = play_ == PlayState::Edit;
    const std::vector<std::string> sections = section_names_of(*doc), tracks = track_names_of(*doc);
    u.section = std::clamp(u.section, 0, std::max(0, int(sections.size()) - 1));

    // ---- the strip: the song as its section passes, with the playhead
    if (const SongTimeline* tl = m.timeline(); tl && tl->bars > 0) {
        const float w = std::max(200.0f, ImGui::GetContentRegionAvail().x - 8.0f), h = 26.0f;
        const ImVec2 p0 = ImGui::GetCursorScreenPos();
        ImGui::Dummy(ImVec2(w, h + 4));
        ImDrawList* dl = ImGui::GetWindowDrawList();
        for (std::size_t i = 0; i < tl->spans.size(); ++i) {
            const SongSpan& sp = tl->spans[i];
            const float xa = p0.x + w * float(sp.startBar) / float(tl->bars), xb = p0.x + w * float(sp.startBar + sp.bars) / float(tl->bars);
            const bool sel = sp.section == u.section;
            const std::string& kind = doc->sections[std::size_t(sp.section)].kind;
            const ImU32 col = kind == "intro" ? IM_COL32(70, 110, 150, 255) : kind == "loop" ? IM_COL32(80, 140, 90, 255) : kind == "outro" ? IM_COL32(150, 100, 80, 255) : IM_COL32(110, 110, 140, 255);
            dl->AddRectFilled(ImVec2(xa + 1, p0.y), ImVec2(xb - 1, p0.y + h), col, 3.0f);
            if (sel) dl->AddRect(ImVec2(xa + 1, p0.y), ImVec2(xb - 1, p0.y + h), IM_COL32(255, 255, 255, 255), 3.0f, 0, 2.0f);
            if (xb - xa > 28) dl->AddText(ImVec2(xa + 5, p0.y + 5), IM_COL32(255, 255, 255, 255), doc->sections[std::size_t(sp.section)].name.c_str());
        }
        if (u.preview->playing() && u.preview->source()) {
            const MusicPreview::Where wh = u.preview->where();
            const MusicMap& map = u.preview->source()->map;
            if (wh.span >= 0 && std::size_t(wh.span) < map.spans.size() && std::size_t(wh.span) < tl->spans.size()) {
                const MusicSpan& ms = map.spans[std::size_t(wh.span)];
                const SongSpan& sp = tl->spans[std::size_t(wh.span)];
                const double f = ms.end > ms.start ? std::clamp((u.preview->position_frames() - ms.start) / (ms.end - ms.start), 0.0, 1.0) : 0.0;
                const float x = p0.x + w * float(double(sp.startBar) + f * double(sp.bars)) / float(tl->bars);
                dl->AddLine(ImVec2(x, p0.y - 2), ImVec2(x, p0.y + h + 2), IM_COL32(255, 90, 90, 255), 2.0f);
            }
        }
    }

    // ---- the sections
    ImGui::TextDisabled("Sections, in play order. Repeat plays a section that many times in a row; a loop section repeats while the game stays in it.");
    static const char* kinds[] = {"section", "intro", "loop", "outro"};
    for (std::size_t i = 0; i < doc->sections.size(); ++i) {
        const SongSection& s = doc->sections[i];
        ImGui::PushID(int(i));
        if (ImGui::Selectable(s.name.c_str(), int(i) == u.section, 0, ImVec2(110, 0))) u.section = int(i);
        at_track("mus:sec:" + s.name);
        ImGui::SameLine();
        ImGui::BeginDisabled(!canEdit);
        ImGui::SetNextItemWidth(84);
        if (ImGui::BeginCombo("##kind", s.kind.c_str())) {
            for (const char* k : kinds)
                if (ImGui::Selectable(k, s.kind == k) && s.kind != k) music_edited(m.set_section(s.name, Json::object({{"kind", k}})));
            ImGui::EndCombo();
        }
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("intro plays once at the start; loop sections repeat while the game stays in them; outro ends the song; section is any other part.");
        ImGui::SameLine();
        ImGui::TextDisabled("repeat");
        ImGui::SameLine();
        if (ImGui::SmallButton("-") && s.repeat > 1) music_edited(m.set_section(s.name, Json::object({{"repeat", s.repeat - 1}}), "Repeat " + s.name + " " + std::to_string(s.repeat - 1) + "x"));
        at_track("mus:repeat_minus:" + s.name);
        ImGui::SameLine();
        ImGui::Text("%2d", s.repeat);
        at_track("mus:repeat_value:" + s.name);
        ImGui::SameLine();
        if (ImGui::SmallButton("+") && s.repeat < 64) music_edited(m.set_section(s.name, Json::object({{"repeat", s.repeat + 1}}), "Repeat " + s.name + " " + std::to_string(s.repeat + 1) + "x"));
        at_track("mus:repeat_plus:" + s.name);
        ImGui::SameLine();
        ImGui::TextDisabled("%3d bars", s.bars);
        ImGui::SameLine();
        if (ImGui::SmallButton("up") && i > 0) music_edited(m.edit("Move section " + s.name, Json::array({Json::object({{"op", "move_section"}, {"section", s.name}, {"index", int(i)}})})));
        at_track("mus:sec_up:" + s.name);
        ImGui::SameLine();
        if (ImGui::SmallButton("down") && i + 1 < doc->sections.size()) music_edited(m.edit("Move section " + s.name, Json::array({Json::object({{"op", "move_section"}, {"section", s.name}, {"index", int(i) + 2}})})));
        at_track("mus:sec_down:" + s.name);
        ImGui::SameLine();
        if (ImGui::SmallButton("remove") && doc->sections.size() > 1) music_edited(m.edit("Remove section " + s.name, Json::array({Json::object({{"op", "remove_section"}, {"section", s.name}})})));
        at_track("mus:sec_remove:" + s.name);
        ImGui::EndDisabled();
        ImGui::SameLine();
        if (ImGui::SmallButton("play")) {
            u.section = int(i);
            music_play(int(i), u.loopSection);
        }
        at_track("mus:sec_play:" + s.name);
        ImGui::PopID();
    }
    ImGui::BeginDisabled(!canEdit);
    ImGui::SetNextItemWidth(110);
    music_ui::text_field("##newsection", u.newSection, 40);
    at_track("mus:new_section_name");
    ImGui::SameLine();
    if (ImGui::Button("Add section")) {
        Json op = Json::object({{"op", "add_section"}, {"section", u.newSection}});
        // The new section plays what the selected one does, so it makes sound from the start.
        if (u.section >= 0 && std::size_t(u.section) < doc->sections.size()) {
            Json play = Json::object();
            for (const std::string& t : tracks) {
                const std::string text = entries_text(doc->sections[std::size_t(u.section)], t);
                if (!text.empty()) play[t] = text;
            }
            op["play"] = play;
        }
        const MusicEditOutcome out = m.edit("Add section " + u.newSection, Json::array({op}));
        music_edited(out);
        if (out.ok) u.newSection = m.free_name("section", section_names_of(*m.doc()));
    }
    at_track("mus:add_section");
    ImGui::EndDisabled();

    // ---- what each track plays in the selected section
    if (!doc->sections.empty()) {
        const SongSection& sel = doc->sections[std::size_t(u.section)];
        ImGui::Separator();
        ImGui::Text("What plays in %s", sel.name.c_str());
        ImGui::SameLine();
        ImGui::TextDisabled("(patterns in order; name*2 repeats one, rest is a silent bar; empty stops the track)");
        for (const std::string& t : tracks) {
            ImGui::PushID(t.c_str());
            ImGui::Text("%-10s", t.c_str());
            ImGui::SameLine(110);
            ImGui::BeginDisabled(!canEdit);
            std::string out;
            if (live_text(u, "entries:" + sel.name + ":" + t, entries_text(sel, t), 260, out)) {
                const bool empty = out.find_first_not_of(" \t") == std::string::npos;
                music_edited(m.edit("Arrange " + t + " in " + sel.name, Json::array({Json::object({{"op", "arrange"}, {"section", sel.name}, {"track", t}, {"entries", empty ? Json() : Json(out)}})})));
            }
            at_track("mus:entries:" + sel.name + ":" + t);
            ImGui::SameLine();
            const bool muted = std::find(sel.mute.begin(), sel.mute.end(), t) != sel.mute.end();
            bool mu = muted;
            if (ImGui::Checkbox("muted", &mu))
                music_edited(m.edit(std::string(mu ? "Mute " : "Unmute ") + t + " in " + sel.name, Json::array({Json::object({{"op", "mute"}, {"section", sel.name}, {"tracks", Json::array({t})}, {"muted", mu}})})));
            at_track("mus:smute:" + sel.name + ":" + t);
            if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Silences the track in this section only (it keeps what it plays here).");
            ImGui::EndDisabled();
            ImGui::PopID();
        }
    }

    // ---- layers
    ImGui::Separator();
    ImGui::Text("Layers");
    ImGui::SameLine();
    ImGui::TextDisabled("(tracks that fade in with the intensity; entity.music.setIntensity in a game. The first plays always.)");
    const std::vector<SongLayer> shown = song_layers(*doc);
    const Json& rawLayers = json_at(m.json(), "layers");
    for (const SongLayer& l : shown) {
        ImGui::PushID(l.name.c_str());
        const bool written = std::any_of(doc->layers.begin(), doc->layers.end(), [&](const SongLayer& w) { return w.name == l.name; });
        ImGui::Text("%-10s", l.name.c_str());
        ImGui::SameLine(110);
        ImGui::BeginDisabled(!canEdit || !written);
        double out = 0;
        if (live_drag(u, "layerint:" + l.name, l.intensity, 0.0, 1.0, 0.01f, "from %.2f", 80, out)) {
            Json tr = Json::array();
            for (const std::string& t : l.tracks) tr.push_back(t);
            music_edited(m.set_layers(Json::object({{l.name, Json::object({{"tracks", tr}, {"intensity", std::round(out * 100.0) / 100.0}})}})));
        }
        at_track("mus:layer_intensity:" + l.name);
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip(written ? "The intensity at which this layer is fully in." : "This layer collects the tracks no other names. Its intensity follows the others.");
        ImGui::EndDisabled();
        for (const std::string& t : tracks) {
            ImGui::SameLine();
            bool in = std::find(l.tracks.begin(), l.tracks.end(), t) != l.tracks.end();
            ImGui::BeginDisabled(!canEdit || !written);
            if (ImGui::Checkbox(t.c_str(), &in)) {
                Json tr = Json::array();
                for (const std::string& x : l.tracks)
                    if (x != t) tr.push_back(x);
                if (in) tr.push_back(t);
                if (tr.empty()) notify("A layer needs at least one track; remove the layer instead.", 1);
                else {
                    Json body = rawLayers.is_object() && rawLayers.contains(l.name) && rawLayers[l.name].is_object() ? rawLayers[l.name] : Json::object();
                    body["tracks"] = tr;
                    if (!body.contains("intensity") && l.intensityWritten) body["intensity"] = l.intensity;
                    music_edited(m.set_layers(Json::object({{l.name, body.contains("intensity") ? body : tr}})));
                }
            }
            at_track("mus:layer_track:" + l.name + ":" + t);
            ImGui::EndDisabled();
        }
        ImGui::SameLine();
        ImGui::BeginDisabled(!canEdit || !written);
        if (ImGui::SmallButton("remove")) music_edited(m.set_layers(Json::object({{l.name, Json()}})));
        at_track("mus:layer_remove:" + l.name);
        ImGui::EndDisabled();
        ImGui::PopID();
    }
    ImGui::BeginDisabled(!canEdit || tracks.empty());
    ImGui::SetNextItemWidth(110);
    music_ui::text_field("##newlayer", u.newLayer, 40);
    at_track("mus:new_layer_name");
    ImGui::SameLine();
    if (ImGui::Button("Add layer")) {
        // The first track no layer has yet, or the last track.
        std::string pick = tracks.back();
        for (const std::string& t : tracks) {
            bool used = false;
            for (const SongLayer& l : doc->layers) used = used || std::find(l.tracks.begin(), l.tracks.end(), t) != l.tracks.end();
            if (!used) {
                pick = t;
                break;
            }
        }
        music_edited(m.set_layers(Json::object({{u.newLayer, Json::array({pick})}})));
    }
    at_track("mus:add_layer");
    ImGui::EndDisabled();
    if (doc->layers.empty()) ImGui::TextDisabled("This song declares no layers: it plays as one piece and the intensity changes nothing.");
}

// --------------------------------------------------------------------------------------------------------------------- mixer --
void Editor::draw_music_mixer(MusicModel& m) {
    MusicUi& u = music_;
    const SongDoc* doc = m.doc();
    if (!doc) return;
    const bool canEdit = play_ == PlayState::Edit;
    const Json& file = m.json();
    std::vector<std::string> busNames;
    for (const SongBus& b : doc->mixer.buses) busNames.push_back(b.name);

    ImGui::TextDisabled("Tracks: fader, pan, mute and solo, sends to the buses, an effects chain before the fader.");
    for (const SongTrack& t : doc->tracks) {
        ImGui::PushID(t.name.c_str());
        ImGui::Text("%-10s", t.name.c_str());
        ImGui::SameLine(96);
        ImGui::BeginDisabled(!canEdit);
        ImGui::TextDisabled("vol");
        ImGui::SameLine();
        double out = 0;
        if (live_drag(u, "vol:" + t.name, t.volume, 0.0, 2.0, 0.01f, "%.2f", 64, out)) music_edited(m.set_track(t.name, Json::object({{"volume", std::round(out * 100.0) / 100.0}}), "Volume of " + t.name));
        at_track("mus:volume:" + t.name);
        ImGui::SameLine();
        ImGui::TextDisabled("pan");
        ImGui::SameLine();
        if (live_drag(u, "pan:" + t.name, t.pan, -1.0, 1.0, 0.01f, "%.2f", 64, out)) music_edited(m.set_track(t.name, Json::object({{"pan", std::round(out * 100.0) / 100.0}}), "Pan of " + t.name));
        at_track("mus:pan:" + t.name);
        ImGui::SameLine();
        if (music_ui::toggle_button("M", t.mute, ImVec2(24, 0))) music_edited(m.set_track(t.name, Json::object({{"mute", !t.mute}}), std::string(t.mute ? "Unmute " : "Mute ") + t.name));
        at_track("mus:mute:" + t.name);
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Mute: the track plays no notes (in every section).");
        ImGui::SameLine();
        if (music_ui::toggle_button("S", t.solo, ImVec2(24, 0))) music_edited(m.set_track(t.name, Json::object({{"solo", !t.solo}}), std::string(t.solo ? "Unsolo " : "Solo ") + t.name));
        at_track("mus:solo:" + t.name);
        if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("Solo: while any track is soloed only soloed tracks play.");
        ImGui::SameLine();
        ImGui::TextDisabled("%s", t.instrument.c_str());
        ImGui::SameLine();
        if (ImGui::SmallButton("remove") && doc->tracks.size() > 1) music_edited(m.edit("Remove track " + t.name, Json::array({Json::object({{"op", "remove_track"}, {"track", t.name}})})));
        at_track("mus:track_remove:" + t.name);
        ImGui::EndDisabled();
        if (!busNames.empty() || !t.effects.empty()) {
            ImGui::Indent(20);
            ImGui::BeginDisabled(!canEdit);
            for (const std::string& b : busNames) {
                const auto it = t.sends.find(b);
                ImGui::TextDisabled("send %s", b.c_str());
                ImGui::SameLine(120);
                if (live_drag(u, "send:" + t.name + ":" + b, it == t.sends.end() ? 0.0 : it->second, 0.0, 2.0, 0.01f, "%.2f", 64, out)) {
                    Json sends = json_at(file, "tracks", t.name, "sends");
                    if (!sends.is_object()) sends = Json::object();
                    sends[b] = std::round(out * 100.0) / 100.0;
                    music_edited(m.set_track(t.name, Json::object({{"sends", sends}}), "Send of " + t.name + " to " + b));
                }
                at_track("mus:send:" + t.name + ":" + b);
            }
            ImGui::EndDisabled();
            ImGui::Unindent(20);
        }
        ImGui::Indent(20);
        if (ImGui::TreeNodeEx(("effects (" + std::to_string(t.effects.size()) + ")##fx").c_str(), ImGuiTreeNodeFlags_SpanAvailWidth)) {
            const Json next = effects_editor(u, "fxt:" + t.name, t.effects, json_at(file, "tracks", t.name, "effects"), canEdit);
            if (next.is_array()) music_edited(m.set_track(t.name, Json::object({{"effects", next}}), "Effects of " + t.name));
            ImGui::TreePop();
        }
        ImGui::Unindent(20);
        ImGui::PopID();
    }
    ImGui::BeginDisabled(!canEdit);
    ImGui::SetNextItemWidth(90);
    music_ui::text_field("##newtrack", u.newTrack, 30);
    at_track("mus:new_track_name");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(100);
    if (ImGui::BeginCombo("##newtrackinst", u.newTrackInstrument.c_str())) {
        if (ImGui::Selectable("kit", u.newTrackInstrument == "kit")) u.newTrackInstrument = "kit";
        for (const SongInstrumentInfo& i : song_instruments()) {
            if (ImGui::Selectable(i.name.c_str(), i.name == u.newTrackInstrument)) u.newTrackInstrument = i.name;
            if (ImGui::IsItemHovered()) ImGui::SetTooltip("%s: %s", i.family.c_str(), i.what.c_str());
        }
        ImGui::EndCombo();
    }
    ImGui::SameLine();
    if (ImGui::Button("Add track")) {
        const MusicEditOutcome out = m.edit("Add track " + u.newTrack, Json::array({Json::object({{"op", "add_track"}, {"track", u.newTrack}, {"instrument", u.newTrackInstrument}})}));
        music_edited(out);
        if (out.ok) u.newTrack = m.free_name("track", track_names_of(*m.doc()));
    }
    at_track("mus:add_track");
    ImGui::EndDisabled();

    // ---- buses
    ImGui::Separator();
    ImGui::Text("Buses");
    ImGui::SameLine();
    ImGui::TextDisabled("(a shared effect: the tracks send to it, and it returns only the effect)");
    for (const SongBus& b : doc->mixer.buses) {
        ImGui::PushID(("bus" + b.name).c_str());
        ImGui::Text("%-10s", b.name.c_str());
        ImGui::SameLine(96);
        ImGui::BeginDisabled(!canEdit);
        double out = 0;
        ImGui::TextDisabled("vol");
        ImGui::SameLine();
        if (live_drag(u, "busvol:" + b.name, b.volume, 0.0, 2.0, 0.01f, "%.2f", 64, out))
            music_edited(m.set_mixer(Json::object({{"buses", Json::object({{b.name, Json::object({{"volume", std::round(out * 100.0) / 100.0}})}})}}), "Volume of bus " + b.name));
        at_track("mus:busvol:" + b.name);
        ImGui::SameLine();
        if (music_ui::toggle_button("M", b.mute, ImVec2(24, 0)))
            music_edited(m.set_mixer(Json::object({{"buses", Json::object({{b.name, Json::object({{"mute", !b.mute}})}})}}), std::string(b.mute ? "Unmute bus " : "Mute bus ") + b.name));
        at_track("mus:busmute:" + b.name);
        ImGui::SameLine();
        if (ImGui::SmallButton("remove")) music_edited(m.set_mixer(Json::object({{"buses", Json::object({{b.name, Json()}})}}), "Remove bus " + b.name));
        at_track("mus:bus_remove:" + b.name);
        ImGui::EndDisabled();
        ImGui::Indent(20);
        if (ImGui::TreeNodeEx(("effects (" + std::to_string(b.effects.size()) + ")##fx").c_str(), ImGuiTreeNodeFlags_SpanAvailWidth)) {
            const Json next = effects_editor(u, "fxb:" + b.name, b.effects, json_at(file, "mixer", "buses", b.name.c_str()).is_object() ? json_at(file, "mixer", "buses", b.name.c_str())["effects"] : Json(), canEdit);
            if (next.is_array()) music_edited(m.set_mixer(Json::object({{"buses", Json::object({{b.name, Json::object({{"effects", next}})}})}}), "Effects of bus " + b.name));
            ImGui::TreePop();
        }
        ImGui::Unindent(20);
        ImGui::PopID();
    }
    ImGui::BeginDisabled(!canEdit);
    ImGui::SetNextItemWidth(90);
    music_ui::text_field("##newbus", u.newBus, 30);
    at_track("mus:new_bus_name");
    ImGui::SameLine();
    if (ImGui::Button("Add bus")) music_edited(m.set_mixer(Json::object({{"buses", Json::object({{u.newBus, Json::object({{"volume", 1.0}})}})}}), "Add bus " + u.newBus));
    at_track("mus:add_bus");
    ImGui::EndDisabled();

    // ---- master
    ImGui::Separator();
    ImGui::Text("Master");
    const SongMaster& ms = doc->mixer.master;
    ImGui::BeginDisabled(!canEdit);
    double out = 0;
    ImGui::TextDisabled("song volume");
    ImGui::SameLine(110);
    if (live_drag(u, "songvol", doc->volume, 0.0, 1.5, 0.01f, "%.2f", 64, out)) music_edited(m.set_song(Json::object({{"volume", std::round(out * 100.0) / 100.0}}), "Song volume"));
    at_track("mus:song_volume");
    ImGui::SameLine();
    bool lim = ms.limiter;
    if (ImGui::Checkbox("limiter", &lim)) music_edited(m.set_mixer(Json::object({{"master", Json::object({{"limiter", lim}})}}), lim ? "Limiter on" : "Limiter off"));
    at_track("mus:limiter");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled)) ImGui::SetTooltip("A lookahead peak limiter: the render never goes above the ceiling.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!ms.limiter);
    if (live_drag(u, "ceiling", ms.ceilingDb, -24.0, 0.0, 0.1f, "ceiling %.1f dB", 110, out))
        music_edited(m.set_mixer(Json::object({{"master", Json::object({{"limiter", Json::object({{"ceilingDb", std::round(out * 10.0) / 10.0}, {"release", ms.limiterRelease}})}})}}), "Limiter ceiling"));
    at_track("mus:ceiling");
    ImGui::EndDisabled();
    ImGui::SameLine();
    const char* modes[] = {"style", "off", "target"};
    const int mode = ms.loudness == SongMaster::Loudness::Style ? 0 : ms.loudness == SongMaster::Loudness::Off ? 1 : 2;
    ImGui::SetNextItemWidth(90);
    if (ImGui::BeginCombo("##loudmode", modes[mode])) {
        for (int i = 0; i < 3; ++i) {
            if (ImGui::Selectable(modes[i], i == mode) && i != mode) {
                const Json value = i == 2 ? Json(ms.loudnessLufs) : Json(modes[i]);
                music_edited(m.set_mixer(Json::object({{"master", Json::object({{"loudness", value}})}}), std::string("Loudness: ") + modes[i]));
            }
            at_track(std::string("mus:loudness:") + modes[i]);
        }
        ImGui::EndCombo();
    }
    at_track("mus:loudness");
    if (ImGui::IsItemHovered(ImGuiHoveredFlags_AllowWhenDisabled))
        ImGui::SetTooltip("style: the music loudness of the project's style guide (assets.json audio.loudnessLufs.music) when a bake or a game renders with it; off: the level the tracks add up to; target: the LUFS beside it.\n"
                          "The preview in this panel is made without a style, so it only applies a target.");
    if (mode == 2) {
        ImGui::SameLine();
        if (live_drag(u, "lufs", ms.loudnessLufs, -40.0, -5.0, 0.1f, "%.1f LUFS", 90, out)) music_edited(m.set_mixer(Json::object({{"master", Json::object({{"loudness", std::round(out * 10.0) / 10.0}})}}), "Loudness target"));
        at_track("mus:lufs");
    }
    ImGui::EndDisabled();
    ImGui::Indent(20);
    if (ImGui::TreeNodeEx(("master effects (" + std::to_string(ms.effects.size()) + ")##fx").c_str(), ImGuiTreeNodeFlags_SpanAvailWidth)) {
        const Json next = effects_editor(u, "fxm", ms.effects, json_at(file, "mixer", "master", "effects"), canEdit);
        if (next.is_array()) music_edited(m.set_mixer(Json::object({{"master", Json::object({{"effects", next}})}}), "Master effects"));
        ImGui::TreePop();
    }
    ImGui::Unindent(20);
    if (ImGui::Button("Measure loudness")) {
        u.measured = m.measure();
        if (u.measured.is_null()) notify("The loudness could not be measured: " + m.status(), 1);
    }
    at_track("mus:measure");
    if (ImGui::IsItemHovered()) ImGui::SetTooltip("music.mix: renders the song in memory and reports the loudness and peak of the mix (the preview's own render is not measured).");
    ImGui::SameLine();
    if (u.measured.is_object() && u.measured.contains("master") && u.measured["master"].is_object()) {
        const Json& mm = u.measured["master"];
        const double lufs = mm.value("lufs", 0.0), peak = mm.value("peakDb", 0.0), red = mm.value("limiterReductionDb", 0.0);
        ImGui::Text("%6.1f LUFS   peak %6.1f dB   limiter %4.1f dB", lufs, peak, red);
        if (peak > -0.5 && !ms.limiter) {
            ImGui::SameLine();
            ImGui::TextColored(kWarn, "close to clipping with the limiter off");
        }
    } else {
        ImGui::TextDisabled("not measured yet");
    }
}

}  // namespace fa::editor
