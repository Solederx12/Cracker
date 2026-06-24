#ifndef OFFSETS_HPP
#define OFFSETS_HPP

#include <stdint.h>

namespace GameOffsets {
    // پاراستنی هەمان ستایلی خۆت بۆ پێناسەکردنی گۆڕاوەکان
    static uintptr_t AimLineFunction = 0;
    static uintptr_t CueTrajectory = 0;
    static uintptr_t AntiCheatBypass = 0;
    static uintptr_t AntiBan = 0;
    static uintptr_t BypassCrash = 0;

    // فەنکشنەکە نوێکراوەتەوە بۆ وەرگرتنی هەر ٥ بەها گرنگەکە
    inline void SetOffsets(uintptr_t aim, uintptr_t trajectory, uintptr_t anticheat, uintptr_t antiban, uintptr_t crash) {
        AimLineFunction = aim;
        CueTrajectory = trajectory;
        AntiCheatBypass = anticheat;
        AntiBan = antiban;
        BypassCrash = crash;
    }
}

#endif
