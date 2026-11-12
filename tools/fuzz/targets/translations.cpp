// The translation readers behind i18n.import: a CSV (comma, semicolon or tab, quoted fields, a BOM) or an XLIFF file from any
// bytes. The input is read as CSV, as XLIFF and with the file-name guess; none may crash.
#include <cstddef>
#include <cstdint>

#include "fa/tooling/translations.h"
#include "fuzz_support.h"

extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    static const bool once = (fa::fuzz::quiet(), true);
    (void)once;
    const std::string_view text = fa::fuzz::as_text(data, size);
    (void)fa::read_csv(text);
    (void)fa::read_xliff(text);
    (void)fa::read_translation_file(text, "fuzz.csv");
    (void)fa::read_translation_file(text, "fuzz.xlf");
    (void)fa::read_translation_file(text, "fuzz");
    return 0;
}
