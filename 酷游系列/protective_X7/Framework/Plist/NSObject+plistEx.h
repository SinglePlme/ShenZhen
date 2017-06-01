//
//  NSObject+plistEx.h
//  phonecases
//
//  Created by HAOZO.MAC on 15/8/3.
//  Copyright (c) 2015年 HAOZO.MAC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMAC @"mac"
#define kPassWord @"pwd"
#define kTokenKey @"key"

#define devicePlist [NSHomeDirectory() stringByAppendingPathComponent:@"/Documents/device.plist"]

#define debugFile [NSHomeDirectory() stringByAppendingPathComponent:@"/Documents/debug.txt"]

@interface NSObject (plistEx)


// 读取mac地址
-(void)creatTxtFile;
-(void)writeMac:(NSString *)mac;
-(NSMutableString *)readMacFile;
-(NSString *)getPath;
/********************************************************/
+(void)createFile;
-(NSMutableDictionary *)readPlist;
-(void)writeDic:(NSDictionary *)dic key:(NSString *)key;


#pragma mark - 字典转换json
+(NSString *)dictToJsonStr:(NSDictionary *)dict;

-(NSMutableString *)readDebug;
-(void)writeDebug:(NSString *)content;


+ (NSString *)DPLocalizedString:(NSString *)translation_key;
+(NSString*)dataToHexString:(NSData*)data;// 十六进制转换成字符串
-(NSData*)convert:(NSString*)str;//字符串转换十六进制   比如 FF ->0XFF
-(int)intForData:(NSData *)data;//十六进制转换十进制  比如 0x37 -> 55
@end
