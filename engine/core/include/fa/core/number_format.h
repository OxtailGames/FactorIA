// Numbers and times written the way a language writes them: decimal and group separators and digit forms from a small
// table in the engine (no ICU). Used by the `{v:number:1}` and `{t:duration}` placeholders of string tables and by
// `i18n.number` / `i18n.duration` (docs/LOCALIZATION.md, "Numbers and times").
//
// The table knows en, es, pt, de, fr, it, nl, ru, uk, pl, cs, sk, bg, sv, nb/no, da, fi, tr, id, el, ja, zh, ko, he, ar, fa
// and a few regions (es-MX, pt-PT, de-CH...). Any other language is written like English ("1,234.5").
#pragma once

#include <string>
#include <string_view>

namespace fa {

// `value` with `decimals` digits after the decimal separator (0..9; a negative number keeps the digits the value has,
// at most 9), the integer part grouped and the digits of `language` (a BCP 47 tag; "" or an unknown language = English).
//   en 1234.5 -> "1,234.5"   es "1234,5" / 12345.5 -> "12.345,5"   de "1.234,5"   fr "1 234,5" (narrow no-break space)
//   ar "١٬٢٣٤٫٥" (Arabic-Indic digits)
// NaN and infinities are written "nan", "inf", "-inf".
std::string format_number(double value, int decimals, std::string_view language);

// `seconds` as a time: "m:ss.d" ("1:23.4" for 83.4), "h:mm:ss.d" from one hour on, `decimals` (0..3, default 1) digits
// of the second and the decimal separator and digits of `language`; "-" in front when negative. The whole value is rounded
// first, so 59.96 s is "1:00.0", never "0:60.0".
std::string format_duration(double seconds, int decimals, std::string_view language);

// The languages the number table knows, as base language tags ("ar", "bg", ..., "zh"), for documentation and tests.
const char* const* number_format_languages(std::size_t* count);

}  // namespace fa
