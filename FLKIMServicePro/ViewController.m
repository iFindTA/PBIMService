//
//  ViewController.m
//  FLKIMServicePro
//
//  Created by nanhu on 2016/11/16.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "ViewController.h"
#import "FLKNetService.h"
#import <CommonCrypto/CommonDigest.h>

@interface ViewController () 

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //start network engine
    FLKNetConfiguration *cfg = [FLKNetConfiguration defaultConfiguration];
    [FLKNetworkManager startWithConfiguration:cfg];
    
    [[FLKIMService shared] addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

- (NSString *)sha256:(NSString *)o {
    const char *cstr = [o UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(cstr, (CC_LONG)strlen(cstr), result);
    
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH*2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return [NSString stringWithString:ret];
}

- (IBAction)authorizationEvent:(id)sender {
    FLKPacket *authorConfigs = [self authorConfigs];
    [[FLKIMService shared] startServiceWithAuthorization:authorConfigs];
}

- (FLKPacket *)authorConfigs {
    NSString *user = @"flk1006";
    NSString *pwd = @"123456";
    pwd = [self sha256:pwd];
    NSMutableDictionary *auth = [NSMutableDictionary dictionary];
    auth[@"command"] = @"auth";
    auth[@"from"] = user;
    auth[@"to"] = user;
    auth[@"password"] = pwd;
    auth[@"mechanism"] = @"sha256";
    
    NSString *apns = @"<c2bf24cf 960b4499 22beba51 ff5a9ad4 46033255 830100eb 8835cb49 76211578>";
    NSString *voip = @"<e5a531a1 26ae2819 a2fe3f28 da007933 49e3a36b a0b0d7c6 5c2c07fa 465321a0>";
    NSMutableDictionary *clientInfo = [NSMutableDictionary dictionary];
    clientInfo[@"apns_id"] = apns;
    
    clientInfo[@"pushkit_id"] = voip;
    
    clientInfo[@"client_version"] = @"4.2.1";
    
    UIDevice *device = [UIDevice currentDevice];
    NSString *sys = [device systemVersion];
    clientInfo[@"os_version"] = sys;
    
    clientInfo[@"os_type"] = @"iOS";
    
    sys = [device model];
    clientInfo[@"model"] = sys;
    
    sys = [device name];
    clientInfo[@"user_agent"] = sys;
    
    auth[@"client_info"] = clientInfo;
    
    FLKPacket *packet = [FLKPacket packetWithMap:auth];
    return packet;
}
- (IBAction)sendMessage:(id)sender {
    
    NSDictionary *msg = @{@"command":@"message",
        @"id":@"a213h2kj1p9kldss821pa",
        @"type":@"chat",
        @"from":@"13023622337",
        @"to":@"13656680031",
        @"content-type":@"text",
        @"body":@"hello!",
        @"timestamp":@"2016-11-20 8:23:23"};
    FLKPacket *packet = [FLKPacket packetWithMap:msg];
    [[FLKIMService shared] sendPacket:packet];
    
}

- (void)didReceivedPacket:(FLKPacket *)pack withCmd:(NSString *)cmd withError:(NSError *)error {
    NSLog(@"did received msg:%@",pack.payloadMap);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
