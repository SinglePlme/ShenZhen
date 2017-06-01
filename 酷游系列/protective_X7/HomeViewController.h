//
//  HomeViewController.h
//  protective_X7
//
//  Created by wu.xiong on 16/12/17.
//  Copyright © 2016年 wu.xiong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

#define debug_MAC @"MAC"

#define debug_Pow @"Power"
#define debug_PowErr @"powerErr"

#define debug_open1 @"openLock1"
#define debug_open2 @"openLock2"
#define debug_open3 @"openLock3"

#define debug_openOK @"opensuccess"
#define debug_openErr @"openErr"

#define debug_closeOK @"closesuccess"
#define debug_closeErr @"closeErr"
#define debug_closeTimeOut @"cloeTimeOut"


#define debug_oldPwd @"oldPwd"
#define debug_newPwd @"newPWd"

#define debug_pwdOK @"pwdOK"
#define debug_pwdErr @"pwdErr"

#define debug_getToken @"getToken"
#define debug_token @"Token"
#define debug_tokenOK @"Tokensuccess"
#define debug_tokenErr @"TokenErr"

#define debug_tqRCode @"tqRcode"

#define debug_upLoad @"jsonStr"
#define debug_uploadsuccess @"upLoadsuccess"
#define debug_uploadErr @"upLoadErr"


#define debug_connect @"conectDevice"
#define debug_disconnect @"disconnectDevice"




@interface HomeViewController : BaseViewController

@property(strong,nonatomic)NSString *deviceID;
@property(strong,nonatomic)UIActivityIndicatorView *activity;

@property(assign,nonatomic)NSInteger qrcodeTag;

@property(strong,nonatomic)NSString *gpsID;
@end
