// FactorIA core types shared by every module.
//
// Conventions (see docs/ARCHITECTURE.md):
//   * namespace `fa`, snake_case functions, PascalCase types, camelCase JSON keys.
//   * Fallible operations return fa::Result<T>; errors carry a human/AI readable
//     message AND a hint telling the caller how to fix the problem.
//   * Nothing in the runtime throws across module boundaries except
//     fa::CommandError inside command handlers (caught by the registry).
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <utility>
#include <variant>

namespace fa {

using u8 = std::uint8_t;
using u16 = std::uint16_t;
using u32 = std::uint32_t;
using u64 = std::uint64_t;
using i32 = std::int32_t;
using i64 = std::int64_t;

// ---------------------------------------------------------------------------
// Entity handle. Lives in core (not scene) so reflection can describe fields
// that reference other entities. index = slot, generation = reuse counter.
// ---------------------------------------------------------------------------
struct Entity {
    u32 index = UINT32_MAX;
    u32 generation = 0;

    constexpr bool is_null() const { return index == UINT32_MAX; }
    constexpr explicit operator bool() const { return !is_null(); }
    constexpr u64 bits() const { return (u64(generation) << 32) | index; }
    static constexpr Entity from_bits(u64 b) { return Entity{u32(b & 0xffffffffu), u32(b >> 32)}; }
    friend constexpr bool operator==(Entity a, Entity b) { return a.index == b.index && a.generation == b.generation; }
    friend constexpr bool operator!=(Entity a, Entity b) { return !(a == b); }
};
inline constexpr Entity kNullEntity{};

// ---------------------------------------------------------------------------
// Error / Result
// ---------------------------------------------------------------------------
struct Error {
    std::string message;  // what went wrong, with location (file:line, JSON path...)
    std::string hint;     // how to fix it (optional but strongly encouraged)

    std::string to_string() const { return hint.empty() ? message : message + " (hint: " + hint + ")"; }
};

template <class T>
class [[nodiscard]] Result {
public:
    Result(T value) : v_(std::move(value)) {}
    Result(Error err) : v_(std::move(err)) {}

    bool ok() const { return v_.index() == 0; }
    explicit operator bool() const { return ok(); }

    T& value() & { return std::get<0>(v_); }
    const T& value() const& { return std::get<0>(v_); }
    T&& value() && { return std::get<0>(std::move(v_)); }
    T value_or(T fallback) const { return ok() ? std::get<0>(v_) : std::move(fallback); }
    T* operator->() { return &std::get<0>(v_); }
    const T* operator->() const { return &std::get<0>(v_); }
    T& operator*() { return value(); }
    const T& operator*() const { return value(); }

    const Error& error() const { return std::get<1>(v_); }

private:
    std::variant<T, Error> v_;
};

template <>
class [[nodiscard]] Result<void> {
public:
    Result() = default;
    Result(Error err) : err_(std::move(err)), ok_(false) {}

    bool ok() const { return ok_; }
    explicit operator bool() const { return ok_; }
    const Error& error() const { return err_; }

private:
    Error err_;
    bool ok_ = true;
};

inline Error make_error(std::string message, std::string hint = {}) {
    return Error{std::move(message), std::move(hint)};
}

}  // namespace fa

// Assertions stay on in all builds: an AI debugging a game needs loud failures.
#define FA_ASSERT(cond, msg)                                            \
    do {                                                                \
        if (!(cond)) ::fa::detail::assert_fail(#cond, msg, __FILE__, __LINE__); \
    } while (0)

namespace fa::detail {
[[noreturn]] void assert_fail(const char* cond, const char* msg, const char* file, int line);
}
