#include <doctest.h>

#include "fa/core/i18n.h"
#include "fa/platform/system_language.h"

using namespace fa;

TEST_CASE("system language: the Linux variables give BCP 47 tags in order") {
    using V = std::vector<std::string>;
    CHECK(posix_environment_languages("", "", "", "es_ES.UTF-8") == V{"es-ES"});
    CHECK(posix_environment_languages("de:es_ES:en", "", "", "fr_FR.UTF-8") == V{"de", "es-ES", "en", "fr-FR"});
    CHECK(posix_environment_languages("", "pt_BR.UTF-8", "pt_BR", "en_US.UTF-8") == V{"pt-BR", "en-US"});  // repeated tags are dropped
    CHECK(posix_environment_languages("", "C", "POSIX", "C.UTF-8").empty());  // no language at all
    CHECK(posix_environment_languages("", "", "", "").empty());
    CHECK(posix_environment_languages("", "", "", "sr_RS@latin") == V{"sr-RS"});
    CHECK(posix_environment_languages("", "", "", "zh_CN") == V{"zh-CN"});
}

TEST_CASE("system language: the languages of this system are tags") {
    for (const std::string& tag : system_languages()) {
        CAPTURE(tag);
        CHECK(is_language_tag(tag));
    }
}
