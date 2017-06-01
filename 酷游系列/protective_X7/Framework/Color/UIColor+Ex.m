//
//  UIColor+Ex.m
//  WaterHeater
//
//  Created by wu.xiong on 14-10-23.
//  Copyright (c) 2014年 wu.xiong. All rights reserved.
//

#import "UIColor+Ex.h"

@implementation UIColor (Ex)

+(UIColor *)colorWithR:(float)r G:(float)g B:(float)b Alpha:(float)alpha{
    
    float w=255.0;
    UIColor *color=[UIColor colorWithRed:r/w green:g/w blue:b/w alpha:alpha];
    return color;
}

/*十六进制颜色转换成标准的颜色值*/
+ (UIColor *)colorWithHexString: (NSString *)stringToConvert{
    NSString *cString = [[stringToConvert stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6){
        return [UIColor whiteColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"]) cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"]) cString = [cString substringFromIndex:1];
    if ([cString length] != 6) return [UIColor whiteColor];
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];
    
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
//    return [UIColor colorWithRed:((float) r / 255.0f)
//                           green:((float) g / 255.0f)
//                            blue:((float) b / 255.0f)
//                           alpha:1.0f];
    return [self colorWithR:r G:g B:b Alpha:1.0f];
}
@end
