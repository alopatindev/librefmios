//
//  DeviceHardware.m
//  librefm
//
//  Created by sbar on 28/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "DeviceHardware.h"

#include <sys/types.h>
#include <sys/sysctl.h>

@implementation DeviceHardware

DeviceHardwareType _type;

- (instancetype)init
{
    if (self = [super init]) {
        _type = DeviceHardwareType_Uninitialized;
    }
    return self;
}

- (DeviceHardwareType)type
{
    if (_type == DeviceHardwareType_Uninitialized) {
        _type = [self calculateHardwareType];
    }
    return _type;
}

- (BOOL)isParallaxEffectSupported
{
    DeviceHardwareType t = [self type];
    return (t >= DeviceHardwareType_iPhone_5_GSM &&
            t <= DeviceHardwareType_iPhone_5s_GSM_CDMA) ||
            t >= DeviceHardwareType_iPad_Mini_WiFi ||
            t == DeviceHardwareType_iPod_Touch_5G
        ? YES : NO;
}

- (DeviceHardwareType)calculateHardwareType
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);

    if ([platform isEqualToString:@"iPhone1,1"])                return DeviceHardwareType_iPhone_1G;
    if ([platform isEqualToString:@"iPhone1,2"])                return DeviceHardwareType_iPhone_3G;
    if ([platform isEqualToString:@"iPhone2,1"])                return DeviceHardwareType_iPhone_3GS;
    if ([platform isEqualToString:@"iPhone3,1"])                return DeviceHardwareType_iPhone_4;
    if ([platform isEqualToString:@"iPhone3,3"])                return DeviceHardwareType_Verizon_iPhone_4;
    if ([platform isEqualToString:@"iPhone4,1"])                return DeviceHardwareType_iPhone_4S;
    if ([platform isEqualToString:@"iPhone5,1"])                return DeviceHardwareType_iPhone_5_GSM;
    if ([platform isEqualToString:@"iPhone5,2"])                return DeviceHardwareType_iPhone_5_GSM_CDMA;
    if ([platform isEqualToString:@"iPhone5,3"])                return DeviceHardwareType_iPhone_5c_GSM;
    if ([platform isEqualToString:@"iPhone5,4"])                return DeviceHardwareType_iPhone_5c_GSM_CDMA;
    if ([platform isEqualToString:@"iPhone6,1"])                return DeviceHardwareType_iPhone_5s_GSM;
    if ([platform isEqualToString:@"iPhone6,2"])                return DeviceHardwareType_iPhone_5s_GSM_CDMA;
    if ([platform isEqualToString:@"iPod1,1"])                  return DeviceHardwareType_iPod_Touch_1G;
    if ([platform isEqualToString:@"iPod2,1"])                  return DeviceHardwareType_iPod_Touch_2G;
    if ([platform isEqualToString:@"iPod3,1"])                  return DeviceHardwareType_iPod_Touch_3G;
    if ([platform isEqualToString:@"iPod4,1"])                  return DeviceHardwareType_iPod_Touch_4G;
    if ([platform isEqualToString:@"iPod5,1"])                  return DeviceHardwareType_iPod_Touch_5G;
    if ([platform isEqualToString:@"iPad1,1"])                  return DeviceHardwareType_iPad;
    if ([platform isEqualToString:@"iPad2,1"])                  return DeviceHardwareType_iPad_2_WiFi;
    if ([platform isEqualToString:@"iPad2,2"])                  return DeviceHardwareType_iPad_2_GSM;
    if ([platform isEqualToString:@"iPad2,3"])                  return DeviceHardwareType_iPad_2_CDMA;
    if ([platform isEqualToString:@"iPad2,4"])                  return DeviceHardwareType_iPad_2_WiFi;
    if ([platform isEqualToString:@"iPad2,5"])                  return DeviceHardwareType_iPad_Mini_WiFi;
    if ([platform isEqualToString:@"iPad2,6"])                  return DeviceHardwareType_iPad_Mini_GSM;
    if ([platform isEqualToString:@"iPad2,7"])                  return DeviceHardwareType_iPad_Mini_GSM_CDMA;
    if ([platform isEqualToString:@"iPad3,1"])                  return DeviceHardwareType_iPad_3_WiFi;
    if ([platform isEqualToString:@"iPad3,2"])                  return DeviceHardwareType_iPad_3_GSM_CDMA;
    if ([platform isEqualToString:@"iPad3,3"])                  return DeviceHardwareType_iPad_3_GSM;
    if ([platform isEqualToString:@"iPad3,4"])                  return DeviceHardwareType_iPad_4_WiFi;
    if ([platform isEqualToString:@"iPad3,5"])                  return DeviceHardwareType_iPad_4_GSM;
    if ([platform isEqualToString:@"iPad3,6"])                  return DeviceHardwareType_iPad_4_GSM_CDMA;
    if ([platform isEqualToString:@"iPad4,1"])                  return DeviceHardwareType_iPad_Air_WiFi;
    if ([platform isEqualToString:@"iPad4,2"])                  return DeviceHardwareType_iPad_Air_Cellular;
    if ([platform isEqualToString:@"iPad4,4"])                  return DeviceHardwareType_iPad_mini_2G_WiFi;
    if ([platform isEqualToString:@"iPad4,5"])                  return DeviceHardwareType_iPad_mini_2G_Cellular;
    if ([platform isEqualToString:@"i386"])                     return DeviceHardwareType_Simulator;
    if ([platform isEqualToString:@"x86_64"])                   return DeviceHardwareType_Simulator;

    return DeviceHardwareType_UnknownNew;
}

@end
