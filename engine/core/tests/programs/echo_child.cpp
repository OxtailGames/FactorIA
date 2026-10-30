// A line-oriented child for the ChildProcess tests (test_child_process.cpp): prints "echo: <line>" for every line on stdin.
// Special lines: "quit" (exit 0), "err <text>" (writes <text> to stderr), "env <NAME>" (prints the variable), "cwd" (prints the
// working directory), "sleep" (reads nothing more, never answers), "twice" (prints two lines).
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <string>

int main() {
    std::string line;
    while (std::getline(std::cin, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line == "quit") return 0;
        if (line.rfind("err ", 0) == 0) {
            std::cerr << line.substr(4) << std::endl;
        } else if (line.rfind("env ", 0) == 0) {
            const char* v = std::getenv(line.substr(4).c_str());
            std::cout << (v ? v : "(unset)") << std::endl;
        } else if (line == "cwd") {
            std::cout << std::filesystem::current_path().string() << std::endl;
        } else if (line == "sleep") {
            std::string never;
            std::getline(std::cin, never);
            return 0;
        } else if (line == "twice") {
            std::cout << "one" << std::endl << "two" << std::endl;
        } else {
            std::cout << "echo: " << line << std::endl;
        }
    }
    return 0;
}
