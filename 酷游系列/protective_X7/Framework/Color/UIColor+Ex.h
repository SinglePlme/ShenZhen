//
//  UIColor+Ex.h
//  WaterHeater
//
//  Created by wu.xiong on 14-10-23.
//  Copyright (c) 2014年 wu.xiong. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kcolor(r,g,b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0]
#define kcolorAp(r,g,b,ap) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:ap]

@interface UIColor (Ex)

+(UIColor *)colorWithR:(float)r G:(float)g B:(float)b Alpha:(float)alpha;
/*十六进制颜色转换成标准的颜色值*/
+ (UIColor *)colorWithHexString: (NSString *)stringToConvert;
@end
