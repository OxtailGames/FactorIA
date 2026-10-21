// Windows: SystemParametersInfo for animations, high contrast and screen reader; the registry for the text size
// (Settings > Accessibility > Text size writes HKCU\SOFTWARE\Microsoft\Accessibility\TextScaleFactor, 100-225).
#define WIN32_LEAN_AND_MEAN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>

#include "fa/platform/accessibility.h"

#pragma comment(lib, "advapi32.lib")

namespace fa {

AccessibilitySettings read_system_accessibility() {
    AccessibilitySettings s;
    BOOL animations = TRUE;
    if (SystemParametersInfoW(SPI_GETCLIENTAREAANIMATION, 0, &animations, 0)) s.reduceMotion = !animations;
    HIGHCONTRASTW hc{};
    hc.cbSize = sizeof(hc);
    if (SystemParametersInfoW(SPI_GETHIGHCONTRAST, sizeof(hc), &hc, 0)) s.highContrast = (hc.dwFlags & HCF_HIGHCONTRASTON) != 0;
    BOOL reader = FALSE;
    if (SystemParametersInfoW(SPI_GETSCREENREADER, 0, &reader, 0)) s.screenReader = reader != FALSE;
    DWORD percent = 0, size = sizeof(percent);
    if (RegGetValueW(HKEY_CURRENT_USER, L"SOFTWARE\\Microsoft\\Accessibility", L"TextScaleFactor", RRF_RT_REG_DWORD, nullptr,
                     &percent, &size) == ERROR_SUCCESS && percent > 0)
        s.textScale = static_cast<float>(percent) / 100.0f;
    return s;
}

}  // namespace fa
