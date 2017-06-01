//
//  ReadDbugViewController.m
//  protective_X7
//
//  Created by wu.xiong on 16/12/28.
//  Copyright © 2016年 wu.xiong. All rights reserved.

#import "ReadDbugViewController.h"

@interface ReadDbugViewController ()<UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *mytextview;
@end

@implementation ReadDbugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"debug 纪录";
    self.mytextview.editable = NO;
    self.mytextview.text = [self readDebug];
    
    UIButton *right=[UIButton buttonWithType:UIButtonTypeCustom];
    right.frame=CGRectMake(0, 0, 100, 30);
    [right addTarget:self action:@selector(rightItemEvent:)
    forControlEvents:UIControlEventTouchUpInside];
    [right setTitle:@"清空debug" forState:0];
    right.backgroundColor = [UIColor grayColor];
    self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc]initWithCustomView:right];
}

-(void)rightItemEvent:(UIButton *)sender{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"**是否确定操作?**"
                                                   message:@"debug纪录及测试存储数据将会被删除，不可修复"
                                                  delegate:self
                                         cancelButtonTitle:@"下次再说"
                                         otherButtonTitles:@"[ 删除 ]", nil];
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
//        NSSLog(@"确定删除");
        
        NSMutableDictionary *allDic = [NSMutableDictionary dictionary];
        NSMutableDictionary *subDic = [NSMutableDictionary dictionary];
        
        [subDic setValue:@"000000000000" forKey:kMAC];
        [subDic setValue:@"000000" forKey:kPassWord];
        [subDic setValue:@"00000000000000000000000000000000" forKey:kTokenKey];
        [allDic setObject:subDic forKey:@"000000"];
        [allDic writeToFile:devicePlist atomically:YES];
        
        NSString *str = @"*************************\n\n";
        [str writeToFile:debugFile atomically:YES encoding:NSUTF8StringEncoding error:nil];
        self.mytextview.text = [self readDebug];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
@end
