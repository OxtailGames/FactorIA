// The `factoria` command line, callable in-process (tests, editor, embedding).
#pragma once

#include <iosfwd>
#include <string>
#include <vector>

namespace fa::cli {

// Runs `factoria <args...>` (args exclude the program name). Normal output goes to
// `out`, diagnostics to `err`. `in` is the stdin of `factoria mcp` and of `-` arguments.
// Returns the process exit code: 0 ok, 1 failure, 2 usage error.
int cli_main(const std::vector<std::string>& args, std::ostream& out, std::ostream& err, std::istream& in);
// Convenience: std::cin.
int cli_main(const std::vector<std::string>& args, std::ostream& out, std::ostream& err);

}  // namespace fa::cli
