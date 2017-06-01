//
//  ListViewController.m
//  protective_X7
//
//  Created by wu.xiong on 16/12/19.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import "ListViewController.h"
#import "HomeViewController.h"

#import "ReadDbugViewController.h"

#define showCount 5

@interface ListViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *myTable;
@property (strong, nonatomic)NSMutableArray *arr;
@end

@implementation ListViewController

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self bleAPIInit];
//    NSSLog(@"macstring :%@",self.bleApi.macString);
}

- (void)viewDidLoad {
    
//    NSString *json = [NSObject dictToJsonStr:[self readPlist]];
//    NSSLog(@"dic :%@",[self readPlist]);
//    NSSLog(@"json :%@",json);
    
    [super viewDidLoad];
    self.title = @"设备扫描中...";
    [self initTableView];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(refList)
                                                name:@"refList" object:nil];
    
    UIButton *right=[UIButton buttonWithType:UIButtonTypeCustom];
    right.frame=CGRectMake(0, 0, 60, 30);
    [right addTarget:self action:@selector(refList)
    forControlEvents:UIControlEventTouchUpInside];
    [right setTitle:@"刷新" forState:0];
    right.backgroundColor = [UIColor grayColor];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:right];
    
    
    UIButton *left=[UIButton buttonWithType:UIButtonTypeCustom];
    left.frame=CGRectMake(0, 0, 60, 30);
    [left setTitle:@"debug" forState:0];
    left.backgroundColor = [UIColor grayColor];
    [left addTarget:self action:@selector(leftItemEvent:)
    forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:left];
    
    
    
    // 当前app的版本信息
    UILabel *version = [[UILabel alloc]initWithFrame:CGRectMake(0, ScreenHeight-30, ScreenWidth, 20)];
    version.textAlignment = NSTextAlignmentCenter;
    version.textColor = [UIColor blackColor];

    NSString *str = [NSString stringWithFormat:@"%@ :v%@",[self getAppName],[self getAppVersion]];
    version.text = str;
    [self.view addSubview:version];
}

-(NSString *)getAppName{
    return [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleName"];
}

-(NSString *)getAppVersion{
    return [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleVersion"];
}


-(void)leftItemEvent:(UIButton *)sender{
    [self.navigationController pushViewController:[ReadDbugViewController new] animated:YES];
}

-(void)refList{
    
    [self.bleApi didDisconnection:self.bleApi.connectArrays];
    [self.bleApi.searchDeviceArrays removeAllObjects];
    [self.bleApi.connectArrays removeAllObjects];
    [self.bleApi.RSSIDictionary removeAllObjects];
    [self.bleApi.MACDictionary removeAllObjects];
    [self.bleApi.foundMacArrays removeAllObjects];
    
    self.bleApi.macString = nil;
    
    [self.arr removeAllObjects];
    [self.myTable reloadData];
    self.title = @"设备扫描中...";
    [self.bleApi performSelector:@selector(scanForPer) withObject:nil afterDelay:1];
}

-(void)foundDevice:(CBPeripheral *)p{
    
    for (NSString *rssiKey in [self.bleApi.RSSIDictionary allKeys]) {
//        NSSLog(@"key :%@",rssiKey);
        
        NSDictionary *subDic = [NSDictionary dictionaryWithObject:[self.bleApi.RSSIDictionary objectForKey:rssiKey] forKey:rssiKey];
        
        if (![self.arr containsObject:subDic]) {
            [self.arr addObject:subDic];
            
            // 按照rssi的强弱进行排序
            NSInteger i = 0,j = 0;
            for(i = 0; i < self.arr.count; i++){
                
                for(j = 0; j < self.arr.count -i - 1; j++){
                    
                    NSDictionary *dic1 = self.arr[j];
                    NSDictionary *dic2 = self.arr[j+1];
                    
                    NSNumber *nb1 = [dic1 allValues][0];
                    NSNumber *nb2 = [dic2 allValues][0];

                    NSInteger rssi1 = [nb1 integerValue];
                    NSInteger rssi2 = [nb2 integerValue];
                    
                    if (rssi1 < rssi2) {
                        [self.arr exchangeObjectAtIndex:j withObjectAtIndex:j+1];
                    }
                }
            }
        }
    }
    [self.myTable reloadData];
}
-(void)connectDevice:(CBPeripheral *)p{
}

-(void)disConnectDevice:(CBPeripheral *)p{
}
-(void)stopScan{
    self.title = @"扫描结束";
//    NSSLog(@"arr.count :%@",self.bleApi.MACDictionary);
}

#pragma mark - tableview delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    NSInteger count = 1;
    if (self.arr.count) {
        count = (self.arr.count <= showCount ? self.arr.count : showCount);
    }
    return  count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 45;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.arr.count) {
        HomeViewController *home = [HomeViewController new];
        NSDictionary *dic = self.arr[indexPath.row];
        NSString *key = [dic allKeys][0];
        home.deviceID = key;
        [self.navigationController pushViewController:home animated:YES];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *DeviceListcell = @"cellID";
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:DeviceListcell];
    if (cell==nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle
                                     reuseIdentifier:DeviceListcell];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont systemFontOfSize:11];
        cell.textLabel.textColor = [UIColor blackColor];
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }
    
    if (self.arr.count > 0) {
        NSDictionary *dic = self.arr[indexPath.row];
        
        NSString *key = [dic allKeys][0];
        NSString *rssi = [dic allValues][0];
        NSData *data = [self.bleApi.MACDictionary objectForKey:key];
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
        
        cell.textLabel.text = [NSString stringWithFormat:@"UUID:%@",key];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI:%@  MAC:%@",rssi,content];
        
//        if ([[[self readPlist]allKeys] containsObject:content]) {
//            cell.textLabel.textColor = [UIColor redColor];
//        }
        
        
    }else{
        cell.textLabel.text = @"没有发现设备,确定蓝牙是否打开并将设备放在手机附近";
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

-(void)initTableView{
    
    self.myTable.delegate = self;
    self.myTable.dataSource = self;
    self.myTable.tableFooterView = [UIView new];
    //    self.myTable.separatorStyle = 0;
    self.myTable.backgroundColor = [UIColor whiteColor];
}

-(NSMutableArray *)arr{
    if (!_arr) {
        _arr = [[NSMutableArray alloc]init];
    }
    return _arr;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
