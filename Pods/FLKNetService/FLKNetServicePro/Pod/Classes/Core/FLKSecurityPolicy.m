//
//  FLKSecurityPolicy.m
//  FLKNetServicePro
//
//  Created by nanhujiaju on 2016/12/23.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKSecurityPolicy.h"

@implementation FLKSecurityPolicy

- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain {
    return [super evaluateServerTrust:serverTrust forDomain:domain];
}

@end
