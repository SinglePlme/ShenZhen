//
//  BaseViewController.h
//  protective_X7
//
//  Created by wu.xiong on 16/12/17.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PublicSet.h"

static uint8_t aeskey[] = {32,87,47,82,54,75,63,71,48,80,65,88,17,99,45,43}; // 原始设置
static uint8_t modifyKey[] = {36,87,48,82,54,75,26,71,48,80,65,88,12,99,45,23}; // 出厂修改


@interface BaseViewController : UIViewController

@property(nonatomic,strong)BleAPI *bleApi;

#pragma mark - 数据的发送

-(NSString *)getDate;

-(void)writeData:(NSData *)data;

-(NSData*) getTokenSignal; //组装命令 token
-(NSData *)getTokenSignal2:(NSString *)tokenKey;

-(void)getPower:(NSData *)token; // 获取电量


-(NSString *)debugToString:(NSString *)value;

#pragma mark - block方法及监听协议
-(void)bleAPIInit;
-(void)foundDevice:(CBPeripheral *)p;
-(void)connectDevice:(CBPeripheral *)p;
-(void)disConnectDevice:(CBPeripheral *)p;
-(void)notificationData:(NSData *)data;
-(void)stopScan;
@end
