// Private files on Windows: a protected DACL with one entry (full control for the current user), given to the file when it is
// created (CreateFileW with SECURITY_ATTRIBUTES), so the secret never exists with the folder's inherited permissions.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include <aclapi.h>
#include <sddl.h>

#include <algorithm>
#include <string>
#include <vector>

#include "private_file_os.h"

namespace fa::detail {

namespace {

std::string win_error(const char* what, DWORD code) {
    return std::string(what) + " (Windows error " + std::to_string(code) + ")";
}

// The security descriptor "protected DACL, allow FILE_ALL_ACCESS to the current user, nothing else". `problem` is set on failure.
// Free the result with LocalFree.
PSECURITY_DESCRIPTOR owner_only_descriptor(std::string& problem) {
    HANDLE token = nullptr;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &token)) {
        problem = win_error("cannot open the process token", GetLastError());
        return nullptr;
    }
    DWORD size = 0;
    GetTokenInformation(token, TokenUser, nullptr, 0, &size);
    std::vector<char> buffer(size ? size : 1);
    PSECURITY_DESCRIPTOR sd = nullptr;
    if (size == 0 || !GetTokenInformation(token, TokenUser, buffer.data(), size, &size)) {
        problem = win_error("cannot read the user of the process", GetLastError());
    } else {
        LPWSTR sidText = nullptr;
        if (!ConvertSidToStringSidW(reinterpret_cast<TOKEN_USER*>(buffer.data())->User.Sid, &sidText)) {
            problem = win_error("cannot read the user's SID", GetLastError());
        } else {
            // D: DACL, P: protected (no inheritance from the folder), one ACE: Allow, FILE_ALL_ACCESS, this user.
            const std::wstring sddl = L"D:P(A;;FA;;;" + std::wstring(sidText) + L")";
            LocalFree(sidText);
            if (!ConvertStringSecurityDescriptorToSecurityDescriptorW(sddl.c_str(), SDDL_REVISION_1, &sd, nullptr)) {
                sd = nullptr;
                problem = win_error("cannot build the permissions", GetLastError());
            }
        }
    }
    CloseHandle(token);
    return sd;
}

}  // namespace

std::string create_private_file(const std::filesystem::path& file, std::string_view bytes) {
    std::string problem;
    PSECURITY_DESCRIPTOR sd = owner_only_descriptor(problem);
    if (!sd) return problem;
    SECURITY_ATTRIBUTES sa{sizeof sa, sd, FALSE};
    // CREATE_NEW: the name is unique; an existing file there is somebody else's and is never written through. No sharing while
    // the secret is written.
    HANDLE h = CreateFileW(file.c_str(), GENERIC_WRITE, 0, &sa, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    const DWORD createError = GetLastError();
    LocalFree(sd);
    if (h == INVALID_HANDLE_VALUE) return win_error("cannot create the file", createError);
    std::size_t done = 0;
    while (done < bytes.size()) {
        const DWORD chunk = static_cast<DWORD>(std::min<std::size_t>(bytes.size() - done, 1u << 20));
        DWORD written = 0;
        if (!WriteFile(h, bytes.data() + done, chunk, &written, nullptr) || written == 0) {
            const DWORD e = GetLastError();
            CloseHandle(h);
            return win_error("cannot write the file (is the disk full?)", e);
        }
        done += written;
    }
    if (!CloseHandle(h)) return win_error("cannot close the file", GetLastError());
    return {};
}

std::string restrict_to_owner(const std::filesystem::path& file) {
    std::string problem;
    PSECURITY_DESCRIPTOR sd = owner_only_descriptor(problem);
    if (!sd) return problem;
    BOOL present = FALSE, defaulted = FALSE;
    PACL dacl = nullptr;
    if (!GetSecurityDescriptorDacl(sd, &present, &dacl, &defaulted) || !present || !dacl) {
        problem = win_error("cannot read the permissions just built", GetLastError());
        LocalFree(sd);
        return problem;
    }
    std::wstring name = file.native();  // SetNamedSecurityInfoW takes a non-const string
    const DWORD rc = SetNamedSecurityInfoW(name.data(), SE_FILE_OBJECT,
                                           DACL_SECURITY_INFORMATION | PROTECTED_DACL_SECURITY_INFORMATION, nullptr,
                                           nullptr, dacl, nullptr);
    LocalFree(sd);
    if (rc != ERROR_SUCCESS) return win_error("cannot set the permissions", rc);
    return {};
}

}  // namespace fa::detail
