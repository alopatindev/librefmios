//
//  Singleton.m
//  librefm
//
//  Created by alopatindev on 28/06/14.
//  Copyright (c) 2014 Alexander Lopatin. All rights reserved.
//

#import "Singleton.h"

@implementation Singleton

+ (instancetype)instance {
    static id object = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[self alloc] init];
    });
    return object;
}

@end
