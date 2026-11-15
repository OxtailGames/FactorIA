#include "selection.h"

#include <algorithm>

namespace fa::editor {

int Selection::index_of(const std::string& id) const {
    const auto it = std::find(ids_.begin(), ids_.end(), id);
    return it == ids_.end() ? -1 : int(it - ids_.begin());
}

void Selection::erase_at(size_t i) {
    const bool wasPrimary = ids_[i] == primary_;
    ids_.erase(ids_.begin() + std::ptrdiff_t(i));
    if (wasPrimary) primary_ = ids_.empty() ? std::string() : ids_.back();
}

void Selection::replace(const std::string& id) {
    ids_.clear();
    primary_.clear();
    if (id.empty()) return;
    ids_.push_back(id);
    primary_ = id;
}

void Selection::add(const std::string& id) {
    if (id.empty()) return;
    if (index_of(id) < 0) ids_.push_back(id);
    primary_ = id;
}

void Selection::toggle(const std::string& id) {
    if (id.empty()) return;
    const int i = index_of(id);
    if (i < 0) add(id);
    else erase_at(size_t(i));
}

bool Selection::range(const std::string& from, const std::string& to, const std::vector<std::string>& ordered,
                      bool additive) {
    const auto a = std::find(ordered.begin(), ordered.end(), from);
    const auto b = std::find(ordered.begin(), ordered.end(), to);
    if (a == ordered.end() || b == ordered.end()) return false;
    if (!additive) {
        ids_.clear();
        primary_.clear();
    }
    const auto lo = std::min(a, b), hi = std::max(a, b);
    for (auto it = lo; it <= hi; ++it)
        if (index_of(*it) < 0) ids_.push_back(*it);
    primary_ = to;
    return true;
}

void Selection::remove(const std::string& id) {
    const int i = index_of(id);
    if (i >= 0) erase_at(size_t(i));
}

void Selection::clear() {
    ids_.clear();
    primary_.clear();
}

int Selection::prune(const std::function<bool(const std::string&)>& exists) {
    const size_t before = ids_.size();
    ids_.erase(std::remove_if(ids_.begin(), ids_.end(), [&](const std::string& id) { return !exists(id); }), ids_.end());
    if (index_of(primary_) < 0) primary_ = ids_.empty() ? std::string() : ids_.back();
    return int(before - ids_.size());
}

bool Selection::contains(const std::string& id) const { return index_of(id) >= 0; }

}  // namespace fa::editor
