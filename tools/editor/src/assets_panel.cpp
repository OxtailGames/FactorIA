// Assets panel: project file browser with image previews; double-click a scene to open it.
#include <algorithm>
#include <cstring>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

const TextureEntry* Editor::texture_for(const std::string& path) {
    auto it = textures_.find(path);
    if (it != textures_.end()) return it->second.failed ? nullptr : &it->second;
    TextureEntry t;
    auto img = load_image(path);
    if (!img || img->empty() || img->width > 8192 || img->height > 8192 ||
        !ui::make_texture(img->width, img->height, img->rgba.data(), t.image, t.view)) {
        t.failed = true;
    } else {
        t.w = img->width;
        t.h = img->height;
    }
    auto& slot = textures_[path] = t;
    return slot.failed ? nullptr : &slot;
}

namespace {
bool is_image(const std::string& p) { return asset_matches("texture", p); }

void build_tree(AssetNode& root, const std::vector<std::string>& files) {
    root = AssetNode{};
    root.isDir = true;
    for (const auto& f : files) {
        AssetNode* cur = &root;
        size_t pos = 0;
        std::string acc;
        while (pos < f.size()) {
            size_t slash = f.find('/', pos);
            const bool last = slash == std::string::npos;
            std::string part = f.substr(pos, last ? std::string::npos : slash - pos);
            acc += (acc.empty() ? "" : "/") + part;
            auto it = std::find_if(cur->children.begin(), cur->children.end(), [&](const AssetNode& n) { return n.name == part; });
            if (it == cur->children.end()) {
                AssetNode n;
                n.name = part;
                n.path = acc;
                n.isDir = !last;
                cur->children.push_back(std::move(n));
                it = cur->children.end() - 1;
            }
            cur = &*it;
            if (last) break;
            pos = slash + 1;
        }
    }
    // folders first, then names
    std::function<void(AssetNode&)> sort = [&](AssetNode& n) {
        std::sort(n.children.begin(), n.children.end(), [](const AssetNode& a, const AssetNode& b) {
            if (a.isDir != b.isDir) return a.isDir;
            return a.name < b.name;
        });
        for (auto& c : n.children) sort(c);
    };
    sort(root);
}

void draw_file(Editor& ed, const std::string& label, const std::string& path) {
    ImGui::PushID(path.c_str());
    ImGuiTreeNodeFlags fl = ImGuiTreeNodeFlags_Leaf | ImGuiTreeNodeFlags_NoTreePushOnOpen | ImGuiTreeNodeFlags_SpanFullWidth;
    if (ed.assetSelected_ == path) fl |= ImGuiTreeNodeFlags_Selected;
    const bool scene = asset_matches("scene", path);
    if (scene) ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(0.55f, 0.85f, 1.0f, 1));
    ImGui::TreeNodeEx(label.c_str(), fl);
    if (scene) ImGui::PopStyleColor();
    if (ImGui::IsItemClicked(ImGuiMouseButton_Left)) ed.assetSelected_ = path;
    if (ImGui::IsItemHovered() && ImGui::IsMouseDoubleClicked(ImGuiMouseButton_Left) && scene) {
        if (ed.dirty()) ed.pendingScene_ = path;
        else ed.open_scene(path);
    }
    if (ImGui::BeginDragDropSource(ImGuiDragDropFlags_SourceAllowNullID)) {
        ImGui::SetDragDropPayload("FA_ASSET", path.c_str(), path.size() + 1);
        ImGui::TextUnformatted(path.c_str());
        ImGui::EndDragDropSource();
    }
    if (ImGui::IsItemHovered() && scene) ImGui::SetTooltip("Double-click to open");
    ImGui::PopID();
}

void draw_node(Editor& ed, const AssetNode& n, bool root) {
    for (const auto& c : n.children) {
        if (c.isDir) {
            ImGui::PushID(c.path.c_str());
            ImGuiTreeNodeFlags fl = ImGuiTreeNodeFlags_SpanFullWidth | ImGuiTreeNodeFlags_OpenOnArrow;
            if (root) fl |= ImGuiTreeNodeFlags_DefaultOpen;
            bool open = ImGui::TreeNodeEx(c.name.c_str(), fl);
            if (open) {
                draw_node(ed, c, false);
                ImGui::TreePop();
            }
            ImGui::PopID();
        } else {
            draw_file(ed, c.name, c.path);
        }
    }
}
}  // namespace

void Editor::draw_assets() {
    if (!ImGui::Begin("Assets")) { ImGui::End(); return; }
    if (time_ - assetsScanned_ > 2.0) {
        assetsScanned_ = time_;
        std::vector<std::string> files;
        for (auto& f : fs::list("", true)) {
            if (f.empty() || f[0] == '.' || f.find("/.") != std::string::npos) continue;
            if (f.rfind("build/", 0) == 0 || f.rfind("node_modules/", 0) == 0) continue;
            files.push_back(f);
        }
        build_tree(assetRoot_, files);
    }
    static std::string filter;
    ImGui::SetNextItemWidth(-1);
    ImGui::InputTextWithHint("##af", "Filter files...", &filter);

    const std::string sel = assetSelected_;
    const bool preview = !sel.empty() && is_image(sel);
    const float previewH = preview ? 150.0f : 0.0f;
    ImGui::BeginChild("##assettree", ImVec2(0, -previewH), ImGuiChildFlags_None);
    if (!filter.empty()) {
        std::vector<std::string> flat;
        std::function<void(const AssetNode&)> collect = [&](const AssetNode& n) {
            for (auto& c : n.children) {
                if (c.isDir) collect(c);
                else if (contains_ci(c.path, filter)) flat.push_back(c.path);
            }
        };
        collect(assetRoot_);
        for (auto& p : flat) draw_file(*this, p, p);
    } else {
        draw_node(*this, assetRoot_, true);
    }
    ImGui::EndChild();

    if (preview) {
        ImGui::Separator();
        const TextureEntry* t = texture_for(sel);
        if (t) {
            const float box = 120.0f;
            float sc = std::min(box / float(t->w), box / float(t->h));
            sc = std::min(sc, 4.0f);
            ImVec2 sz(float(t->w) * sc, float(t->h) * sc);
            ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(t->view, false))), sz);
            ImGui::SameLine();
            ImGui::BeginGroup();
            ImGui::TextUnformatted(fs::filename(sel).c_str());
            ImGui::TextDisabled("%d x %d", t->w, t->h);
            ImGui::TextDisabled("%s", sel.c_str());
            ImGui::EndGroup();
        } else {
            ImGui::TextDisabled("Cannot preview %s", sel.c_str());
        }
    }
    ImGui::End();
}

}  // namespace fa::editor
