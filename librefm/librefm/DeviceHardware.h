//
//  DeviceHardware.h
//  librefm
//
//  Created by sbar on 28/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    DeviceHardwareType_Uninitialized,
    DeviceHardwareType_iPhone_1G,
    DeviceHardwareType_iPhone_3G,
    DeviceHardwareType_iPhone_3GS,
    DeviceHardwareType_iPhone_4,
    DeviceHardwareType_Verizon_iPhone_4,
    DeviceHardwareType_iPhone_4S,
    DeviceHardwareType_iPhone_5_GSM,
    DeviceHardwareType_iPhone_5_GSM_CDMA,
    DeviceHardwareType_iPhone_5c_GSM,
    DeviceHardwareType_iPhone_5c_GSM_CDMA,
    DeviceHardwareType_iPhone_5s_GSM,
    DeviceHardwareType_iPhone_5s_GSM_CDMA,
    DeviceHardwareType_iPod_Touch_1G,
    DeviceHardwareType_iPod_Touch_2G,
    DeviceHardwareType_iPod_Touch_3G,
    DeviceHardwareType_iPod_Touch_4G,
    DeviceHardwareType_iPod_Touch_5G,
    DeviceHardwareType_iPad,
    DeviceHardwareType_iPad_2_WiFi,
    DeviceHardwareType_iPad_2_GSM,
    DeviceHardwareType_iPad_2_CDMA,
    DeviceHardwareType_iPad_Mini_WiFi,
    DeviceHardwareType_iPad_Mini_GSM,
    DeviceHardwareType_iPad_Mini_GSM_CDMA,
    DeviceHardwareType_iPad_3_WiFi,
    DeviceHardwareType_iPad_3_GSM_CDMA,
    DeviceHardwareType_iPad_3_GSM,
    DeviceHardwareType_iPad_4_WiFi,
    DeviceHardwareType_iPad_4_GSM,
    DeviceHardwareType_iPad_4_GSM_CDMA,
    DeviceHardwareType_iPad_Air_WiFi,
    DeviceHardwareType_iPad_Air_Cellular,
    DeviceHardwareType_iPad_mini_2G_WiFi,
    DeviceHardwareType_iPad_mini_2G_Cellular,
    DeviceHardwareType_Simulator,
    DeviceHardwareType_UnknownNew
} DeviceHardwareType;

@interface DeviceHardware : NSObject

+ (instancetype)instance;
- (DeviceHardwareType)type;
- (BOOL)isParallaxEffectSupported;

@end
