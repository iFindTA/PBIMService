//
//  FLKNetCore.m
//  FLKNetCorePro
//
//  Created by nanhu on 2016/11/28.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKNetCore.h"
#import "FLKSecurityPolicy.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonCryptoError.h>

NSString * const FLK_NETSERVICE_DOMAIN_DEBUG            =   @"FLK_NETSERVICE_DOMAIN_DEBUG";

NSString * const FLK_NETSERVICE_DOMAIN_RELEASE          =   @"FLK_NETSERVICE_DOMAIN_RELEASE";

NSString * const FLK_NETSERVICE_DOMAIN_PING             =   @"FLK_NETSERVICE_DOMAIN_PING";

NSString * const FLK_NETSERVICE_REQUEST_TIME_OUT        =   @"FLK_NETSERVICE_REQUEST_TIME_OUT";

NSString * const FLK_NETSERVICE_SECURITY_CERT           =   @"FLK_NETSERVICE_SECURITY_CERT";

//server key
NSString * const FLK_SERVER_4_COMMON_API_KEY            =   @"serviceServers";
NSString * const FLK_SERVER_4_PIM_API_KEY               =   @"pimServers";
NSString * const FLK_SERVER_4_CLOUD_API_KEY             =   @"cloudServers";
NSString * const FLK_SERVER_4_MEDIA_API_KEY             =   @"multimediaServers";

/*
 Network constraint vars.
 */
static NSString * const FLK_DEBUG_DOMAIN                    =   @"http://112.74.77.9";
static NSString * const FLK_RELEASE_DOMAIN                  =   @"http://demo.flkjiami.com";
static NSString * const FLK_PING_DOMAIN                     =   @"www.baidu.com";
static NSString * const FLK_BALANCE_UID                     =   @"18657123805";
static NSString * const FLK_BALANCE_PLATFORM                =   @"iOS";
static CGFloat const FLK_TIMEOUT_INTERVAL                   =   30;//sec

#pragma mark == NSData Category ==
NSString * const kCommonCryptoErrorDomain = @"CommonCryptoErrorDomain";
@interface NSError (FLKNetCore)

+ (NSError *) flk_errorWithCCCryptorStatus: (CCCryptorStatus) status;

@end

@implementation NSError (FLKNetCore)

+ (NSError *) flk_errorWithCCCryptorStatus: (CCCryptorStatus) status {
    NSString * description = nil, * reason = nil;
    
    switch ( status )
    {
        case kCCSuccess:
            description = NSLocalizedString(@"Success", @"Error description");
            break;
            
        case kCCParamError:
            description = NSLocalizedString(@"Parameter Error", @"Error description");
            reason = NSLocalizedString(@"Illegal parameter supplied to encryption/decryption algorithm", @"Error reason");
            break;
            
        case kCCBufferTooSmall:
            description = NSLocalizedString(@"Buffer Too Small", @"Error description");
            reason = NSLocalizedString(@"Insufficient buffer provided for specified operation", @"Error reason");
            break;
            
        case kCCMemoryFailure:
            description = NSLocalizedString(@"Memory Failure", @"Error description");
            reason = NSLocalizedString(@"Failed to allocate memory", @"Error reason");
            break;
            
        case kCCAlignmentError:
            description = NSLocalizedString(@"Alignment Error", @"Error description");
            reason = NSLocalizedString(@"Input size to encryption algorithm was not aligned correctly", @"Error reason");
            break;
            
        case kCCDecodeError:
            description = NSLocalizedString(@"Decode Error", @"Error description");
            reason = NSLocalizedString(@"Input data did not decode or decrypt correctly", @"Error reason");
            break;
            
        case kCCUnimplemented:
            description = NSLocalizedString(@"Unimplemented Function", @"Error description");
            reason = NSLocalizedString(@"Function not implemented for the current algorithm", @"Error reason");
            break;
            
        default:
            description = NSLocalizedString(@"Unknown Error", @"Error description");
            break;
    }
    
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject: description forKey: NSLocalizedDescriptionKey];
    
    if ( reason != nil )
        [userInfo setObject: reason forKey: NSLocalizedFailureReasonErrorKey];
    
    NSError * result = [NSError errorWithDomain: kCommonCryptoErrorDomain code: status userInfo: userInfo];
    //[userInfo release];
    
    return ( result );
}

@end

@interface NSData (FLKNetCore)

@end

@implementation NSData (FLKNetCore)

static void flk_fixKeyLengths( CCAlgorithm algorithm, NSMutableData * keyData, NSMutableData * ivData )
{
    NSUInteger keyLength = [keyData length];
    switch ( algorithm )
    {
        case kCCAlgorithmAES128:
        {
            if ( keyLength <= 16 )
            {
                [keyData setLength: 16];
            }
            else if ( keyLength <= 24 )
            {
                [keyData setLength: 24];
            }
            else
            {
                [keyData setLength: 32];
            }
            
            break;
        }
            
        case kCCAlgorithmDES:
        {
            [keyData setLength: 8];
            break;
        }
            
        case kCCAlgorithm3DES:
        {
            [keyData setLength: 24];
            break;
        }
            
        case kCCAlgorithmCAST:
        {
            if ( keyLength <= 5 )
            {
                [keyData setLength: 5];
            }
            else if ( keyLength > 16 )
            {
                [keyData setLength: 16];
            }
            
            break;
        }
            
        case kCCAlgorithmRC4:
        {
            if ( keyLength > 512 )
                [keyData setLength: 512];
            break;
        }
            
        default:
            break;
    }
    
    [ivData setLength: [keyData length]];
}

- (NSData *) flk_encryptedAES256DataUsingKey: (id) key error: (NSError **) error {
    CCCryptorStatus status = kCCSuccess;
    NSData * result = [self flk_dataEncryptedUsingAlgorithm: kCCAlgorithmAES128
                                                    key: key
                                   initializationVector: nil
                                                options: kCCOptionPKCS7Padding
                                                  error: &status];
    
    if ( result != nil )
        return ( result );
    
    if ( error != NULL )
        *error = [NSError flk_errorWithCCCryptorStatus: status];
    
    return ( nil );
}

- (NSData *) flk_runCryptor: (CCCryptorRef) cryptor result: (CCCryptorStatus *) status
{
    size_t bufsize = CCCryptorGetOutputLength( cryptor, (size_t)[self length], true );
    void * buf = malloc( bufsize );
    size_t bufused = 0;
    size_t bytesTotal = 0;
    *status = CCCryptorUpdate( cryptor, [self bytes], (size_t)[self length],
                              buf, bufsize, &bufused );
    if ( *status != kCCSuccess )
    {
        free( buf );
        return ( nil );
    }
    
    bytesTotal += bufused;
    
    // From Brent Royal-Gordon (Twitter: architechies):
    //  Need to update buf ptr past used bytes when calling CCCryptorFinal()
    *status = CCCryptorFinal( cryptor, buf + bufused, bufsize - bufused, &bufused );
    if ( *status != kCCSuccess )
    {
        free( buf );
        return ( nil );
    }
    
    bytesTotal += bufused;
    
    return ( [NSData dataWithBytesNoCopy: buf length: bytesTotal] );
}

- (NSData *) flk_decryptedAES256DataUsingKey: (id) key error: (NSError **) error {
    CCCryptorStatus status = kCCSuccess;
    NSData * result = [self flk_decryptedDataUsingAlgorithm: kCCAlgorithmAES128
                                                    key: key
                                   initializationVector: nil
                                                options: kCCOptionPKCS7Padding
                                                  error: &status];
    
    if ( result != nil )
        return ( result );
    
    if ( error != NULL )
        *error = [NSError flk_errorWithCCCryptorStatus: status];
    
    return ( nil );
}

- (NSData *) flk_dataEncryptedUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key
                    initializationVector: (id) iv
                                 options: (CCOptions) options
                                   error: (CCCryptorStatus *) error
{
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = kCCSuccess;
    
    NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
    NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSMutableData * keyData, * ivData;
    if ( [key isKindOfClass: [NSData class]] )
        keyData = (NSMutableData *) [key mutableCopy];
    else
        keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    
    if ( [iv isKindOfClass: [NSString class]] )
        ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    else
        ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
    
    //[keyData autorelease];
    //[ivData autorelease];
    
    // ensure correct lengths for key and iv data, based on algorithms
   flk_fixKeyLengths( algorithm, keyData, ivData );
    
    status = CCCryptorCreate( kCCEncrypt, algorithm, options,
                             [keyData bytes], [keyData length], [ivData bytes],
                             &cryptor );
    
    if ( status != kCCSuccess )
    {
        if ( error != NULL )
            *error = status;
        return ( nil );
    }
    
    NSData * result = [self flk_runCryptor: cryptor result: &status];
    if ( (result == nil) && (error != NULL) )
        *error = status;
    
    CCCryptorRelease( cryptor );
    
    return ( result );
}

- (NSData *) flk_decryptedDataUsingAlgorithm: (CCAlgorithm) algorithm
                                     key: (id) key		// data or string
                    initializationVector: (id) iv		// data or string
                                 options: (CCOptions) options
                                   error: (CCCryptorStatus *) error
{
    CCCryptorRef cryptor = NULL;
    CCCryptorStatus status = kCCSuccess;
    
    NSParameterAssert([key isKindOfClass: [NSData class]] || [key isKindOfClass: [NSString class]]);
    NSParameterAssert(iv == nil || [iv isKindOfClass: [NSData class]] || [iv isKindOfClass: [NSString class]]);
    
    NSMutableData * keyData, * ivData;
    if ( [key isKindOfClass: [NSData class]] )
        keyData = (NSMutableData *) [key mutableCopy];
    else
        keyData = [[key dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    
    if ( [iv isKindOfClass: [NSString class]] )
        ivData = [[iv dataUsingEncoding: NSUTF8StringEncoding] mutableCopy];
    else
        ivData = (NSMutableData *) [iv mutableCopy];	// data or nil
    
    //[keyData autorelease];
    //[ivData autorelease];
    
    // ensure correct lengths for key and iv data, based on algorithms
    flk_fixKeyLengths( algorithm, keyData, ivData );
    
    status = CCCryptorCreate( kCCDecrypt, algorithm, options,
                             [keyData bytes], [keyData length], [ivData bytes],
                             &cryptor );
    
    if ( status != kCCSuccess )
    {
        if ( error != NULL )
            *error = status;
        return ( nil );
    }
    
    NSData * result = [self flk_runCryptor: cryptor result: &status];
    if ( (result == nil) && (error != NULL) )
        *error = status;
    
    CCCryptorRelease( cryptor );
    
    return ( result );
}

@end

#pragma mark == network configuration ==

@implementation FLKNetConfiguration

+ (FLKNetConfiguration *)defaultConfiguration {
    FLKNetConfiguration *config = [[FLKNetConfiguration alloc] init];
    config.debugDomain = FLK_DEBUG_DOMAIN.copy;
    config.releaseDomain = FLK_RELEASE_DOMAIN.copy;
    config.pingDomain = FLK_PING_DOMAIN.copy;
    config.timeoutInterval = FLK_TIMEOUT_INTERVAL;
    return config;
}

@end

#pragma mark == network core logics ==

@interface FLKNetCore ()

//network multicast delegate
@property (nonatomic, strong) id multiDelegate;

@property (nonatomic, assign, readwrite) FLKNetState netState;

//the balance for network route
@property (nonatomic, strong, readwrite) NSDictionary *balanceMap;

//retry download balance policy
@property (nonatomic, assign) NSUInteger retryBalanceCount;

@end

static FLKNetCore *instance                 =       nil;
static dispatch_once_t onceToken;
static NSString *kNetworkDisable            =       @"当前网络不可用，请检查网络设置！";
static NSString *kNetworkWorking            =       @"请稍后...";
static int      kRetryDownloadBalance       =       5;
static NSString *kBalanceAlertFailed        =       @"failed on loading balance map!";
static NSString *kBalancePreviousAlert      =       @"waiting for balance please!";
static FLKNetConfiguration *configuration   =       nil;
static NSString * const balanceFileName     =       @"balanceMap.json";
static NSString * const balanceAESKey       =       @"com.flk.ios-balance.key";

/**
 excute block func in main tread
 
 @param block to be excuted
 */
static void excuteInMainThread(void(^block)()) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

/**
 load all cert files in bundle

 @return cert array
 */
/*static NSArray * loadTLSAuthorizationCertFiles() {
    static NSArray *certs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *certPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"cer" inDirectory:nil];
        CFMutableArrayRef anchorCerts = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
        NSEnumerator *enumerator = [certPaths objectEnumerator];
        NSString *path = nil;
        while (path = [enumerator nextObject]) {
            NSData *data = [[NSData alloc] initWithContentsOfFile:path];
            SecCertificateRef cert = SecCertificateCreateWithData(kCFAllocatorDefault,
                                                                  (__bridge CFDataRef)data);
            if (cert) {
                CFArrayAppendValue(anchorCerts, cert);
                CFRelease(cert);
            }
        }
        certs = [[NSArray alloc] initWithArray:(__bridge NSArray * _Nonnull)(anchorCerts)];
    });
    return certs;
}
 */

@implementation FLKNetCore

+ (FLKNetCore *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            if (configuration == nil) {
                configuration = [FLKNetConfiguration defaultConfiguration];
            }
            //check for domain
            NSString *domain;
#if DEBUG
            domain = (configuration.debugDomain.length > 0 ?configuration.debugDomain.copy:FLK_DEBUG_DOMAIN.copy);
#else
            domain = (configuration.releaseDomain.length > 0 ?configuration.releaseDomain.copy:FLK_RELEASE_DOMAIN.copy);
#endif
            NSAssert(domain.length > 0, @"domain for net service can't be nil!");
            NSURL *baseURL = [NSURL URLWithString:domain];
            instance = [[[self class] alloc] initWithBaseURL:baseURL];
            
            [FLKNetCore setupInnerSettings];
        }
    });
    
    return instance;
}

+ (void)released {
    onceToken = 0;instance = nil;configuration = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)setupWithConfiguration:(FLKNetConfiguration *)config {
    NSAssert(config != nil, @"network configure couldn't be nil!");
    configuration = config;
    //check for domain
    NSString *domain;
#if DEBUG
    domain = (config.debugDomain.length > 0 ?config.debugDomain.copy:FLK_DEBUG_DOMAIN.copy);
#else
    domain = (config.releaseDomain.length > 0 ?config.releaseDomain.copy:FLK_RELEASE_DOMAIN.copy);
#endif
    NSAssert(domain.length > 0, @"domain for net service can't be nil!");
    //static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            NSURL *baseURL = [NSURL URLWithString:domain];
            instance = [[[self class] alloc] initWithBaseURL:baseURL];
        }
    });
    
    [FLKNetCore setupInnerSettings];
}

+ (void)setupInnerSettings {
    //check for ping
    NSString *pingH = (configuration.pingDomain.length > 0 ?configuration.pingDomain.copy:FLK_PING_DOMAIN.copy);
    GLobalRealReachability.hostForPing = pingH;
    
    //check for timeout interval
    CGFloat timeout = configuration.timeoutInterval;
    if (timeout < 15 || timeout > 60) {
        timeout = FLK_TIMEOUT_INTERVAL;
    }
    instance.requestSerializer.timeoutInterval = timeout;
    
    // init multicastDelegate
    instance.multiDelegate = [[GCDMulticastDelegate alloc] init];
    
    //setup net check
    [GLobalRealReachability startNotifier];
    instance.netState = FLKNetStateUnknown;
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    [instance updateNetworkState:status];
    [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(networkStateDidChanged:) name:kRealReachabilityChangedNotification object:nil];
    
    //init retry count
    instance.retryBalanceCount = 0;
    
    //setup bundle resource to local documents
    [[FLKNetCore shared] copyPreviousBalanceMapFromBundle2DocumentsIfNeeded];
}

- (void)copyPreviousBalanceMapFromBundle2DocumentsIfNeeded {
    NSString *path = [self getBalanceMapPath];
    //whether the map file exist
    NSFileManager *fileHandler = [NSFileManager defaultManager];
    if ([fileHandler fileExistsAtPath:path]) {
        NSLog(@"documents resources did exists!");
        return ;
    }
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:balanceFileName ofType:nil];
    if (bundlePath.length != 0) {
        NSError *error = nil;
        BOOL ret = [fileHandler copyItemAtPath:bundlePath toPath:path error:&error];
        if (!ret || error != nil) {
            NSLog(@"failed to copy bunlde source to local documents error:%@", error.localizedDescription);
        } else {
            NSLog(@"copy bundle source to documents path successful!");
        }
    }
}

#pragma mark -- initialized methods

- (id)copyWithZone:(struct _NSZone *)zone {
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        //TODO:custmize optional
    }
    return self;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        //request serializer, can be set with HTTP's header
        AFHTTPRequestSerializer *req_serial = [AFHTTPRequestSerializer serializer];
        //req_serial.timeoutInterval = configuration.timeoutInterval;
        //[req_serial setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        self.requestSerializer = req_serial;
        //*
        //response serializer, can be set with HTTP's accept type
        AFJSONResponseSerializer *res_serial = [AFJSONResponseSerializer serializer];
        //res_serial.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
        //res_serial.acceptableStatusCodes = [NSIndexSet indexSetWithIndex:400];
        self.responseSerializer = res_serial;
        //*/
        
        //双向认证 安全设置
        NSSet *certs = [AFSecurityPolicy certificatesInBundle:[NSBundle mainBundle]];
        //security policy
        FLKSecurityPolicy *sec_policy = [FLKSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        //允许非权威机构颁发的证书
        sec_policy.allowInvalidCertificates = true;
        //验证域名一致性
        sec_policy.validatesDomainName = false;
        sec_policy.pinnedCertificates = certs;
        self.securityPolicy = sec_policy;
    }
    return self;
}

- (void)setAuthorizationWithUsername:(NSString *)username password:(NSString *)password {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
}

- (void)setAuthorization:(NSString *)info forKey:(NSString *)key {
    [self.requestSerializer setValue:info forHTTPHeaderField:key];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -- network state changed

- (void)networkStateDidChanged:(NSNotification *)noti {
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    [self updateNetworkState:status];
}

- (void)updateNetworkState:(ReachabilityStatus)status {
    FLKNetState aState = 1 << (status + 1);
    
    //check network balance when net state become avaliable from unavaliable
    if ((status &(FLKNetStateViaWWAN|FLKNetStateViaWiFi))
        && (self.netState & (FLKNetStateUnknown|FLKNetStateUnavaliable))
        && self.balanceMap == nil) {
        [self loadNetworkBalance];
    }
    self.netState = aState;
}

- (void)setNetState:(FLKNetState)netState {
    if (netState != _netState) {
        [self.multiDelegate networkStateDidChangeTo:netState withPrevious:_netState];
        _netState = netState;
    }
}

- (BOOL)netvalid {
    return (self.netState != FLKNetStateUnknown) && (self.netState != FLKNetStateUnavaliable);
}

#pragma mark -- Balance(network route) policy --

- (NSDictionary * _Nullable)fetchPreviousSavedBalanceMap {
    NSString *path = [self getBalanceMapPath];
    //whether the map file exist
    NSFileManager *fileHandler = [NSFileManager defaultManager];
    if (![fileHandler fileExistsAtPath:path]) {
        return nil;
    }
    //generate the map data(encrypted)
    NSData *mapEnData = [NSData dataWithContentsOfFile:path];
    if (mapEnData.length == 0) {
        NSLog(@"failed to fetch the balance map encrypted data!");
        return nil;
    }
    NSError *err = nil;
    NSData *mapDeData = [mapEnData flk_decryptedAES256DataUsingKey:balanceAESKey error:&err];
    if (err != nil) {
        NSLog(@"failed to decrypt balance map data!");
        return nil;
    }
    //convert data to map
    err = nil;
    NSDictionary *map = [NSJSONSerialization JSONObjectWithData:mapDeData options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&err];
    if (err != nil || map == nil) {
        NSLog(@"failed to convert balance data to map format!");
        return nil;
    }
    return map;
}

- (BOOL)saveBalanceMap:(NSDictionary *)map {
    if (map == nil) {
        return false;
    }
    NSError *err = nil;
    NSData *mapData = [NSJSONSerialization dataWithJSONObject:map options:NSJSONWritingPrettyPrinted error:&err];
    if (err != nil || mapData.length == 0) {
        NSLog(@"failed convert balance map to hex data!");
        return false;
    }
    //encrypt data
    err = nil;
    NSData *mapEnData = [mapData flk_encryptedAES256DataUsingKey:balanceAESKey error:&err];
    if (err != nil || mapEnData.length == 0) {
        NSLog(@"failed encrypt balance map data!");
        return false;
    }
    //saved in local path
    NSString *path = [self getBalanceMapPath];
    NSFileManager *fileHandler = [NSFileManager defaultManager];
    if ([fileHandler fileExistsAtPath:path]) {
        err = nil;
        [fileHandler removeItemAtPath:path error:&err];
        if (err) {
            NSLog(@"failed to remove old file at path:%@---error:%@", path, err.localizedDescription);
        }
    }
    return [mapEnData writeToFile:path atomically:true];
}

- (NSString *)getBalanceMapPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true);
    NSString *documentPath = [paths firstObject];
    return [documentPath stringByAppendingPathComponent:balanceFileName];
}

/**
 called before send request
 */
- (BOOL)checkBalanceMap {
    return self.balanceMap != nil;
}

#pragma mark -- request cancel method

- (void)cancelAllRequest {
    //url session's tasks include:dataTasks/uploadTasks/downloadTasks
    NSArray *tasks = self.tasks;
    if (tasks.count == 0) {
        return;
    }
    for (NSURLSessionDataTask *task in tasks) {
        [task cancel];
    }
}

- (void)cancelRequestForClass:(Class)aClass {
    if (aClass == nil) {
        return;
    }
    //url session's tasks include:dataTasks/uploadTasks/downloadTasks
    NSArray *tasks = self.tasks;
    if (tasks.count == 0) {
        return;
    }
    NSString *classString = NSStringFromClass(aClass);
    for (NSURLSessionDataTask *task in tasks) {
        NSString *taskDesc = task.taskDescription;
        if (taskDesc.length > 0 && [taskDesc rangeOfString:classString].location != NSNotFound) {
            [task cancel];
        }
    }
}

#pragma mark -- network balance

- (NSDictionary *)assembleRequestBalanceParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:0];
    NSDictionary *mainConfigs = [[NSBundle mainBundle] infoDictionary];
    //app version TODO: should upload bundle-identifier to avoid be signed by another vendor
    NSString *app_version = [mainConfigs objectForKey:@"CFBundleShortVersionString"];
    [params setObject:app_version forKey:@"version"];
    //vendor infomation, must url-encode cause of request method was 'GET'
    NSString *vendor = [[[UIDevice currentDevice] model] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [params setObject:vendor forKey:@"vendor"];
    //client operator system version
    NSString *os_version = [[[UIDevice currentDevice] systemVersion] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    [params setObject:os_version forKey:@"osversion"];
    //platform
    [params setObject:FLK_BALANCE_PLATFORM forKey:@"platform"];
    //uid
    [params setObject:FLK_BALANCE_UID forKey:@"uid"];
    return params.copy;
}

- (void)loadNetworkBalance {
    if (self.balanceMap != nil) {
        return;
    }
    //assemble request params
    NSDictionary *params = [self assembleRequestBalanceParams];
    __weak typeof(FLKNetCore) *weakSelf = self;
    [self GET:@"lb" parameters:params class:nil view:nil hudEnable:false progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObj) {
        __strong typeof(FLKNetCore) *strongSelf = weakSelf;
        if (responseObj) {
            NSLog(@"success to load network balance :%@",responseObj);
            strongSelf.balanceMap = nil;
            strongSelf.balanceMap = [[NSDictionary alloc] initWithDictionary:responseObj];
            //save in sandbox
            [strongSelf saveBalanceMap:responseObj];
            //notify delegate that successfully download network balance
            [strongSelf.multiDelegate didLoadBalanceWithError:nil];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [strongSelf retryDownloadNetworkBalance];
            });
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"failed to load network balance :%@",error.localizedDescription);
        __strong typeof(FLKNetCore) *strongSelf = weakSelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [strongSelf retryDownloadNetworkBalance];
        });
    }];
}

- (void)retryDownloadNetworkBalance {
    self.retryBalanceCount++;
    if (self.retryBalanceCount >= kRetryDownloadBalance) {
        [self failedOnRetryLoadBalanceMap];
        return;
    }
    if (self.balanceMap == nil && (self.netState & (FLKNetStateViaWiFi|FLKNetStateViaWWAN))) {
        //网络可用的情况下
        [self loadNetworkBalance];
    } else {
        [self failedOnRetryLoadBalanceMap];
    }
}

- (void)failedOnRetryLoadBalanceMap {
    self.retryBalanceCount = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(loadNetworkBalance) object:nil];
    //when failed on beyond the maxium number for retry, then use local cache when it exist.
    NSDictionary *map = [self fetchPreviousSavedBalanceMap];
    NSError *err = nil;
    if (map != nil) {
        self.balanceMap = [NSDictionary dictionaryWithDictionary:map];
    } else {
        err = [NSError errorWithDomain:kBalanceAlertFailed code:-1 userInfo:nil];
    }
    [self.multiDelegate didLoadBalanceWithError:err];
}

- (NSString * _Nullable)assembleHostAndPort4HTTPSWithMap:(NSDictionary *)map {
    if (map == nil) {
        return nil;
    }
    NSString *mH = [map objectForKey:@"host"];
    NSNumber *mP = [map objectForKey:@"port"];
    NSString *addr = [NSString stringWithFormat:@"https://%@:%@",mH, mP];
    return addr;
}

- (NSDictionary * _Nullable)assembleConfigures4ServerKey:(NSString *)key {
    NSMutableDictionary *tmpMap = nil;
    if (self.balanceMap != nil && key.length != 0) {
        NSArray *hosts = [self.balanceMap objectForKey:key];
        if (hosts.count > 0) {
            NSDictionary *map = hosts.firstObject;
            if (map != nil) {
                NSString *host = [self assembleHostAndPort4HTTPSWithMap:map];
                if (host.length != 0) {
                    tmpMap = [NSMutableDictionary dictionaryWithObjectsAndKeys:host,FLK_NETSERVICE_DOMAIN_RELEASE,host, FLK_NETSERVICE_DOMAIN_DEBUG, nil, nil];
                }
            }
        }
        
    }
    return tmpMap.copy;
}

#pragma mark -- Multicast Delegate
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    __weak typeof(FLKNetCore) *weakSelf = self;
    dispatch_block_t block = ^{
        __strong typeof(FLKNetCore) *strongSelf = weakSelf;
        [strongSelf.multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
    };
    block();
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    __weak typeof(FLKNetCore) *weakSelf = self;
    dispatch_block_t block = ^{
        __strong typeof(FLKNetCore) *strongSelf = weakSelf;
        [strongSelf.multiDelegate removeDelegate:delegate delegateQueue:delegateQueue];
    };
    block();
}

#pragma mark -- Public Request Methods --
- (void)GET:(NSString *)path parameters:(id)params class:(Class)cls view:(UIView *)view hudEnable:(BOOL)hud progress:(void (^)(NSProgress * _Nonnull progress))downProgress success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    //step 1: check the network state
    if (![self wetherRequestCanContinueWithView:view withHudEnable:hud]) {
        //408 request time out!
        NSError *error = [NSError errorWithDomain:kNetworkDisable code:408 userInfo:nil];
        if (failure) {
            failure(nil, error);
        }
        return;
    }
    __weak typeof(view) weakView = view;
    //step 4: make url session data task
    void (^sucessResponse)(NSURLSessionDataTask * _Nonnull, id _Nullable) = [self successOnRequestWithSuccess:success andFailure:failure withInterface:weakView];
    void (^failureResponse)(NSURLSessionDataTask * _Nonnull, NSError * _Nonnull) = [self failureOnRequestWithFailure:failure withInterface:weakView];
    NSURLSessionDataTask *dataTask = [super GET:path parameters:params progress:downProgress success:sucessResponse failure:failureResponse];
    //step 5: store the vcr's class charator for canceling action some where.
    if (cls != nil) {
        dataTask.taskDescription = [NSString stringWithFormat:@"class_%@_request", NSStringFromClass(cls)];
    }
}

- (void)POST:(NSString *)path parameters:(id)params class:(Class)cls view:(UIView *)view success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    //step 1: check the network state
    if (![self wetherRequestCanContinueWithView:view withHudEnable:true]) {
        //408 request time out!
        NSError *error = [NSError errorWithDomain:kNetworkDisable code:408 userInfo:nil];
        if (failure) {
            failure(nil, error);
        }
        return;
    }
    __weak typeof(view) weakView = view;
    //step 4: make url session data task
    void (^sucessResponse)(NSURLSessionDataTask * _Nonnull, id _Nullable) = [self successOnRequestWithSuccess:success andFailure:failure withInterface:weakView];
    void (^failureResponse)(NSURLSessionDataTask * _Nonnull, NSError * _Nonnull) = [self failureOnRequestWithFailure:failure withInterface:weakView];
    NSURLSessionDataTask *dataTask = [super POST:path parameters:params progress:nil success:sucessResponse failure:failureResponse];
    //step 5: store the vcr's class charator for canceling action some where.
    if (cls != nil) {
        dataTask.taskDescription = [NSString stringWithFormat:@"class_%@_request", NSStringFromClass(cls)];
    }
}

- (void)POST:(NSString *)path parameters:(id)params class:(Class)cls view:(UIView *)view constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> _Nonnull))block progress:(void (^)(NSProgress * _Nonnull))uploadProgress success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    //step 1: check the network state
    if (![self wetherRequestCanContinueWithView:view withHudEnable:true]) {
        //408 request time out!
        NSError *error = [NSError errorWithDomain:kNetworkDisable code:408 userInfo:nil];
        if (failure) {
            failure(nil, error);
        }
        return;
    }
    __weak typeof(view) weakView = view;
    //step 4: make url session data task
    void (^sucessResponse)(NSURLSessionDataTask * _Nonnull, id _Nullable) = [self successOnRequestWithSuccess:success andFailure:failure withInterface:weakView];
    void (^failureResponse)(NSURLSessionDataTask * _Nonnull, NSError * _Nonnull) = [self failureOnRequestWithFailure:failure withInterface:weakView];
    NSURLSessionDataTask *dataTask = [super POST:path parameters:params constructingBodyWithBlock:block progress:uploadProgress success:sucessResponse failure:failureResponse];
    //step 5: store the vcr's class charator for canceling action some where.
    if (cls != nil) {
        dataTask.taskDescription = [NSString stringWithFormat:@"class_%@_request", NSStringFromClass(cls)];
    }
}

- (void)PUT:(NSString *)path parameters:(id)params class:(Class)cls view:(UIView *)view success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    //step 1: check the network state
    if (![self wetherRequestCanContinueWithView:view withHudEnable:true]) {
        //408 request time out!
        NSError *error = [NSError errorWithDomain:kNetworkDisable code:408 userInfo:nil];
        if (failure) {
            failure(nil, error);
        }
        return;
    }
    __weak typeof(view) weakView = view;
    //step 4: make url session data task
    void (^sucessResponse)(NSURLSessionDataTask * _Nonnull, id _Nullable) = [self successOnRequestWithSuccess:success andFailure:failure withInterface:weakView];
    void (^failureResponse)(NSURLSessionDataTask * _Nonnull, NSError * _Nonnull) = [self failureOnRequestWithFailure:failure withInterface:weakView];
    NSURLSessionDataTask *dataTask = [super PUT:path parameters:params success:sucessResponse failure:failureResponse];
    //step 5: store the vcr's class charator for canceling action some where.
    if (cls != nil) {
        dataTask.taskDescription = [NSString stringWithFormat:@"class_%@_request", NSStringFromClass(cls)];
    }
}

#pragma mark -- handle request pre start

- (BOOL)wetherRequestCanContinueWithView:(UIView * _Nullable)view withHudEnable:(BOOL)hud {
    //step 1: check the network state
    if (![self netvalid]) {
        excuteInMainThread(^{
            [SVProgressHUD showErrorWithStatus:kNetworkDisable];
        });
        return false;
    }
    
    //step 2:check wether there is a view should disable while networking
    if (view != nil) {
        view.userInteractionEnabled = false;
    }
    //step 3: display the hud while netwoking
    if (hud) {
        excuteInMainThread(^{
            [SVProgressHUD showWithStatus:kNetworkWorking];
        });
    }
    
    return true;
}

#pragma mark -- handle request response

- (void (^)(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject))successOnRequestWithSuccess:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success andFailure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure withInterface:(UIView *)weakView {
    
    void (^response)(NSURLSessionDataTask * _Nonnull, id _Nullable) = ^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject){
        //parser response
         Class aClass = [responseObject class];Class aDestClass = [NSDictionary class];
         if ([aClass isKindOfClass:aDestClass] || [aClass isMemberOfClass:aDestClass] || [aClass isSubclassOfClass:aDestClass]) {
            unsigned int code = [[responseObject objectForKey:@"status"] intValue];
            if (code == 0) {
                if (success) {
                    success(task, responseObject);
                }
            } else {
                NSString *errDomain = [responseObject objectForKey:@"msg"];
                NSError *error = [NSError errorWithDomain:errDomain code:code userInfo:nil];
                if (failure) {
                    failure(task, error);
                }
            }
        } else {
            if (success) {
                success(task, responseObject);
            }
        }
        
        //reuse user interface acton
        if (weakView) {
            weakView.userInteractionEnabled = true;
        }
        //dismiss the hud
        excuteInMainThread(^{
            [SVProgressHUD dismiss];
        });
    };
    
    return response;
}

- (void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failureOnRequestWithFailure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure withInterface:(UIView *)weakView {
    
    void (^response)(NSURLSessionDataTask * _Nonnull, NSError * _Nonnull) = ^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error){
        //reuse user interface acton
        if (weakView) {
            weakView.userInteractionEnabled = true;
        }
        //dismiss the hud
        excuteInMainThread(^{
            [SVProgressHUD dismiss];
        });
        if (failure) {
            failure(task, error);
        }
    };
    
    return response;
}

@end
