//
//  NSObject+LayoutZoom.h
//  BowLight
//
//  Created by wu.xiong on 16/7/9.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define ScreenHeight             [[UIScreen mainScreen] bounds].size.height
#define ScreenWidth              [[UIScreen mainScreen] bounds].size.width

#define iphone4S 480

/*
 4s:320*480  640*960
 5s:320*568  640*1136
 6s:375*667  750＊1334
 6p:414*736
 */

@interface NSObject (LayoutZoom)

int XZoom(int x);
int YZoom(int y);

int widthZoom(int width);
int heightZoom(int height);
@end
