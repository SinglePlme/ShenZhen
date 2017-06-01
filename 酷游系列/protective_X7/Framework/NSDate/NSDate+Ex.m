//
//  NSDate+Ex.m
//  NSDate
//
//  Created by wu.xiong on 14-10-27.
//  Copyright (c) 2014年 wu.xiong. All rights reserved.
//

#import "NSDate+Ex.h"

@implementation NSDate (Ex)

//时区转换，取得系统时区，取得格林威治时间差秒
-(NSDate *)dateForsystemTimeZone{
    NSTimeInterval  timeZoneOffset=[[NSTimeZone systemTimeZone] secondsFromGMT];
    return [self dateByAddingTimeInterval:timeZoneOffset];
}
// 获取时间的日历
-(NSDateComponents *)DateCalendar{
    
//    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
//    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    
    NSInteger unitFlags = NSCalendarUnitYear |//int week 1是星期天, 7是星期六;
    NSCalendarUnitMonth | NSCalendarUnitDay |
    NSCalendarUnitWeekday | NSCalendarUnitWeekOfYear |
    NSCalendarUnitHour | NSCalendarUnitMinute |
    NSCalendarUnitSecond;
    comps = [calendar components:unitFlags fromDate:self];
    return comps;
}

// 获取当前时间的毫秒数
-(NSString *)stringMSForDate{
    
    
    //    NSString *timeSp = [NSString stringWithFormat:@"%ld", (long)[[NSDate date] timeIntervalSince1970]];
    //    NSLog(@"time sp %@  .length %ld",timeSp,timeSp.length);
    
//    NSString *str=@"1418220814911";
//    NSLog(@"str %@  .length %ld",str,str.length);
    
//    NSDate* dat = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval a=[self timeIntervalSince1970]*1000;  //  *1000 是精确到毫秒，不乘就是精确到秒
    NSString *timeString = [NSString stringWithFormat:@"%0.f", a]; //转为字符型
    
//    NSLog(@"timeString %@  .length %ld",timeString,timeString.length);
    return timeString;
//    NSLog(@"=== %ld", time(NULL));  // 这句也可以获得时间戳，跟上面一样，精确到秒
    
//    UInt64 recordTime = [[NSDate date] timeIntervalSince1970]*1000;
//    NSLog(@"record time %llu",recordTime);
//    NSString *timeSp = [NSString stringWithFormat:@"%llu",recordTime];
}

#pragma mark - 时间和字符串格式的转换
-(NSString*)stringToNSDateFormat:(NSString *)format{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:format];
    NSString *strDate = [dateFormatter stringFromDate:self];
    return strDate;
}
@end
