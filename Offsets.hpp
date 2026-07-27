#ifndef OFFSETS_HPP
#define OFFSETS_HPP

#include <cstdint>

namespace GameOffsets {

    // ── Real offsets from fun.ction.txt ──
    // GameManager::visualCue            → ldrsw x8,[x8,#0x728]
    // Table::frictionProperties         → ldrsw x8,[x8,#0x1e8]
    // VisualCue::setMaxCuePowerOffset:  → ldrsw x8,[x8,#0x48]
    // UserSettingsManager::wideGuideline→ ldrb  w8,[x0,#0x13] (1 BYTE)
    // BallPropertiesCue::getBalls       → ldr   x0,[x0,#0x8]

    inline uintptr_t GameManager_VisualCue        = 0x728;
    inline uintptr_t Table_FrictionProperties     = 0x1E8;
    inline uintptr_t VisualCue_MaxCuePowerOffset  = 0x48;
    inline uintptr_t UserSettings_WideGuideline   = 0x13;
    inline uintptr_t BallProperties_Balls         = 0x8;

    inline void SetOffsets(uintptr_t visualCue,
                           uintptr_t friction,
                           uintptr_t maxPower,
                           uintptr_t wideGuide,
                           uintptr_t balls) {
        GameManager_VisualCue       = visualCue;
        Table_FrictionProperties    = friction;
        VisualCue_MaxCuePowerOffset = maxPower;
        UserSettings_WideGuideline  = wideGuide;
        BallProperties_Balls        = balls;
    }

} // namespace GameOffsets

#endif // OFFSETS_HPP
