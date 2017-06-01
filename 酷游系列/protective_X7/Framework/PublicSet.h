//
//  PublicSet.h
//  icolorlive
//
//  Created by wu.xiong on 15/7/1.
//  Copyright (c) 2015年 wu.xiong. All rights reserved.
//

#ifndef icolorlive_PublicSet_h
#define icolorlive_PublicSet_h

#define NSLocString(title) NSLocalizedString(title, @"")

#define afterTimer 0.12

#import "aes.h"
#import "BleAPI.h"
#import "NSDate+Ex.h"
#import "UIColor+Ex.h"
#import "NSObject+plistEx.h"
#import "NSObject+LayoutZoom.h"
#import "MyNavigationController.h"

#import "AFNetworking.h"

#ifdef DEBUG
#define NSSLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#else
#define NSSLog(...)
#endif

#endif
