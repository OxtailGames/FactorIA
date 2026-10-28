// Windows: a thread reads std::cin (a pipe cannot be polled with a timeout the way POSIX descriptors can). The server never
// replaces itself in place here, so nothing depends on how much it reads ahead.
#include <iostream>

#include "fa/mcp/stdio.h"

namespace fa {

std::unique_ptr<LineReader> make_stdin_reader() { return make_stream_reader(std::cin); }

}  // namespace fa
