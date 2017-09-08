//
//  FLKNetService.m
//  FLKNetServicePro
//
//  Created by nanhu on 2016/11/11.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKNetService.h"

#define FLK_REQUEST_TIMEOUT                             30.f

#pragma mark -- common api service
static FLKComAPI * CommonApiInstance = nil;
static dispatch_once_t com_onceToken ;
@implementation FLKComAPI

+ (void)setupService:(NSDictionary *)info {
    
    if (info) {
        //check for domain
        NSString *domain;
#if DEBUG
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_DEBUG];
#else
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_RELEASE];
#endif
        NSAssert(domain.length > 0, @"domain for net service can't be nil!");
        //static dispatch_once_t onceToken;
        dispatch_once(&com_onceToken, ^{
            if (CommonApiInstance == nil) {
                NSURL *baseURL = [NSURL URLWithString:domain];
                CommonApiInstance = [[[self class] alloc] initWithBaseURL:baseURL];
            }
        });
        
        //check for timeout interval
        CGFloat timeout = [[info objectForKey:FLK_NETSERVICE_REQUEST_TIME_OUT] floatValue];
        if (timeout < 15 || timeout > 60) {
            timeout = FLK_REQUEST_TIMEOUT;
        }
        CommonApiInstance.requestSerializer.timeoutInterval = timeout;
    }
}

+ (FLKComAPI *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&com_onceToken, ^{
        CommonApiInstance = [[[self class] alloc] init];
    });
    //ensure base-url was exist!
    if (CommonApiInstance.baseURL.absoluteString.length == 0) {
        [FLKComAPI released];
        NSDictionary *cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_COMMON_API_KEY];
        [FLKComAPI setupService:cfgs];
        return nil;
    }
    
    return CommonApiInstance;
}

+ (void)released {
    com_onceToken = 0;CommonApiInstance = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

#pragma mark -- contact api service
static FLKPimAPI * PimApiInstance = nil;
static dispatch_once_t pim_onceToken ;
@implementation FLKPimAPI

+ (void)setupService:(NSDictionary *)info {
    
    if (info) {
        //check for domain
        NSString *domain;
#if DEBUG
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_DEBUG];
#else
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_RELEASE];
#endif
        NSAssert(domain.length > 0, @"domain for net service can't be nil!");
        //static dispatch_once_t onceToken;
        dispatch_once(&pim_onceToken, ^{
            if (PimApiInstance == nil) {
                NSURL *baseURL = [NSURL URLWithString:domain];
                PimApiInstance = [[[self class] alloc] initWithBaseURL:baseURL];
            }
        });
        
        //check for timeout interval
        CGFloat timeout = [[info objectForKey:FLK_NETSERVICE_REQUEST_TIME_OUT] floatValue];
        if (timeout < 15 || timeout > 60) {
            timeout = FLK_REQUEST_TIMEOUT;
        }
        PimApiInstance.requestSerializer.timeoutInterval = timeout;
    }
}

+ (FLKPimAPI *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&pim_onceToken, ^{
        PimApiInstance = [[[self class] alloc] init];
    });
    //ensure base-url was exist!
    if (PimApiInstance.baseURL.absoluteString.length == 0) {
        [FLKPimAPI released];
        NSDictionary *cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_PIM_API_KEY];
        [FLKPimAPI setupService:cfgs];
        return nil;
    }
    
    return PimApiInstance;
}

+ (void)released {
    pim_onceToken = 0;PimApiInstance = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

#pragma mark -- cloud api service
static FLKCloudAPI * CloudApiInstance = nil;
static dispatch_once_t cloud_onceToken ;
@implementation FLKCloudAPI

+ (void)setupService:(NSDictionary *)info {
    
    if (info) {
        //check for domain
        NSString *domain;
#if DEBUG
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_DEBUG];
#else
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_RELEASE];
#endif
        NSAssert(domain.length > 0, @"domain for net service can't be nil!");
        //static dispatch_once_t onceToken;
        dispatch_once(&cloud_onceToken, ^{
            if (CloudApiInstance == nil) {
                NSURL *baseURL = [NSURL URLWithString:domain];
                CloudApiInstance = [[[self class] alloc] initWithBaseURL:baseURL];
            }
        });
        
        //check for timeout interval
        CGFloat timeout = [[info objectForKey:FLK_NETSERVICE_REQUEST_TIME_OUT] floatValue];
        if (timeout < 15 || timeout > 60) {
            timeout = FLK_REQUEST_TIMEOUT;
        }
        CloudApiInstance.requestSerializer.timeoutInterval = timeout;
    }
}

+ (FLKCloudAPI *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&cloud_onceToken, ^{
        CloudApiInstance = [[[self class] alloc] init];
    });
    //ensure base-url was exist!
    if (CloudApiInstance.baseURL.absoluteString.length == 0) {
        [FLKCloudAPI released];
        NSDictionary *cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_CLOUD_API_KEY];
        [FLKCloudAPI setupService:cfgs];
        return nil;
    }
    
    return CloudApiInstance;
}

+ (void)released {
    cloud_onceToken = 0;CloudApiInstance = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

#pragma mark -- media api service
static FLKMediaAPI * MediaApiInstance = nil;
static dispatch_once_t media_onceToken ;
@implementation FLKMediaAPI

+ (void)setupService:(NSDictionary *)info {
    
    if (info) {
        //check for domain
        NSString *domain;
#if DEBUG
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_DEBUG];
#else
        domain = [info objectForKey:FLK_NETSERVICE_DOMAIN_RELEASE];
#endif
        NSAssert(domain.length > 0, @"domain for net service can't be nil!");
        //static dispatch_once_t onceToken;
        dispatch_once(&media_onceToken, ^{
            if (MediaApiInstance == nil) {
                NSURL *baseURL = [NSURL URLWithString:domain];
                MediaApiInstance = [[[self class] alloc] initWithBaseURL:baseURL];
            }
        });
        
        //check for timeout interval
        CGFloat timeout = [[info objectForKey:FLK_NETSERVICE_REQUEST_TIME_OUT] floatValue];
        if (timeout < 15 || timeout > 60) {
            timeout = FLK_REQUEST_TIMEOUT;
        }
        MediaApiInstance.requestSerializer.timeoutInterval = timeout;
    }
}

+ (FLKMediaAPI *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&media_onceToken, ^{
        MediaApiInstance = [[[self class] alloc] init];
    });
    //ensure base-url was exist!
    if (MediaApiInstance.baseURL.absoluteString.length == 0) {
        [FLKMediaAPI released];
        NSDictionary *cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_MEDIA_API_KEY];
        [FLKMediaAPI setupService:cfgs];
        return nil;
    }
    
    return MediaApiInstance;
}

+ (void)released {
    media_onceToken = 0;MediaApiInstance = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

#pragma mark == Network Manager ==

@interface FLKNetworkManager ()<FLKNetworkCoreDelegate>

@end

static FLKNetworkManager *instance = nil;
static dispatch_once_t onceToken;

@implementation FLKNetworkManager

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (FLKNetworkManager *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FLKNetworkManager alloc] init];
    });
    return instance;
}

+ (void)released {
    onceToken = 0;instance = nil;
}

+ (void)startWithConfiguration:(FLKNetConfiguration *)cfg {
    [[FLKNetworkManager shared] startLoadBalancesWithConfigure:cfg];
}

- (void)startLoadBalancesWithConfigure:(FLKNetConfiguration *)cfg {
    //clear caches
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    //setup network core logic
    [FLKNetCore setupWithConfiguration:cfg];
    
    //setup delegate for network core logic
    dispatch_queue_t queue = dispatch_queue_create("com.flk.app-launch.queue", NULL);
    [[FLKNetCore shared] addDelegate:self delegateQueue:queue];
    
    //start load balance
    [[FLKNetCore shared] loadNetworkBalance];
}

#pragma mark -- network callback delegate

- (void)networkStateDidChangeTo:(FLKNetState)aState withPrevious:(FLKNetState)preState {
    
}

- (void)didLoadBalanceWithError:(NSError *)error {
    
    NSLog(@"%s____error:%@",__FUNCTION__, error.localizedDescription);
    if (error != nil) {
        //failed on load balance info while error not nil!
        return;
    }
    
    //初始化Common API
    NSDictionary *cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_COMMON_API_KEY];
    if (cfgs != nil) {
        [FLKComAPI setupService:cfgs];
    } else {
        NSLog(@"failed to init common api service!");
    }
    
    //初始化通讯录
    cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_PIM_API_KEY];
    if (cfgs != nil) {
        [FLKPimAPI setupService:cfgs];
    } else {
        NSLog(@"failed to init pim api service!");
    }
    
    //初始化网盘
    cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_CLOUD_API_KEY];
    if (cfgs != nil) {
        [FLKCloudAPI setupService:cfgs];
    } else {
        NSLog(@"failed to init cloud api service!");
    }
    
    //初始化多媒体
    cfgs = [[FLKNetCore shared] assembleConfigures4ServerKey:FLK_SERVER_4_MEDIA_API_KEY];
    if (cfgs != nil) {
        [FLKMediaAPI setupService:cfgs];
    } else {
        NSLog(@"failed to init media api service!");
    }
    //释放资源
    NSDictionary *balance = [NSDictionary dictionaryWithDictionary:[FLKNetCore shared].balanceMap];
    if (balance) {
        //负载均衡加载后释放无关的类
        [FLKNetworkManager released];
        
        //[FLKNetCore released];//balance needed somewhere
    }
}

+ (BOOL)updateAuthoziedToken:(NSString *)token forKey:(NSString *)key {
    if ([FLKNetCore shared].balanceMap == nil) {
        return false;
    }
    if (token.length == 0 || key.length == 0) {
        return false;
    }
    [[FLKNetCore shared] setAuthorization:token forKey:key];
    [[FLKComAPI shared] setAuthorization:token forKey:key];
    [[FLKPimAPI shared] setAuthorization:token forKey:key];
    [[FLKCloudAPI shared] setAuthorization:token forKey:key];
    [[FLKMediaAPI shared] setAuthorization:token forKey:key];
    
    return true;
}

@end
