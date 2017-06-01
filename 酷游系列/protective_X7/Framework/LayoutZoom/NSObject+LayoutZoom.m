//
//  NSObject+LayoutZoom.m
//  BowLight
//
//  Created by wu.xiong on 16/7/9.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import "NSObject+LayoutZoom.h"

@implementation NSObject (LayoutZoom)

int XZoom(int x){
    
    return x * (ScreenWidth / 320);
}

int YZoom(int y){
    return y * (ScreenHeight / 568);
}

int widthZoom(int width){
    return width * (ScreenWidth / 320);
}

int heightZoom(int height){
    return height * (ScreenHeight / 568);
}
@end
