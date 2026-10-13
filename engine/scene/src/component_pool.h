// Type-erased storage for one component type.
//
//  * Elements live in fixed-size pages, so a component pointer stays valid
//    until that component is removed (adding others never moves it).
//  * Freed slots are reused LIFO through a free list.
//  * `order_` lists (entity, slot) in insertion order and drives iteration.
//    Removal leaves a tombstone instead of swap-and-pop, so order never changes;
//    the list is compacted when tombstones dominate. Determinism over speed.
#pragma once

#include <cstddef>
#include <memory>
#include <vector>

#include "fa/core/reflect.h"

namespace fa {

class ComponentPool {
public:
    explicit ComponentPool(const TypeInfo& type);
    ~ComponentPool();
    ComponentPool(const ComponentPool&) = delete;
    ComponentPool& operator=(const ComponentPool&) = delete;

    const TypeInfo& type() const { return *type_; }
    std::size_t size() const { return count_; }

    // Default-constructs a component for `e`, or returns the existing one.
    void* add(Entity e);
    void* get(Entity e) const;  // nullptr if `e` has none (or the handle is stale)
    bool has(Entity e) const { return get(e) != nullptr; }
    bool remove(Entity e);      // false if there was nothing to remove
    void clear();

    // Snapshot of owners in insertion order.
    std::vector<Entity> entities() const;

private:
    static constexpr std::size_t kPageSize = 64;
    static constexpr std::uint32_t kNone = UINT32_MAX;

    struct OrderEntry {
        Entity entity;       // null = tombstone
        std::uint32_t slot;
    };

    void* slot_ptr(std::uint32_t slot) const;
    void compact();

    const TypeInfo* type_;
    struct PageDeleter {
        std::align_val_t align;
        void operator()(std::byte* p) const { ::operator delete(p, align); }
    };
    std::vector<std::unique_ptr<std::byte, PageDeleter>> pages_;
    std::vector<std::uint32_t> freeSlots_;
    std::uint32_t nextSlot_ = 0;
    std::vector<OrderEntry> order_;
    std::vector<std::uint32_t> posByEntity_;  // entity.index -> position in order_ (kNone if absent)
    std::size_t count_ = 0;
    std::size_t tombstones_ = 0;
};

}  // namespace fa
