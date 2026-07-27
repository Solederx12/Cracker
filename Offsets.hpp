#ifndef OFFSETS_HPP
#define OFFSETS_HPP

#include <stdint.h>

namespace GameOffsets {
    // ئۆفێستە ڕاستەقینەکان لە disassembly (fun.ction.txt)
    static uintptr_t GameManager_VisualCue       = 0;   // ldrsw [x8,#0x728]
    static uintptr_t Table_FrictionProperties    = 0;   // ldrsw [x8,#0x1e8]
    static uintptr_t VisualCue_MaxCuePowerOffset = 0;   // ldrsw [x8,#0x48]
    static uintptr_t UserSettings_WideGuideline  = 0;   // ldrb  [x0,#0x13] (1 byte)
    static uintptr_t BallProperties_Balls        = 0;   // ldr   [x0,#0x8]

    // بۆ گونجاندن لەگەڵ کۆنی SetOffsetsـەکەت
    static uintptr_t AimLineFunction   = 0;
    static uintptr_t CueTrajectory     = 0;
    static uintptr_t AntiCheatBypass   = 0;
    static uintptr_t AntiBan           = 0;
    static uintptr_t BypassCrash       = 0;

    inline void SetOffsets(uintptr_t visualCue, uintptr_t friction,
                           uintptr_t maxPower, uintptr_t wideGuide,
                           uintptr_t balls) {
        GameManager_VisualCue       = visualCue;
        Table_FrictionProperties    = friction;
        VisualCue_MaxCuePowerOffset = maxPower;
        UserSettings_WideGuideline  = wideGuide;
        BallProperties_Balls        = balls;

        // گونجاندن لەگەڵ ناوە کۆنەکان
        AimLineFunction = visualCue;
        CueTrajectory   = friction;
        AntiCheatBypass = maxPower;
        AntiBan         = wideGuide;
        BypassCrash     = balls;
    }
}

#endif
