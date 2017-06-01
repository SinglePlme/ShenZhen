//
//  NSDate+Ex.h
//  NSDate
//
//  Created by wu.xiong on 14-10-27.
//  Copyright (c) 2014年 wu.xiong. All rights reserved.
//

#import <Foundation/Foundation.h>

#define dateFormat1 @"yyyy-MM-dd HH:mm:ss"
#define dateFormat2 @"yyyy-MM-dd HH:mm"
#define dateFormat3 @"yyyy-MM-dd"
#define dateFormat4 @"yyyy_MM_dd"

@interface NSDate (Ex)

//时区转换，取得系统时区 - 正确的当前时间，取得格林威治时间差秒
-(NSDate *)dateForsystemTimeZone;

// 获取当前时间的日历
-(NSDateComponents *)DateCalendar;

// 获取当前时间的毫秒数
-(NSString *)stringMSForDate;

#pragma mark - 时间和字符串格式的转换
-(NSString*)stringToNSDateFormat:(NSString *)format;
@end
