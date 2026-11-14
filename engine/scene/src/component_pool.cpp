#include "component_pool.h"

namespace fa {

namespace {
std::size_t align_up(std::size_t v, std::size_t a) { return (v + a - 1) / a * a; }
}  // namespace

ComponentPool::ComponentPool(const TypeInfo& type) : type_(&type) {}

ComponentPool::~ComponentPool() { clear(); }

void* ComponentPool::slot_ptr(std::uint32_t slot) const {
    std::size_t stride = align_up(type_->size, type_->align);
    return pages_[slot / kPageSize].get() + (slot % kPageSize) * stride;
}

void* ComponentPool::add(Entity e) {
    if (void* existing = get(e)) return existing;
    std::uint32_t slot;
    if (!freeSlots_.empty()) {
        slot = freeSlots_.back();
        freeSlots_.pop_back();
    } else {
        slot = nextSlot_++;
        if (slot / kPageSize >= pages_.size()) {
            std::size_t bytes = align_up(type_->size, type_->align) * kPageSize;
            std::align_val_t align{type_->align};
            auto* mem = static_cast<std::byte*>(::operator new(bytes, align));
            pages_.emplace_back(mem, PageDeleter{align});
        }
    }
    void* ptr = slot_ptr(slot);
    type_->construct(ptr);
    if (posByEntity_.size() <= e.index) posByEntity_.resize(std::size_t(e.index) + 1, kNone);
    posByEntity_[e.index] = std::uint32_t(order_.size());
    order_.push_back({e, slot});
    ++count_;
    return ptr;
}

void* ComponentPool::get(Entity e) const {
    if (e.index >= posByEntity_.size()) return nullptr;
    std::uint32_t pos = posByEntity_[e.index];
    if (pos == kNone) return nullptr;
    const OrderEntry& entry = order_[pos];
    if (entry.entity != e) return nullptr;  // stale generation
    return slot_ptr(entry.slot);
}

bool ComponentPool::remove(Entity e) {
    if (!get(e)) return false;
    std::uint32_t pos = posByEntity_[e.index];
    OrderEntry& entry = order_[pos];
    type_->destruct(slot_ptr(entry.slot));
    freeSlots_.push_back(entry.slot);
    entry.entity = kNullEntity;
    posByEntity_[e.index] = kNone;
    --count_;
    ++tombstones_;
    compact_if_needed();
    return true;
}

void ComponentPool::compact_if_needed() {
    if (walking_ == 0 && tombstones_ > 64 && tombstones_ > order_.size() / 2) compact();
}

void ComponentPool::compact() {
    std::size_t out = 0;
    for (std::size_t i = 0; i < order_.size(); ++i) {
        if (order_[i].entity.is_null()) continue;
        order_[out] = order_[i];
        posByEntity_[order_[out].entity.index] = std::uint32_t(out);
        ++out;
    }
    order_.resize(out);
    tombstones_ = 0;
}

void ComponentPool::clear() {
    for (const OrderEntry& entry : order_)
        if (!entry.entity.is_null()) type_->destruct(slot_ptr(entry.slot));
    order_.clear();
    posByEntity_.clear();
    freeSlots_.clear();
    pages_.clear();
    nextSlot_ = 0;
    count_ = 0;
    tombstones_ = 0;
    ++generation_;
}

void ComponentPool::walk(Visit visit, void* ctx) {
    struct Guard {
        ComponentPool& pool;
        explicit Guard(ComponentPool& p) : pool(p) { ++pool.walking_; }
        ~Guard() {
            if (--pool.walking_ == 0) pool.compact_if_needed();
        }
    } guard{*this};
    const std::uint32_t generation = generation_;
    const std::size_t end = order_.size();  // owners added from now on land at or after `end`
    for (std::size_t i = 0; i < end; ++i) {
        if (generation_ != generation || i >= order_.size()) return;  // clear() ran: nothing left to visit
        const OrderEntry entry = order_[i];                           // a copy: `visit` may grow (reallocate) order_
        if (entry.entity.is_null()) continue;
        visit(ctx, entry.entity, slot_ptr(entry.slot));
    }
}

std::vector<Entity> ComponentPool::entities() const {
    std::vector<Entity> out;
    out.reserve(count_);
    for (const OrderEntry& entry : order_)
        if (!entry.entity.is_null()) out.push_back(entry.entity);
    return out;
}

}  // namespace fa
