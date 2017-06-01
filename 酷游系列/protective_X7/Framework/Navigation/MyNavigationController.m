//
//  MyNavigationController.m
//  LamField
//
//  Created by HAOZO.MAC on 16/3/28.
//  Copyright © 2016年 HAOZO.MAC. All rights reserved.
//

#import "MyNavigationController.h"

@implementation MyNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController{
    self=[super initWithRootViewController:rootViewController];
    if (self) {
        
        UIImage *navi_Image=[UIImage imageNamed:@"naviclear.png"];
        [self.navigationBar setTintColor:[UIColor whiteColor]];
//        [self.navigationBar setBackgroundImage:navi_Image forBarMetrics:UIBarMetricsDefault];
        [self.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
        
        //去除导航栏下方的横线
        [self.navigationBar setBackgroundImage:navi_Image forBarPosition:UIBarPositionAny
                                    barMetrics:UIBarMetricsDefault];
        
        [self.navigationBar setShadowImage:[UIImage new]];
    }
    return self;
}
@end
