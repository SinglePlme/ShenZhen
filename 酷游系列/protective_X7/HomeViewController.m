//
//  HomeViewController.m
//  protective_X7
//
//  Created by wu.xiong on 16/12/17.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import "HomeViewController.h"
#import "STQRCodeController.h"

//#import "PublicSet.h"

#define found_Device @"发现该设备"
#define connect_Device @"设备已链接"
#define disConnect_Device @"设备已断开"

@interface HomeViewController ()<STQRCodeControllerDelegate,UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLb;
@property (weak, nonatomic) IBOutlet UILabel *macLb;
@property (weak, nonatomic) IBOutlet UILabel *statuLb;
@property (weak, nonatomic) IBOutlet UILabel *contrlLb;

@property (weak, nonatomic) IBOutlet UILabel *powLb;
@property (weak, nonatomic) IBOutlet UILabel *openCountLb;
@property (weak, nonatomic) IBOutlet UIButton *openLockBt;

@property (weak, nonatomic) IBOutlet UIButton *pwdBt1;
@property (weak, nonatomic) IBOutlet UIButton *pwdBt2;

@property (weak, nonatomic) IBOutlet UIButton *deviceIDBt;

@property (weak, nonatomic) IBOutlet UIButton *upLoadBt;

@property (weak, nonatomic) IBOutlet UIButton *backBt;

@property(strong,nonatomic)NSData *tokenData; // 获取token值

@property(nonatomic)BOOL ismodify; // 判断修改密钥标识


@property(strong,nonatomic)NSString *passWordStr; // 随机生成密码和密钥
@property(strong,nonatomic)NSString *tokenKeyStr; //
@property(strong,nonatomic)NSString *macStr; // 解析mac地址 AB:12:D3...


@property(strong,nonatomic)NSString *scanResult; //二维码扫描ID

@property(strong,nonatomic)CBPeripheral *connectDevice; // 当前链接的设备
@property(assign, nonatomic)NSInteger count; //开锁的次数


@property(assign,nonatomic)int readPower; // 读取电量
@property(strong,nonatomic)NSDictionary *resultDic;

@property(strong,nonatomic)NSMutableArray *deviceArrays;

@property(strong,nonatomic)NSMutableDictionary *debugDic;
@end

@implementation HomeViewController

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter]postNotificationName:@"refList" object:nil];
}

-(void)nilBackItime{
    
    UIButton *left=[UIButton buttonWithType:UIButtonTypeCustom];
    left.frame=CGRectMake(0, 0, 25, 25);
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:left];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.title = @"设备操作";
    [self bleAPIInit];
    [self initPassWord];
    
    if (!self.deviceID.length) {
        self.contrlLb.text = @"MAC获取失败";
        return;
    }
    self.connectDevice = nil;
    for (CBPeripheral *p in self.bleApi.searchDeviceArrays) {
        if ([[p.identifier UUIDString] isEqualToString:self.deviceID]) {
            self.connectDevice = p;
        }
    }
    if (!self.connectDevice) {
        self.contrlLb.text = @"没有找到链接的设备 &&&&&&";
        return;
    }
    [self.bleApi didConnection:@[self.connectDevice]];
    
    NSData *data = [self.bleApi.MACDictionary objectForKey:self.deviceID];
    NSString *str = [NSObject dataToHexString:[data subdataWithRange:NSMakeRange(data.length-1, 1)]];
    
    if ([str isEqualToString:@"00"]) { //0-已开启  1-已关闭
        self.contrlLb.text = @"当前锁状态:已开启...";
        [self setEnabled:self.openLockBt isEnabled:YES];
    }
    if ([str isEqualToString:@"01"]) {
        self.contrlLb.text = @"当前锁状态:已关闭...";
        [self setEnabled:self.openLockBt isEnabled:NO];
    }
}
#pragma mark - 蓝牙监听协议
-(void)foundDevice:(CBPeripheral *)p{
}
-(void)connectDevice:(CBPeripheral *)p{
    NSString *rssi = [self.bleApi.RSSIDictionary objectForKey:[p.identifier UUIDString]];
    NSData *data = [self.bleApi.MACDictionary objectForKey:[p.identifier UUIDString]];
    NSString *mac = [NSObject dataToHexString:[data subdataWithRange:NSMakeRange(2, 6)]];
    
    // 自定义mac格式
    NSMutableString *content = [NSMutableString string];
    for (int i = 0; i < mac.length / 2; i++) {
        NSString *str = [mac substringWithRange:NSMakeRange(i*2, 2)];
        if (i == 0) {
            [content appendString:[str uppercaseString]];
        }else{
            [content appendString:@":"];
            [content appendString:[str uppercaseString]];
        }
    }
    self.macStr = content;
    
    NSString *value = [NSString stringWithFormat:@"链接设备 MAC%@",self.macStr];
    [self.debugDic setValue:[self debugToString:value] forKey:debug_connect];
    
    [self saveDeviceInfo];
    [self setText:p.name UUID:[p.identifier UUIDString] MAC:mac RSSI:rssi Statu:connect_Device];
    
    // 发送获取token数据指令
//    NSSLog(@"链接成功，获取token指令");
    [self performSelector:@selector(writeData:) withObject:[self getTokenSignal] afterDelay:2];
}

-(void)disConnectDevice:(CBPeripheral *)p{
    self.statuLb.text = @"设备已断开";
    
    NSString *value = [NSString stringWithFormat:@"断开链接 MAC%@",self.macStr];
    [self.debugDic setValue:[self debugToString:value] forKey:debug_disconnect];
}

-(void)notificationData:(NSData *)data{
    
    Byte *signalByte = (Byte *)[data bytes];
    Byte decryptSignal[16];
    
    AES128_ECB_decrypt(signalByte, aeskey, decryptSignal);//AES 128解密
    
    NSData *d2 = [NSData dataWithBytes:decryptSignal length:16];
    NSString *desryptStr = [NSObject dataToHexString:d2];
    
//    NSLog(@"解密数据 :%@",d2);
    // 获取正确的token
    if ([desryptStr hasPrefix:@"0602"]) { //07
//        NSLog(@"解密数据 :%@",d2);
        self.tokenData = [d2 subdataWithRange:NSMakeRange(3, 4)];
        
        NSString *value = [NSString stringWithFormat:@"获取token:%@ MAC:%@",[NSObject dataToHexString:self.tokenData],self.macStr];
        [self.debugDic setValue:[self debugToString:value] forKey:debug_getToken];
        
        
        
        int v1 = [self intForData:[d2 subdataWithRange:NSMakeRange(8, 1)]];
        int v2 = [self intForData:[d2 subdataWithRange:NSMakeRange(9, 1)]];
        NSString *version = [NSString stringWithFormat:@"设备操作 version:%d.%d",v1,v2];
        self.title = version;
        
        
        
        [self performSelector:@selector(getPower:) withObject:self.tokenData afterDelay:1];
        [self writeData:[self getLockStatu]]; // 获取当前锁的开关状态
    }
    
    if ([desryptStr hasPrefix:@"020201"]) { // 获取电量
        if ([desryptStr hasPrefix:@"020201ff"]){
            self.contrlLb.text = @"获取电量失败";
            [self.debugDic setValue:[self debugToString:@"获取电量失败"] forKey:debug_PowErr];
        }else{
            
            self.readPower = [NSObject intForData:[d2 subdataWithRange:NSMakeRange(3, 1)]];
            NSString *powStr = [NSString stringWithFormat:@"%d%@",self.readPower,@"%"];
            self.powLb.text = powStr;
            self.contrlLb.text = @"获取电量成功";
            [self.debugDic setValue:[self debugToString:powStr] forKey:debug_Pow];
            
            if (self.readPower >=95) {
                [self setEnabled:self.openLockBt isEnabled:YES];
                [self setEnabled:self.pwdBt1 isEnabled:NO];
                [self setEnabled:self.pwdBt2 isEnabled:NO];
                [self setEnabled:self.deviceIDBt isEnabled:NO];
                [self setEnabled:self.upLoadBt isEnabled:NO];
                [self setEnabled:self.backBt isEnabled:NO];
            
            }else{
                self.contrlLb.text = @"电量低于95%,不可使用...";
                [self setEnabled:self.pwdBt1 isEnabled:NO];
                [self setEnabled:self.pwdBt2 isEnabled:NO];
                [self setEnabled:self.deviceIDBt isEnabled:NO];
                [self setEnabled:self.upLoadBt isEnabled:NO];
                [self setEnabled:self.backBt isEnabled:NO];
                [self.debugDic setValue:[self debugToString:@"电量低于95%,不可使用"]
                                 forKey:debug_PowErr];
            }
        }
    }
    
    
    
    if ([desryptStr hasPrefix:@"05080100"]) {
        self.contrlLb.text = @"当前锁状态:已关闭...";
        [self setEnabled:self.openLockBt isEnabled:YES];
        if (self.count < 3) {
            [self performSelector:@selector(openLock) withObject:nil afterDelay:1.5];// 自动开锁
        }
        else{
            [self setEnabled:self.pwdBt1 isEnabled:YES];
            NSSLog(@"自动修改密码");// 自动修改密码
            [self performSelector:@selector(changePwdEvent:) withObject:nil afterDelay:1];
        }
    }
    if ([desryptStr hasPrefix:@"05080101"]) {
        self.contrlLb.text = @"当前锁状态:&&&关锁失败,超时!!!!";
        [self setEnabled:self.openLockBt isEnabled:YES];
        [self.debugDic setValue:[self debugToString:@"关锁失败,超时!"] forKey:debug_closeTimeOut];
    }

    
    
    //0x05 0x0f 0x01 0x00   已开启 0x05 0x0f 0x01 0x01   已关闭
    if ([desryptStr hasPrefix:@"050f0100"]) {
        self.contrlLb.text = @"当前锁状态:已开启...";
        [self setEnabled:self.openLockBt isEnabled:NO];
    }
    else{
        self.contrlLb.text = @"当前锁状态:已关闭...";
        [self setEnabled:self.openLockBt isEnabled:YES];
    }
    
    
    if ([desryptStr hasPrefix:@"05020100"]) {
        
        [self setEnabled:self.openLockBt isEnabled:NO];
        self.contrlLb.text = @"开锁成功";
        self.count++;
        self.openCountLb.text = [NSString stringWithFormat:@"开锁次数: %ld",self.count];
        [self.debugDic setValue:[self debugToString:@"开锁成功"] forKey:debug_openOK];
    }
    if ([desryptStr hasPrefix:@"05020101"]) {
        self.contrlLb.text = @"开锁失败";
        [self setEnabled:self.openLockBt isEnabled:YES];
        [self.debugDic setValue:[self debugToString:@"开锁失败"] forKey:debug_openErr];
    }
    
    
    
    
    if ([desryptStr hasPrefix:@"05050100"]) {
        self.contrlLb.text = @"密码修改成功";
        [self setEnabled:self.pwdBt2 isEnabled:YES];
        
        [self.debugDic setValue:[self debugToString:@"密码修改成功"] forKey:debug_pwdOK];
        
        [self nilBackItime];
        // 自动修改密钥
        [self performSelector:@selector(modifyEvent:) withObject:nil afterDelay:1];
    }
    if ([desryptStr hasPrefix:@"05050101"]) {
        self.contrlLb.text = @"...密码修改失败...";
        [self setEnabled:self.pwdBt2 isEnabled:NO];
        
        [self.debugDic setValue:[self debugToString:@"...密码修改失败..."] forKey:debug_pwdErr];
    }
    
    
    
    
    if ([desryptStr hasPrefix:@"cb070101"] && self.ismodify) { // 发送修改密钥的第二组数据
        [self writeData:[self getModifyDdata2]];
        NSLog(@"发送修改密钥的第二组数据......");
    }
    if ([desryptStr hasPrefix:@"07030100"]) {
        self.contrlLb.text = @"＊密钥修改成功＊";
        self.ismodify = NO;
        [self setEnabled:self.deviceIDBt isEnabled:YES];
        
        [self.debugDic setValue:[self debugToString:@"＊密钥修改成功＊"] forKey:debug_tokenOK];
        
        // 自动扫描二维码  获取gpsID
        [self searchEvent:self.deviceIDBt];
//        [self performSelector:@selector(searchEvent:) withObject:nil afterDelay:1];
    }
    
    
    if ([desryptStr hasPrefix:@"07030101"]) {
        self.contrlLb.text = @"＊＊＊密钥修改失败＊＊＊";
        [self setEnabled:self.deviceIDBt isEnabled:NO];
        [self.debugDic setValue:[self debugToString:@"＊密钥修改失败＊"] forKey:debug_tokenErr];
    }
    
    
    if ([desryptStr hasPrefix:@"050d0100"]) {
        self.contrlLb.text = @"关锁成功...";
        [self.debugDic setValue:[self debugToString:@"关锁成功..."] forKey:debug_closeOK];
    }
    if ([desryptStr hasPrefix:@"050d0101"]) {
        self.contrlLb.text = @"关锁失败...";
        [self.debugDic setValue:[self debugToString:@"关锁失败..."] forKey:debug_closeErr];
    }
    
    
    if ([desryptStr hasPrefix:@"03020100"]) {
        self.contrlLb.text = @"开始升级";
    }
    if ([desryptStr hasPrefix:@"03020101"]) {
        self.contrlLb.text = @"不支持升级";
        self.ismodify = NO;
    }
}

#pragma mark 返回
- (IBAction)networkOpenLockEvent:(UIButton *)sender {
    
    [self clearMsg];
}

// 数据服务器请求成功,开始链接设备
-(void)starNetworkOpenLock{
    if (!self.deviceID) {
        self.contrlLb.text = @"无法获取设备...请返回列表重新操作!";
        return;
    }
    self.contrlLb.text = @"链接开锁中...";
    [self performSelector:@selector(netWorkDidConnect) withObject:nil afterDelay:2];
}

-(void)netWorkDidConnect{
    
    for (CBPeripheral *p in self.bleApi.searchDeviceArrays) {
        if ([[p.identifier UUIDString] isEqualToString:self.deviceID]) {
            NSSLog(@"扫码... 链接设备中......");
            [self.bleApi didConnection:@[p]];
        }
    }
}

#pragma mark - 开锁
- (IBAction)openLockEvent:(UIButton *)sender {
    [self openLock];
}

-(void)openLock{
    if (!self.tokenData) {
        self.contrlLb.text = @"token无效,返回列表重新操作";
        return;
    }
    NSSLog(@"正常开锁...");
    [self writeData:[self getOpenLockData:@"000000"]];
}

#pragma mark 关锁
- (IBAction)closeLockEvent:(UIButton *)sender {
    
    if (!self.tokenData) {
        return;
    }
    [self writeData:[self getCloseLockData]];
}

#pragma mark 修改密码
- (IBAction)changePwdEvent:(UIButton *)sender {
    
    if (!self.self.macStr) {
        return;
    }
    NSLog(@"开始修改密码...");
    NSDictionary *subDic = [[self readPlist]objectForKey:self.macStr];
    
    [self writeData:[self getPasswordOld:@"000000"]];
    
    sleep(1);
    
    NSArray *arr = [[subDic objectForKey:kPassWord] componentsSeparatedByString:@","];
    if (arr.count !=6) {
        self.contrlLb.text = @"新密码错误!!!";
        return;
    }
    NSString *value = [NSString stringWithFormat:@"设置新密码 %@",[subDic objectForKey:kPassWord]];
    [self.debugDic setValue:[self debugToString:value] forKey:debug_newPwd];
    
    [self writeData:[self getPasswordNew:arr]];
}

#pragma mark 修改密钥
- (IBAction)modifyEvent:(UIButton *)sender {
    if (!self.tokenData) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"确定是否修改密钥?" delegate:self cancelButtonTitle:@"下次再说" otherButtonTitles:@"[ 确定 ]", nil];
    alert.tag = 100;
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 100) { // 密钥
        if (buttonIndex == 1) {
            self.ismodify = YES;
            [self writeData:[self getModifyDdata1]];
        }
    }
    if (alertView.tag == 200) { // 扫码上传
        
        if(buttonIndex == 1){
            [self showActivity];
            [self performSelector:@selector(AFIStarRequest) withObject:nil afterDelay:1];
        }
    }
}

#pragma mark 扫描二维码
- (IBAction)searchEvent:(UIButton *)sender {
    
    self.qrcodeTag = sender.tag;
//    NSLog(@"self.qrcodeTag :%ld",self.qrcodeTag);
    
    STQRCodeController *code = [[STQRCodeController alloc]init];
    code.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc]initWithRootViewController:code];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - --- 2.delegate 视图委托 ---
- (void)qrcodeController:(STQRCodeController *)qrcodeController readerScanResult:(NSString *)readerScanResult type:(STQRCodeResultType)resultType{
    
    if(resultType == STQRCodeResultTypeSuccess  && readerScanResult){
        
        
        self.scanResult = readerScanResult;
        
        if (self.qrcodeTag == 100) {
            if (readerScanResult.length == 12) {
                self.contrlLb.text = @"获取设备编号成功";
                self.gpsID = readerScanResult;
                [self setEnabled:self.upLoadBt isEnabled:YES];
                [self performSelector:@selector(searchEvent:) withObject:self.upLoadBt afterDelay:2];
                return;
            }else{
                self.contrlLb.text = @"编号获取失败，请重新扫描获取";
                
                return;
            }
        }
        if (self.qrcodeTag == 200 && self.scanResult) {
            
            NSString *value = [NSString stringWithFormat:@" 扫描二维码 %@",self.scanResult];
            [self.debugDic setValue:[self debugToString:value] forKey:debug_tqRCode];
            
            if (self.scanResult.length ==46){
                
                NSArray *arr = [self.scanResult componentsSeparatedByString:@"?id="];
                NSString *strID = [NSString stringWithFormat:@"是否确定上传?ID=%@",arr[1]];
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:strID
                                                              delegate:self
                                                     cancelButtonTitle:@"报错,下次再说"
                                                     otherButtonTitles:@"[ 确定 ]", nil];
                alert.tag = 200;
                [alert show];
                return;
                
            }else{
                self.contrlLb.text = @"扫码数据格式丢失,请重新扫描!";
                return;
            }
        }
    }
}

-(void)AFIStarRequest{
    
    
    // http://blog.csdn.net/u012960049/article/details/51152014
    //    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.requestSerializer=[AFJSONRequestSerializer serializer];
    [manager.requestSerializer setTimeoutInterval:10]; // 设置超时时间
    
    //    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    
    
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *allDic = [[self readPlist]objectForKey:self.macStr];
    
    NSString *macAddr = [allDic objectForKey:kMAC];//锁mac地址
    NSString *newPwd = [allDic objectForKey:kPassWord];//锁密码
    NSString *newKey = [allDic objectForKey:kTokenKey];//锁key
    NSString *qrCode = self.scanResult;//二维码
    
    
    NSArray *arr = [self.scanResult componentsSeparatedByString:@"?id="];
    NSString *deviceId = arr[1];
    
    
    NSString *jsonStr = [NSString stringWithFormat:@"[{\"macAddr\":\"%@\",\"newPwd\":\"%@\",\"newKey\":\"%@\",\"qrCode\":\"%@\"}]",macAddr,newPwd,newKey,qrCode];
    params[@"jsonStr"] = jsonStr;
    [self.debugDic setValue:[self debugToString:jsonStr] forKey:debug_upLoad];
    
    
    
    //120.76.156.166
    //120.76.236.117 天天骑
    //119.23.72.53   酷游
    NSString *url = @"http://119.23.72.53:16888/Insert";
    NSDictionary *par = @{
                          @"data1":self.gpsID, // GPSID 用于GPS开锁
                          @"data2":macAddr,
                          @"data3":qrCode,
                          @"data4":@"ble2",
                          @"data5":newKey,
                          @"data6":newPwd,
                          @"data7":deviceId // 二维码边上的编号，用于手动输入编号开锁
                          };
    
//    NSLog(@"par :%@",par);
    
    [manager POST:url parameters:par
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     [self removeActivity];
                     
                     // 妈蛋，返回的就是json  不需要转换
                     NSString *statusStr = [responseObject objectForKey:@"result"];
                     
//                     NSLog(@"responseObject :%@",responseObject);
//                     NSLog(@"value :%@",statusStr);
                     
                     if ([statusStr isEqualToString:@"ok"]) {
                         
                         self.contrlLb.text = @"已成功存储服务器";
                         [self setEnabled:self.backBt isEnabled:YES];
                         
                         [self writeMac:self.macStr];
                         
                         [self.debugDic setValue:[self debugToString:@"已成功存储服务器"]
                                          forKey:debug_uploadsuccess];
                         [self recordDebugDic:self.debugDic];
                         
                         
                         [self performSelector:@selector(clearMsg) withObject:nil afterDelay:2];
                     }else{
                         
                         self.contrlLb.text = statusStr;
                         [self setEnabled:self.backBt isEnabled:NO];
                         
                         [self.debugDic setValue:[self debugToString:statusStr]
                                          forKey:debug_uploadErr];
                         [self recordDebugDic:self.debugDic];
                         
                     }
                 } failure:^(NSURLSessionDataTask *task, NSError *error) {
                     
                    NSLog(@"请求超时处理.error :%@",error);
                     
                     self.contrlLb.text = @"数据请求失败,重新操作...";
                     [self removeActivity];
                     [self setEnabled:self.backBt isEnabled:NO];
                     
                     
                     [self.debugDic setValue:[self debugToString:@"数据请求失败,重新操作..."]
                                      forKey:debug_uploadErr];
                     [self recordDebugDic:self.debugDic];
                 }];
}

#pragma mark - 字典数据转换成json格式存入debug纪录
-(void)recordDebugDic:(NSDictionary *)debugDic{
    if (debugDic) {
        NSString *json = [NSObject dictToJsonStr:debugDic];
        [self writeDebug:json];
    }
}

#pragma mark - 发送指令的拼接
/*************************************************************/
#pragma mark - 查询锁的开关状态
-(NSData *)getLockStatu{
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    
    Byte signal[16] = {
        0x05,0x0e,0x01,0x01,tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
    
}
#pragma mark -  修改密钥
-(NSData *)getModifyDdata1{
    
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    
    NSDictionary *subDic = [[self readPlist]objectForKey:self.macStr];
    NSArray *arr = [[subDic objectForKey:kTokenKey]componentsSeparatedByString:@","];
    
    NSMutableData *pwdData = [NSMutableData data];
    for (int i = 0; i < arr.count; i++) {
        int value = [arr[i]intValue];
        NSData *subData = [NSData dataWithBytes:&value length:1];
        [pwdData appendData:subData];
    }
//    NSSLog(@"token1......%@  %@",arr,pwdData);
    
    Byte *keyByte = (Byte *)[pwdData bytes];
    
    Byte signal[16] = {
        0x07,0x01,0x08,
        keyByte[0],keyByte[1],keyByte[2],keyByte[3],
        keyByte[4],keyByte[5],keyByte[6],keyByte[7],
        
        tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],
        0x00};
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}
-(NSData *)getModifyDdata2{
    
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    
    NSDictionary *subDic = [[self readPlist]objectForKey:self.macStr];
    NSArray *arr = [[subDic objectForKey:kTokenKey]componentsSeparatedByString:@","];
    
    NSMutableData *pwdData = [NSMutableData data];
    for (int i = 0; i < arr.count; i++) {
        int value = [arr[i]intValue];
        NSData *subData = [NSData dataWithBytes:&value length:1];
        [pwdData appendData:subData];
    }
//    NSSLog(@"token2******%@  %@",arr,pwdData);
    NSString *value = [NSString stringWithFormat:@"修改密钥  %@",[subDic objectForKey:kTokenKey]];
    [self.debugDic setValue:[self debugToString:value] forKey:debug_token];
    
    Byte *keyByte = (Byte *)[pwdData bytes];
    
    Byte signal[16] = {
        0x07,0x02,0x08,
        
        keyByte[8],keyByte[9],keyByte[10],keyByte[11],
        keyByte[12],keyByte[13],keyByte[14],keyByte[15],
        
        tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],
        0x00};
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}

#pragma mark - 开锁
-(NSData *)getOpenLockData:(NSString *)pwd{
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    
    // 新秘密  转换 int 类型
    NSMutableData *pwdData = [NSMutableData data];
    [pwdData appendData:[pwd dataUsingEncoding:NSUTF8StringEncoding]];

//    if (self.isnetworkOpen) {
//        
//        for (int i = 0; i < pwd.length; i++) {
//            int value = [[pwd substringWithRange:NSMakeRange(i, 1)] intValue];
//            [pwdData appendBytes:&value length:1];
//        }
//    }else{}
    
//    NSSLog(@"开锁...pwd :%@  data :%@",pwd,pwdData);
    NSString *value = [NSString stringWithFormat:@"开锁:%@",pwd];
    NSString *key = [NSString stringWithFormat:@"openLock%ld",self.count];
    [self.debugDic setValue:[self debugToString:value] forKey:key];
    
    Byte *pwdByte = (Byte *)[pwdData bytes];
    Byte signal[16] = {
        0x05,0x01,0x06,pwdByte[0],pwdByte[1],pwdByte[2],pwdByte[3],pwdByte[4],pwdByte[5],
        tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],0x00,0x00,0x00
    };
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal); //AES 128加密
    NSData *encryptData= [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}
#pragma mark - 关锁(复位)
-(NSData *)getCloseLockData{
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    Byte signal[16] = {
        0x05,0x0C,0x01,0x01,
        tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],
        0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
    };
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}
// 同步时间
-(NSData *)getSyncTimeData{
    
    Byte time[4];
    long tim = [NSDate date].timeIntervalSince1970;
    time[0] = (Byte) (((tim) >> 0) & 0xFF);
    time[1] = (Byte) (((tim) >> 8) & 0xFF);
    time[2] = (Byte) (((tim) >> 16) & 0xFF);
    time[3] = (Byte) (((tim) >> 24) & 0xFF);
    
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    Byte signal[16] = {
        0x01,0x01,0x04,
        time[0],time[1],time[2],time[3],
        tokenByte[0],tokenByte[1],tokenByte[2],tokenByte[3],
        0x00,0x00,0x00,0x00,0x00};
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}
// 修改广播名称
-(NSData *)getDeviceNameData:(NSString *)name{
    
    NSData*nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
    if (nameData.length > 8) {
        NSLog(@"----超长");
        return nil;
    }
    
    Byte *nameByte = (Byte *)[nameData bytes];
    Byte *tokenByte = (Byte *)[self.tokenData bytes]; //得到之前的token
    
    //组装命令
    Byte signal[16] = {0x04,0x01};
    signal[2] = nameData.length;
    for (int i = 0; i < nameData.length; i++) {
        signal[i+3] = nameByte[i];
    }
    signal[nameData.length+3] = tokenByte[0];
    signal[nameData.length+4] = tokenByte[1];
    signal[nameData.length+5] = tokenByte[2];
    signal[nameData.length+6] = tokenByte[3];
    for (long i = nameData.length+7; i < 16; i++) {
        signal[i] = 0;//arc4random()%255;
    }
    Byte encryptSignal[16];
    
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}

#pragma mark -  修改密码  旧密码
-(NSData *)getPasswordOld:(NSString *)pwd{
    if (pwd.length != 6) {
        return nil;
    }
    NSSLog(@"设置旧的密码...");
    NSString *value = [NSString stringWithFormat:@"设置旧密码 %@",pwd];
    [self.debugDic setValue:[self debugToString:value] forKey:debug_oldPwd];
    
    NSData*passwordData = [pwd dataUsingEncoding:NSUTF8StringEncoding];
    Byte *passwdByte = (Byte *)[passwordData bytes];
    
    //得到之前的token
    Byte *tokenByte = (Byte *)[self.tokenData bytes];
    
//    NSSLog(@"psd :%@  token :%@",passwordData,self.tokenData);
    
    //组装命令
    Byte signal[] = {0x05,0x03,0x06,
        passwdByte[0],passwdByte[1],passwdByte[2],passwdByte[3],passwdByte[4],passwdByte[5],
        tokenByte[0],tokenByte[1],tokenByte[2], tokenByte[3],
        arc4random()%255,arc4random()%255,arc4random()%255};
    
    Byte encryptSignal[16];
    //AES 128加密
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);
    //转成NSData
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}

#pragma mark -  修改密码  新密码
-(NSData *)getPasswordNew:(NSArray *)pwdArr{
    if (pwdArr.count != 6) {
        return nil;
    }
    
    // 新密码  转换 int 类型
    NSMutableData *data = [NSMutableData data];
    for (int i = 0; i < pwdArr.count; i++) {
        int value = [pwdArr[i]intValue];
        [data appendBytes:&value length:1];
    }
    NSSLog(@"发送新的密码... %@",data);

    
    Byte *passwdByte = (Byte *)[data bytes];
    Byte *tokenByte = (Byte *)[self.tokenData bytes];//得到之前的token
    Byte signal[] = {0x05,0x04,0x06,
        passwdByte[0],passwdByte[1],passwdByte[2],passwdByte[3],passwdByte[4],passwdByte[5],
        
        tokenByte[0],tokenByte[1],tokenByte[2], tokenByte[3],
        arc4random()%255,arc4random()%255,arc4random()%255};
    
    Byte encryptSignal[16];
    AES128_ECB_encrypt(signal, aeskey, encryptSignal);//AES 128加密
    NSData *encryptData = [NSData dataWithBytes:&encryptSignal length:sizeof(encryptSignal)];
    return encryptData;
}

/*************************************************************/
#pragma mark - 设置当前操作，状态等信息
-(void)setText:(NSString *)name UUID:(NSString *)uuID MAC:(NSString *)mac RSSI:(NSString *)rssi Statu:(NSString *)statu{
    
    if (name) {
        self.nameLb.text = [NSString stringWithFormat:@"NAME: %@",name];
    }
    if (mac) {
        self.macLb.text = [NSString stringWithFormat:@"MAC: 0102%@",[mac uppercaseString]];
    }
    if (statu) {
        self.statuLb.text = [NSString stringWithFormat:@"链接状态: %@",statu];
    }
}

#pragma mark - 初始化密码 **** 乱起八糟的公共方法
-(void)saveDeviceInfo{
    
    NSArray *keys = [[self readPlist]allKeys];
    if (![keys containsObject:self.macStr]) {
        NSMutableDictionary *sub = [NSMutableDictionary dictionary];
        [sub setValue:self.macStr forKey:kMAC];
        [sub setValue:self.passWordStr forKey:kPassWord];
        [sub setValue:self.tokenKeyStr forKey:kTokenKey];
        [self writeDic:sub key:self.macStr];
//        NSSLog(@"保存新设备密码等信息...");
    }
//    NSSLog(@"contentDic:%@",[[self readPlist]objectForKey:self.macStr]);
}

-(void)initPassWord{
    
    // 密码
    int psd1 = arc4random()%10;
    int psd2 = arc4random()%10;
    int psd3 = arc4random()%10;
    int psd4 = arc4random()%10;
    int psd5 = arc4random()%10;
    int psd6 = arc4random()%10;
    
    // 密钥
    int key1 = arc4random()%100;
    int key2 = arc4random()%100;
    int key3 = arc4random()%100;
    int key4 = arc4random()%100;
    
    int key5 = arc4random()%100;
    int key6 = arc4random()%100;
    int key7 = arc4random()%100;
    int key8 = arc4random()%100;
    
    int key9 = arc4random()%100;
    int key10 = arc4random()%100;
    int key11 = arc4random()%100;
    int key12 = arc4random()%100;
    
    int key13 = arc4random()%100;
    int key14 = arc4random()%100;
    int key15 = arc4random()%100;
    int key16 = arc4random()%100;
    
    self.passWordStr = [NSString stringWithFormat:@"%d,%d,%d,%d,%d,%d",psd1,psd2,psd3,psd4,psd5,psd6];
    self.tokenKeyStr = [NSString stringWithFormat:@"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d",key1,key2,key3,key4,key5,key6,key7,key8,key9,key10,key11,key12,key13,key14,key15,key16];
    
    
    //[self setEnabled:self.pwdBt1 isEnabled:NO];
    //[self setEnabled:self.pwdBt2 isEnabled:NO];
    //[self setEnabled:self.upLoadBt isEnabled:NO];
    //[self setEnabled:self.backBt isEnabled:NO];
    //[self setEnabled:self.deviceIDBt isEnabled:NO];
}

-(void)setEnabled:(UIButton *)bt isEnabled:(BOOL)enabled{
    bt.userInteractionEnabled = enabled;
    int w = 200;
    if (enabled) {
        [bt setBackgroundColor:[UIColor colorWithR:128 G:0 B:0 Alpha:1.0]];
    }else{
        [bt setBackgroundColor:[UIColor colorWithR:w G:w B:w Alpha:1.0]];
    }
}
-(void)clearMsg{
    [self.bleApi stopScanForPer];
    self.tokenData = nil;
    self.ismodify = NO;
    self.debugDic = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)showActivity{
    [self removeActivity];
    self.activity=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.activity.frame=CGRectMake(0, 0, 40, 40);
    
    CGPoint point=self.view.center;
    point.y=200;
    self.activity.center=point;;
    [self.activity startAnimating];
    self.activity.layer.cornerRadius=4.0;
    self.activity.backgroundColor=[UIColor grayColor];
    [self.view addSubview:self.activity];
}
-(void)removeActivity{
    
    if (self.activity) {
        [self.activity stopAnimating];
        [self.activity setHidden:YES];
        [self.activity removeFromSuperview];
    }
}
-(NSMutableArray *)deviceArrays{
    if (!_deviceArrays) {
        _deviceArrays = [[NSMutableArray alloc]init];
    }
    return _deviceArrays;
}
-(NSMutableDictionary *)debugDic{
    if (!_debugDic) {
        _debugDic = [[NSMutableDictionary alloc]init];
    }
    return _debugDic;
}
-(NSDictionary *)resultDic{
    if (!_resultDic) {
        _resultDic = [[NSDictionary alloc]init];
    }
    return _resultDic;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
