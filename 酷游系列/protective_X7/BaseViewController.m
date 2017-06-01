//
//  BaseViewController.m
//  protective_X7
//
//  Created by wu.xiong on 16/12/17.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self bleAPIInit];
}

-(NSString *)getDate{
    return [[NSDate date]stringToNSDateFormat:dateFormat1];
}

#pragma mark - 数据的发送
-(NSData*) getTokenSignal { //获取token数据
    
    Byte signal[] = {
        0x06,0x01,0x01,0x01,
        arc4random()%255,arc4random()%255,arc4random()%255,arc4random()%255,
        arc4random()%255,arc4random()%255,arc4random()%255,arc4random()%255,
        arc4random()%255,arc4random()%255,arc4random()%255,arc4random()%255};
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}

-(NSData *)getTokenSignal2:(NSString *)tokenKey{
    Byte signal[] = {
        0x06,0x01,0x01,0x01,
        arc4random()%255,arc4random()%255,arc4random()%255,arc4random()%255,
        arc4random()%255,arc4random()%255,arc4random()%255,arc4random()%255,
        arc4random()%255,arc4random()%255,arc4random()%255,arc4random()%255};
    
    Byte encryptSignal[16];
    // 网络动态获取
    static uint8_t networkAeskey[] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    NSArray *arr = [tokenKey componentsSeparatedByString:@","];
    for (int i = 0; i < arr.count; i++) {
        networkAeskey[i] = [arr[i] intValue];
    }
    
    AES128_ECB_encrypt(signal, networkAeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}

// 获取电量
-(void)getPower:(NSData *)token{
    Byte *tokenByte = (Byte *)[token bytes];
    Byte signal[16] = {
        0x02,0x01,0x01,0x01,
        tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    [self writeData:encryptData];
}

// 纪录操作debug
-(NSString *)debugToString:(NSString *)value{
    return [NSString stringWithFormat:@"%@  [%@]",value,[self getDate]];
}

// 发送数据
-(void)writeData:(NSData *)data{
    [self.bleApi writeData:data forcharauuid:kWriteuuid];
}

#pragma mark - block方法及监听协议
-(void)bleAPIInit{
    self.bleApi = [BleAPI Singleton];
    
    __block typeof(self) weakSelf = self;
    [self.bleApi bleAPIBlocks:^(CBPeripheral *p) { // 发现设备
        [weakSelf foundDevice:p];
    } withconnectBlock:^(CBPeripheral *p) { // 链接设备
        [weakSelf connectDevice:p];
    } withdisconnectBlock:^(CBPeripheral *p) { // 断开链接
        [weakSelf disConnectDevice:p];
    } withnotificationBlock:^(NSData *data) { // 监听获取数据
        [weakSelf notificationData:data];
    } withstopScanBlock:^{ // 停止扫描
        [weakSelf stopScan];
    }];
}
-(void)foundDevice:(CBPeripheral *)p{
    NSLog(@"===============");
}
-(void)connectDevice:(CBPeripheral *)p{
    NSLog(@"connectDevice");
}
-(void)disConnectDevice:(CBPeripheral *)p{
    
}
-(void)notificationData:(NSData *)data{
    
}
-(void)stopScan{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
