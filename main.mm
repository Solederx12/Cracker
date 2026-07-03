#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <iostream>

// پێناسەکردنی پۆینتەرێک بۆ هەڵگرتنی فەنکشنە ئەسڵییەکە (Original Function)
static id (*orig_fetchDeviceReceipt)(id self, SEL _cmd);

// ئەمە ئەو فەنکشنە نوێیەیە کە ئێمە دەیخەینە جێگای ئەسڵییەکە
id new_fetchDeviceReceipt(id self, SEL _cmd) {
    std::cout << "[CyberEliteCore] fetchDeviceReceipt Hooked Successfully! (Anti-Update Mode)" << std::endl;
    
    // لێرەدا فەیک ڕیسیتێک (Fake Receipt) دروست دەکەین لە جۆری NSData
    // بۆ ئەوەی ڕێگری لە بلۆککردنی یارییەکە بکات (Bypass Code 6902)
    NSString *bypassString = @"Bypass_6902_Active_CyberElite";
    NSData *fakeReceiptData = [bypassString dataUsingEncoding:NSUTF8StringEncoding];
    
    return fakeReceiptData;
}

// 🚀 ئەم بەشە خۆکار لۆد دەبێت کاتێک دایلیبەکە دەخرێتە ناو یارییەکەوە (Constructor)
__attribute__((constructor)) static void init_6902_Bypass_Core() {
    @autoreleasepool {
        // ١. گەڕان بەدوای کڵاسەکەدا لەناو مێمۆری یارییەکە بەبێ ئۆفێست
        Class targetClass = objc_getClass("FBSDKPaymentProductRequestor");
        
        if (targetClass) {
            // ٢. دیاریکردنی ناوی فەنکشنەکە (Selector)
            SEL targetSelector = sel_registerName("fetchDeviceReceipt");
            
            // ٣. تاقیکردنەوەی ئایا فەنکشنەکە Instance Methodـە یان Class Method
            Method originalMethod = class_getInstanceMethod(targetClass, targetSelector);
            if (!originalMethod) {
                originalMethod = class_getClassMethod(targetClass, targetSelector);
            }
            
            if (originalMethod) {
                // ٤. ئەنجامدانی پڕۆسەی Swizzling (گۆڕینی فەنکشنەکە بە کۆدی ئێمە)
                orig_fetchDeviceReceipt = (id (*)(id, SEL))method_getImplementation(originalMethod);
                method_setImplementation(originalMethod, (IMP)new_fetchDeviceReceipt);
                
                std::cout << "[CyberEliteCore] 6902 Bypass Injected Successfully without Offsets!" << std::endl;
            } else {
                std::cout << "[CyberEliteCore] Error: Method fetchDeviceReceipt not found." << std::endl;
            }
        } else {
            std::cout << "[CyberEliteCore] Error: Class FBSDKPaymentProductRequestor not found." << std::endl;
        }
    }
}
