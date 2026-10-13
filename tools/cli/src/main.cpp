// `factoria`: the single developer binary. See docs/CLI.md.
#include <iostream>
#include <string>
#include <vector>

#include "fa/cli/cli.h"

int main(int argc, char** argv) {
    std::vector<std::string> args(argv + 1, argv + argc);
    return fa::cli::cli_main(args, std::cout, std::cerr, std::cin);
}
