//
//  BleAPI.m
//  keyPad
//
//  Created by HAOZO.MAC on 15/10/16.
//  Copyright © 2015年 HAOZO.MAC. All rights reserved.
//

#import "BleAPI.h"
#import "PublicSet.h"

#define delay 3
static BleAPI *api =nil;

@implementation BleAPI

#pragma mark - 蓝牙设备的返回处理操作
-(void)bleAPIBlocks:(bleAPIdiscoverBlock)_discover
   withconnectBlock:(bleAPIconnectBlock)_connect
withdisconnectBlock:(bleAPIdisconnectBlock)_disconnect
withnotificationBlock:(bleAPInotificationBlock)_notification
  withstopScanBlock:(bleAPStopScanBlock)_stopScan{
    
    self.discoverBlock=_discover;
    self.connectBlock=_connect;
    self.disconnectBlock=_disconnect;
    self.notificationBlock = _notification;
    self.stopScanBlock = _stopScan;
}

#pragma mark - 扫描操作 -- 开始扫瞄
-(void)scanForPer{
    
    if (!TARGET_IPHONE_SIMULATOR) {
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                            forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [self.centralManager scanForPeripheralsWithServices:@[Servicesuuids] options:options];
        
//        NSLog(@"...... 开始扫描设备......");
        [self performSelector:@selector(stopScanForPer) withObject:nil afterDelay:delay];
    }
}
-(void)scanForPerAndStop:(int)delayTime{
    
    if (!TARGET_IPHONE_SIMULATOR) {
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                            forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [self.centralManager scanForPeripheralsWithServices:@[Servicesuuids] options:options];
        
//        NSLog(@"...... 开始扫描设备......");
//        [self performSelector:@selector(stopScanForPer) withObject:nil afterDelay:delayTime];
    }
}

//停止扫瞄
-(void)stopScanForPer{
//    NSLog(@"******扫描设备结束");
    [self.centralManager stopScan];
    self.stopScanBlock();
}

#pragma mark - 连接，断开操作  连接
-(void)didConnection:(NSArray *)devices{
    for (CBPeripheral *p in devices) {
        [self.centralManager connectPeripheral:p options:nil];
    }
}

//断开连接
-(void)didDisconnection:(NSArray *)devices{
    if (!devices.count) {
        return;
    }
    for (CBPeripheral *p in devices) {
        [self.centralManager cancelPeripheralConnection:p];
    }
}

#pragma mark - 数据写入操作
-(void)writeData:(NSData *)data forcharauuid:(NSString *)charauuid{
    if (!self.connectArrays.count) {
        return;
    }
    else{
        
        for (CBPeripheral *p in self.connectArrays) {
            
            for (CBService *service in p.services) {
                
                for ( CBCharacteristic *characteristic in service.characteristics ) {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:charauuid]]) {
                        
                        [p writeValue:data forCharacteristic:characteristic
                                 type:CBCharacteristicWriteWithResponse];
//                        NSLog(@"write.value :%@",data);
                    }
                }
            }
        }
    }
}

#pragma mark - ====== *********** centralManager methods and delegate ************ ==============
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    if (central.state ==CBCentralManagerStatePoweredOn) {
        [self scanForPer];
    }
    
    if (central.state == CBCentralManagerStatePoweredOff) { // 系统蓝牙关闭处理异常

        if (self.searchDeviceArrays.count) {
            for (CBPeripheral *p in self.searchDeviceArrays) {
                self.disconnectBlock(p);
            }
        }
    }
}

//发现外围设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    // 166C867D-4FD6-469C-AEF4-E99F4384AF63
    
    NSData *data = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
    NSString *strData = [NSObject dataToHexString:data];
    
    
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
    
    BOOL bl = [strData hasPrefix:@"0102"] && (![self.macString containsString:content]);
    if (bl && (([RSSI integerValue] > -65) && ([RSSI integerValue] < 0))){
        
//        NSSLog(@"data :%@",data);
//        NSSLog(@"str :%@",strData);
//        NSSLog(@"mac :%@",mac);
        
        if (![self.searchDeviceArrays containsObject:peripheral] && self.searchDeviceArrays.count<50) {
            
            [self.searchDeviceArrays addObject:peripheral];
            [self.RSSIDictionary setValue:[RSSI stringValue]
                                   forKey:[peripheral.identifier UUIDString]];
            [self.MACDictionary setValue:data forKey:[peripheral.identifier UUIDString]];
            self.discoverBlock(peripheral);
            
            if (([RSSI integerValue] > -47)) {
                [self stopScanForPer];
            }
        }else{
//            [self stopScanForPer];
        }
    }
}
//连接外围设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    [self insertORdeleteDevice:peripheral isInsert:YES];
    
    self.connectBlock(peripheral);
    peripheral.delegate=self;//这个方法调用发现服务协议
    [peripheral discoverServices:nil];
}

//取消连接
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self insertORdeleteDevice:peripheral isInsert:NO];
    self.disconnectBlock(peripheral);
}

//连接中断
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    [self insertORdeleteDevice:peripheral isInsert:NO];
    self.disconnectBlock(peripheral);
}

-(void)insertORdeleteDevice:(CBPeripheral *)p isInsert:(BOOL)insert{
    if (insert) { // 新怎连接设备
        if (![self.connectArrays containsObject:p]) {
            [self.connectArrays addObject:p];
        }
    }
    if (!insert) {
        if ([self.connectArrays containsObject:p]) {
            [self.connectArrays removeObject:p];
        }
    }
}
#pragma mark - ====== peripheral methods and delegate ======发现服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    for (CBService *service in [peripheral services]){
        [peripheral discoverCharacteristics:charauuids forService:service];
//        NSLog(@"service.uuid :%@",service.UUID);
    }
}

//发现特性
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    
    for (CBCharacteristic *character in [service characteristics]){
//        NSLog(@"chara.uuid:%@",character.UUID);
        
        if ([character.UUID isEqual:[CBUUID UUIDWithString:kReaduuid]]) {
            [peripheral setNotifyValue:YES forCharacteristic:character];
        }
    }
}

//读取指定特性的数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    self.notificationBlock(characteristic.value);
}

#pragma mark - 实例化中央服务
+(BleAPI *)Singleton{
    
    @synchronized(api){
        if (!api) {api=[[BleAPI alloc]initWithcentralManager];}
        return api;
    }
}

- (id)initWithcentralManager{
    
    self = [super init];
    if (self){
        if (!self.centralManager){
            
            self.centralManager=[[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
            //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            
//            NSTimer *timer= [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(scanForPer) userInfo:nil repeats:YES];
//            [[NSRunLoop currentRunLoop]addTimer:timer forMode:NSRunLoopCommonModes];
        }
    }
    return self;
}

-(NSMutableArray *)connectArrays{
    if (!_connectArrays) {
        _connectArrays = [[NSMutableArray alloc]init];
    }
    return _connectArrays;
}

-(NSMutableArray *)searchDeviceArrays{
    if (!_searchDeviceArrays) {
        _searchDeviceArrays = [[NSMutableArray alloc]init];
    }
    return _searchDeviceArrays;
}

-(NSMutableDictionary *)RSSIDictionary{
    if (!_RSSIDictionary) {
        _RSSIDictionary = [[NSMutableDictionary alloc]init];
    }
    return _RSSIDictionary;
}
-(NSMutableDictionary *)MACDictionary{
    if (!_MACDictionary) {
        _MACDictionary = [[NSMutableDictionary alloc]init];
    }
    return _MACDictionary;
}
-(NSMutableArray *)foundMacArrays{
    if (!_foundMacArrays) {
        _foundMacArrays = [[NSMutableArray alloc]init];
    }
    return _foundMacArrays;
}
-(NSMutableString *)macString{
    if (!_macString) {
        _macString = [[NSMutableString alloc]initWithString:[self readMacFile]];
    }
    return _macString;
}
@end
