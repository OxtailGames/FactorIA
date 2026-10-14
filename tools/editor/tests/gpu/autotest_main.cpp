// Runs the editor in autotest mode (see fa/editor/editor.h). Exit code 0 = all checks passed.
#include <cstdlib>

#include "fa/editor/editor.h"

int main() {
#if defined(_WIN32)
    if (!std::getenv("FA_EDITOR_AUTOTEST")) _putenv_s("FA_EDITOR_AUTOTEST", "1");  // like setenv(..., 0): "welcome" stays
#else
    setenv("FA_EDITOR_AUTOTEST", "1", 0);
#endif
    return fa::run_editor(fa::EditorOptions{});
}
