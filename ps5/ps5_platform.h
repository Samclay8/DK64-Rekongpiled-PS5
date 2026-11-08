// Start-up of DK64: Recompiled as a PS5 title (ps5_platform.cpp).
#pragma once

namespace dk64::ps5 {
    // Opens the buffered log in the title folder, installs the crash handlers and selects SDL's offscreen video
    // driver. Call first in main, before SDL is initialized.
    void init();
    // Writes the buffered log out now (at exit and in error paths).
    void flush_log();
}
