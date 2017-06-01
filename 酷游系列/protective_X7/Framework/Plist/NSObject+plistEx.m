//
//  NSObject+plistEx.m
//  phonecases
//
//  Created by HAOZO.MAC on 15/8/3.
//  Copyright (c) 2015年 HAOZO.MAC. All rights reserved.
//

#import "NSObject+plistEx.h"
#import "NSDate+Ex.h"

#define NSSLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String])




#define C2I(c) ((c >= '0' && c<='9') ? (c-'0') : ((c >= 'a' && c <= 'z') ? (c - 'a' + 10): ((c >= 'A' && c <= 'Z')?(c - 'A' + 10):(-1))))

#define CURR_LANG ([[NSLocale preferredLanguages] objectAtIndex:0])

@implementation NSObject (plistEx)

+(void)createFile{
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:devicePlist]){
        
        NSMutableDictionary *allDic = [NSMutableDictionary dictionary];
        NSMutableDictionary *subDic = [NSMutableDictionary dictionary];
        
        [subDic setValue:@"000000000000" forKey:kMAC];
        [subDic setValue:@"000000" forKey:kPassWord];
        [subDic setValue:@"00000000000000000000000000000000" forKey:kTokenKey];
        [allDic setObject:subDic forKey:@"000000"];
        [allDic writeToFile:devicePlist atomically:YES];
    }
    
    if (![[NSFileManager defaultManager]fileExistsAtPath:debugFile]){
        NSString *str = @"*************************\n\n";
        [str writeToFile:debugFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

// 创建新的文件，按照当天的日期为名称
-(void)creatTxtFile{
    if (![[NSFileManager defaultManager]fileExistsAtPath:[self getPath]]){
        NSString *str = @"00:00:00:00:00:00";
        [str writeToFile:[self getPath] atomically:YES
                encoding:NSUTF8StringEncoding error:nil];
    }
}

-(void)writeMac:(NSString *)mac{
    if (mac) {
        
        [self creatTxtFile];
        NSString *strMac = [NSString stringWithFormat:@"$%@",mac];
        NSMutableString *all = [self readMacFile];
        [all appendString:strMac];
        
        [all writeToFile:[self getPath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

-(NSMutableString *)readMacFile{
    [self creatTxtFile];
    NSMutableString *content = [NSMutableString stringWithContentsOfFile:[self getPath]
                                                                encoding:NSUTF8StringEncoding
                                                                   error:nil];
    return content;
}

-(NSString *)getPath{
    
    NSString *name = [[NSDate date]stringToNSDateFormat:dateFormat4];
    NSString *fileName = [NSString stringWithFormat:@"/Documents/%@.txt",name];
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:fileName];
    return path;
}

/*********************************/
-(NSMutableString *)readDebug{
    NSMutableString *debug = [NSMutableString stringWithContentsOfFile:debugFile
                                                              encoding:NSUTF8StringEncoding
                                                                 error:nil];
    return debug;
}
-(void)writeDebug:(NSString *)content{
    if (content == nil) {
        return;
    }
    NSMutableString *all = [self readDebug];
    [all appendString:content];
    [all appendString:@"\n\n"];
    [all writeToFile:debugFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
}



-(NSMutableDictionary *)readPlist{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithContentsOfFile:devicePlist];
    return dic;
}

-(void)writeDic:(NSDictionary *)dic key:(NSString *)key{
    NSMutableDictionary *allDic = [NSMutableDictionary dictionaryWithContentsOfFile:devicePlist];
    [allDic setObject:dic forKey:key];
    [allDic writeToFile:devicePlist atomically:YES];
}

#pragma mark - 字典转换json
+(NSString *)dictToJsonStr:(NSDictionary *)dict{
    
    NSString *jsonString = nil;
    if([NSJSONSerialization isValidJSONObject:dict]){
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        jsonString =[[NSString alloc] initWithData:jsonData
                                          encoding:NSUTF8StringEncoding];
        if(error) {
            //NSLog(@"Error:%@", error);
            jsonString = @"json转换失败";
        }
    }
    return jsonString;
}

+ (NSString *)DPLocalizedString:(NSString *)translation_key {
    
    NSString * s = NSLocalizedString(translation_key, nil);// 当前语言如果不是中文，默认采用英文
    if (![CURR_LANG isEqualToString:@"zh-Hans-CN"] && ![CURR_LANG isEqualToString:@"zh-Hans"] && ![CURR_LANG isEqualToString:@"zh-Hans-US"]) {
        
        NSString * path = [[NSBundle mainBundle] pathForResource:@"en" ofType:@"lproj"];
        NSBundle * languageBundle = [NSBundle bundleWithPath:path];
        s = [languageBundle localizedStringForKey:translation_key value:@"" table:nil];
    }
    return s;
}

// 十六进制转换成字符串
+(NSString*)dataToHexString:(NSData*)data {
    if (data == nil) {
        return @"";
    }
    Byte *dateByte = (Byte *)[data bytes];
    
    NSString *hexStr=@"";
    for(int i=0;i<[data length];i++) {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",dateByte[i]&0xff]; ///16进制数
        if([newHexStr length]==1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}

//字符串转换十六进制   比如 FF ->0XFF
-(NSData*)convert:(NSString*)str{
    const char* cs = str.UTF8String;
    int count = (int)strlen(cs);
    int8_t  bytes[count / 2];
    for(int i = 0; i<count; i+=2){
        char c1 = *(cs + i);
        char c2 = *(cs + i + 1);
        if(C2I(c1) >= 0 && C2I(c2) >= 0){
            bytes[i / 2] = C2I(c1) * 16 + C2I(c2);
            
        }else{
            return nil;
        }
    }
    return [NSData dataWithBytes:bytes length:count /2];
}

//十六进制转换十进制  比如 0x37 -> 55
-(int)intForData:(NSData *)data{
    uint8_t* a = (uint8_t*) [data bytes];
    NSString *str=[NSString stringWithFormat:@"%d",*a];
    return [str intValue];
}
@end
