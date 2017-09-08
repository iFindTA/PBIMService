//
//  FLKIMService.m
//  FLKIMServicePro
//
//  Created by nanhu on 2016/11/16.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLKIMService.h"
#import <FLKNetService/FLKNetService.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import <MulticastDelegate/GCDMulticastDelegate.h>

typedef NS_ENUM(NSUInteger, FLKIMTag) {
    FLKIMTagWriteHeartBeat          =   1   <<  0,
    FLKIMTagWritePacket             =   1   <<  1,
    FLKIMTagReadLength              =   1   <<  2,
    FLKIMTagReadPayload             =   1   <<  3
};

#pragma mark -- IM's packet

@interface FLKPacket ()

@property (nonatomic, strong, readwrite) NSDictionary *payloadMap;

@property (nonatomic, strong, readwrite) NSData *payloadData;

@property (nonatomic, copy, readwrite) NSString *mid;

@end

@implementation FLKPacket

+ (FLKPacket *)packetWithMap:(NSDictionary *)aMap {
    NSAssert(aMap != nil, @"can't send empty message!");
    FLKPacket *packet = [[FLKPacket alloc] initWithMap:aMap];
    return packet;
}

+ (FLKPacket *)packetWithData:(NSData *)aData {
    NSAssert(aData.length > 0, @"can't received empty data!");
    FLKPacket *packet = [[FLKPacket alloc] initWithData:aData];
    return packet;
}

- (id)initWithMap:(NSDictionary *)aMap {
    self = [super init];
    if (self) {
        _payloadMap = [NSDictionary dictionaryWithDictionary:aMap];
    }
    return self;
}

- (id)initWithData:(NSData *)aData {
    self = [super init];
    if (self) {
        _payloadData = [NSData dataWithData:aData];
    }
    return self;
}

- (NSData *)payloadData {
    if (!_payloadData) {
        NSError *error = nil;
        NSData *pData = [NSJSONSerialization dataWithJSONObject:self.payloadMap options:NSJSONWritingPrettyPrinted error:&error];
        if (error) {
            NSLog(@"packet 2 data error :%@",error.localizedDescription);
            return nil;
        }
        // cause of iPhone was little endian, should convert to big endian
        int32_t len = CFSwapInt32HostToBig((int32_t)[pData length]);
        NSMutableData *dData = [NSMutableData dataWithBytes:&len length:sizeof(int32_t)];
        [dData appendData:pData];
        _payloadData = [dData copy];
    }
    return _payloadData;
}

- (NSDictionary *)payloadMap {
    if (!_payloadMap) {
        NSError *error = nil;
        NSDictionary *map = [NSJSONSerialization JSONObjectWithData:self.payloadData options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&error];
        if (error) {
            NSLog(@"packet 2 map error :%@",error.localizedDescription);
            return nil;
        }
        _payloadMap = [NSDictionary dictionaryWithDictionary:map];
    }
    return _payloadMap;
}

- (NSString *)description {
    NSError *error = nil;NSData *pData = self.payloadData;
    if (pData.length == 0) {
        pData = [NSJSONSerialization dataWithJSONObject:self.payloadMap options:NSJSONWritingPrettyPrinted error:&error];
    }
    if (error) {
        NSLog(@"packet 2 description error :%@",error.localizedDescription);
        return nil;
    }
    return [[NSString alloc] initWithData:pData encoding:NSUTF8StringEncoding];
}

- (NSString *)mid {
    if (_mid == nil) {
        NSString *tmp_id = [self.payloadMap objectForKey:@"id"];
        if (tmp_id.length == 0) {
            tmp_id = [self.payloadMap objectForKey:@"command"];
        }
        _mid = [tmp_id copy];
    }
    return _mid;
}

@end

//max count for auto connect retry count
static NSUInteger FLK_RETRY_AUTO_CONNECT_COUNT                  =   5;
static NSString * const FLK_IM_TLS_FILE_TYPE                    =   @"cer";

/**
 *  消息格式简化为：
 *
 *  Length	Payload
 *     4      JSON
 *  Length表示Payload的长度，Payload为JSON.
 */
static NSUInteger const FLK_PACKET_LENGTH                       =   4;
static NSUInteger const FLK_HEART_BEAT_INTERVAL                 =   4.5*60;

NSString * const FLK_IM_MSG_COMMAND_AUTHOR                      =   @"auth";
NSString * const FLK_IM_MSG_COMMAND_MESSAGE                     =   @"message";

@interface FLKIMService () <GCDAsyncSocketDelegate, FLKNetworkCoreDelegate>

//im multicast delegate
@property (nonatomic, strong) id multiDelegate;

@property (nonatomic, strong) GCDAsyncSocket *mSocket;
@property (nonatomic, strong) dispatch_queue_t mSocketQueue;

// socket state and flag
@property (nonatomic, assign, readwrite) FLKIMState mSocketState;
@property (nonatomic, assign, readwrite) BOOL mSocketClosedManualy;
@property (nonatomic, assign) NSUInteger retryConnectCount;
@property (nonatomic, strong) dispatch_source_t heartBeater;
@property (nonatomic, strong) dispatch_queue_t mHeartBeatQueue;

// user authorization info
@property (nonatomic, strong) FLKPacket *authorConfigs;

@end

static FLKIMService *instance = nil;
static dispatch_once_t onceToken;

static NSArray * loadTLSAuthorizationCertFiles() {
    static NSArray *certs = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *certPaths = [[NSBundle mainBundle] pathsForResourcesOfType:FLK_IM_TLS_FILE_TYPE inDirectory:nil];
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

@implementation FLKIMService

- (id)copyWithZone:(struct _NSZone *)zone {
    return instance;
}

+ (FLKIMService *)shared {
    //static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FLKIMService alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        
        // init multicastDelegate
        self.multiDelegate = [[GCDMulticastDelegate alloc] init];
        
        //observe application notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        //reset retry count
        self.retryConnectCount = 0;
        self.mSocketState = FLKIMStateDisconnected;
    }
    return self;
}

- (void)stopService {
    self.mSocketState = FLKIMStateDisconnected;
    self.mSocketClosedManualy = true;
    [self.mSocket disconnect];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
+ (void)released {
    [[FLKIMService shared] stopService];
    onceToken = 0;instance = nil;
}

#pragma mark -- Multicast Delegate
- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    __weak typeof(FLKIMService) *weakSelf = self;
    dispatch_block_t block = ^{
        __strong typeof(FLKIMService) *strongSelf = weakSelf;
        [strongSelf.multiDelegate addDelegate:delegate delegateQueue:delegateQueue];
    };
    block();
    
    //    GCDMulticastDelegate *multicast = (GCDMulticastDelegate *)self.multiDelegate;
    //    NSLog(@"multicast delegate count:%zd",multicast.count);
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    __weak typeof(FLKIMService) *weakSelf = self;
    dispatch_block_t block = ^{
        __strong typeof(FLKIMService) *strongSelf = weakSelf;
        [strongSelf.multiDelegate removeDelegate:delegate delegateQueue:delegateQueue];
    };
    block();
    
    //GCDMulticastDelegate *multicast = (GCDMulticastDelegate *)self.multiDelegate;
    //NSLog(@"multicast delegate count:%zd",multicast.count);
}

#pragma mark -- Application Notifications

- (void)_applicationDidBecomeActive {
    if (self.mSocketClosedManualy) {
        NSLog(@"start socket service ---");
        [self startService];
    }
}

- (void)_applicationDidEnterBackground {
    [self stopService];
}

#pragma mark -- Net Service Delegate

- (void)networkStateDidChangeTo:(FLKNetState)aState withPrevious:(FLKNetState)preState {
    //auto retry connect when the network state become avaliable from unavaliable
    if ((preState & (FLKNetStateUnknown|FLKNetStateUnavaliable)) &&
        (aState & (FLKNetStateViaWWAN|FLKNetStateViaWiFi))
        && !self.mSocketClosedManualy) {
        self.retryConnectCount = 0;
        [self retryStartService];
    }
}

- (void)didLoadBalanceWithError:(NSError *)error {
    //NSLog(@"im received delegate call :%s",__FUNCTION__);
    if (error != nil) {
        NSLog(@"failed load balance maps in function:%s",__FUNCTION__);
        return;
    }
    if ((self.mSocketState & (FLKIMStateDisconnected)) && !self.mSocketClosedManualy && self.authorConfigs.payloadData.length > 0) {
        self.retryConnectCount = 0;
        [self retryStartService];
    }
}

/**
 when im's host/port unavaliable, start net service to load balance again
 */
- (void)virtualLoadBalance {
    [[FLKNetCore shared] loadNetworkBalance];
}

#pragma mark -- socket management

- (dispatch_queue_t)mSocketQueue {
    if (!_mSocketQueue) {
        _mSocketQueue = dispatch_queue_create("com.flk.im-queue", DISPATCH_QUEUE_SERIAL);
    }
    return _mSocketQueue;
}

- (GCDAsyncSocket *)mSocket {
    if (!_mSocket) {
        _mSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.mSocketQueue];
    }
    return _mSocket;
}

- (void)setMSocketState:(FLKIMState)mSocketState {
    if (mSocketState == _mSocketState) {
        return;
    }
    [self.multiDelegate connectionDidChanged2State:mSocketState];
    _mSocketState = mSocketState;
}

- (void)startService {
    if (self.mSocketState & (FLKIMStateConnecting|FLKIMStateConnected)) {
        return;
    }
    //change socket state
    self.mSocketClosedManualy = false;
    self.mSocketState = FLKIMStateConnecting;
    
    NSDictionary *serverConfigs = [NSDictionary dictionaryWithDictionary:[FLKNetCore shared].balanceMap];
    NSArray *imServers = [serverConfigs objectForKey:@"accessServers"];
    NSDictionary *imServer = [imServers firstObject];
    NSString *host = [imServer objectForKey:@"host"];
    uint16_t port = [[imServer objectForKey:@"port"] intValue];
    if (host.length == 0) {
        NSLog(@"im server address error!");
        self.mSocketState = FLKIMStateDisconnected;
        [self virtualLoadBalance];
        return;
    }
    self.mSocketState = FLKIMStateConnecting;
    NSError *error = nil;
    [self.mSocket connectToHost:host onPort:port error:&error];
    if (error) {
        NSLog(@"socket connect error :%@", error.localizedDescription);
        [self retryStartService];
        self.mSocketState = FLKIMStateDisconnected;
    }
}

- (void)retryStartService {
    self.retryConnectCount++;
    if (self.retryConnectCount >= FLK_RETRY_AUTO_CONNECT_COUNT) {
        NSLog(@"failed to retry auto start im service!");
        self.retryConnectCount = 0;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(retryStartService) object:nil];
        return;
    }
    
    if ((self.mSocketState & (FLKIMStateConnecting | FLKIMStateConnected))
        ||[[FLKNetCore shared] netState] & (FLKNetStateUnknown|FLKNetStateUnavaliable)) {
        self.retryConnectCount = 0;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(retryStartService) object:nil];
    } else {
        [self startService];
    }
}

- (void)startServiceWithAuthorization:(FLKPacket *)cfgs {
    NSAssert(cfgs.payloadData.length > 0, @"usr's authorization shouldn't be nil!");
    //step 1: save the author info datas
    self.authorConfigs = cfgs;
    //step 2:start service
    [self startService];
}
// authorized in when the socket did connected
- (void)authorizedWithPacket:(FLKPacket *)cfgs {
    if (self.mSocketState & (FLKIMStateConnecting|FLKIMStateConnected)) {
        return;
    }
    self.authorConfigs = cfgs;
    [self authorizedInImmediately];
}
#pragma mark -- private

- (void)authorizedInImmediately {
    //start authorize in server with user's acc && pwd
    if (self.authorConfigs.payloadData.length > 0) {
        [self.mSocket writeData:self.authorConfigs.payloadData withTimeout:5 tag:FLKIMTagWritePacket];
        //NSLog(@"will start authorization !");
        //NSLog(@"write author in data:%@",self.authorConfigs.payloadData);
        [self readSocketData];
    }
}

- (void)sendPacket:(FLKPacket *)payload {
    if (payload.payloadData.length == 0) {
        NSLog(@"can't send nil msg !");
        return;
    }
    [self.mSocket writeData:payload.payloadData withTimeout:5 tag:FLKIMTagWritePacket];
    sleep(0.001);
    //[self readSocketData];
}

#pragma mark -- Socket Delegate, list by call order

//-------------------------------socket connect---------------------------------

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"%s",__FUNCTION__);
    //chage connect state
    self.mSocketState = FLKIMStateConnected;
    self.retryConnectCount = 0;self.mSocketClosedManualy = false;
    //start tls authorization
    NSDictionary *sslOpts = [NSDictionary dictionaryWithObjectsAndKeys:@(true),GCDAsyncSocketManuallyEvaluateTrust, nil];
    [self.mSocket startTLS:sslOpts];
    
    [self startHeartBeatTimer];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"%s---error:%@",__FUNCTION__, err.localizedDescription);
    self.mSocketState = FLKIMStateDisconnected;
    [self clearResourcesAfterDisconnected];
    NSString *errorInfo = err.localizedDescription.lowercaseString;
    NSRange remoteClosedRange = [errorInfo rangeOfString:@"closed by remote peer"];
    if (remoteClosedRange.location != NSNotFound) {
        return;
    }
    if (!self.mSocketClosedManualy) {
        [self retryStartService];
    }
}

#pragma mark -- heart beat

- (NSString *)UUIDString {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *s = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    if(uuid) {
        CFRelease(uuid);
    }
    return s;
}

- (dispatch_queue_t)mHeartBeatQueue {
    if (!_mHeartBeatQueue) {
        dispatch_queue_t queue = dispatch_queue_create("com.flk.im-heartbeat", NULL);
        _mHeartBeatQueue = queue;
    }
    return _mHeartBeatQueue;
}

- (dispatch_source_t)heartBeater {
    if (!_heartBeater) {
        _heartBeater = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.mHeartBeatQueue);
        int64_t timeInterval = FLK_HEART_BEAT_INTERVAL*NSEC_PER_SEC;
        dispatch_time_t time = dispatch_walltime(NULL, 60*NSEC_PER_SEC);
        dispatch_source_set_timer(_heartBeater, time, timeInterval, 1*NSEC_PER_SEC);
        __weak typeof(FLKIMService) *weakSelf = self;
        dispatch_source_set_event_handler(_heartBeater, ^{
            //NSLog(@"its time for ping!");
            __strong typeof(FLKIMService) *strongSelf = weakSelf;
            [strongSelf socketHeartBeatEvent];
        });
    }
    return _heartBeater;
}

- (void)socketHeartBeatEvent {
    NSString *uuid = [self UUIDString];
    NSDictionary *heartConfigs = [NSDictionary dictionaryWithObjectsAndKeys:@"iq",@"command",@"get",@"type",@"ping",@"name",uuid,@"id", nil];
    FLKPacket *heartPacket = [FLKPacket packetWithMap:heartConfigs];
    [self.mSocket writeData:heartPacket.payloadData withTimeout:-1.0 tag:FLKIMTagWriteHeartBeat];
    //[self.mSocket readDataWithTimeout:-1 tag:FLKIMTagWriteHeartBeat];
    NSLog(@"heart beat...");
}

- (void)startHeartBeatTimer {
    dispatch_resume(self.heartBeater);
}

- (void)clearResourcesAfterDisconnected {
    dispatch_source_cancel(self.heartBeater);
    _heartBeater = nil;
    _mHeartBeatQueue = nil;
    //reset retry count
    self.retryConnectCount = 0;
}

#pragma mark -------------------------------socket TLS---------------------------------

- (SecTrustResultType)evaluateServertrust:(SecTrustRef)trust {
    NSArray *certs = loadTLSAuthorizationCertFiles();
    OSStatus status = SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)certs);
    if (status != noErr) {
        return kSecTrustResultOtherError;
    }
    SecTrustResultType retType;
    status = SecTrustEvaluate(trust, &retType);
    if (status != noErr) {
        return kSecTrustResultOtherError;
    }
    return retType;
}

- (void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"%s",__FUNCTION__);
    SecTrustResultType type = [self evaluateServertrust:trust];
    if (type == kSecTrustResultUnspecified || type == kSecTrustResultProceed) {
        completionHandler(true);
    } else {
        //trust verify manualy!
        FLKNetConfiguration *cfg = [FLKNetConfiguration defaultConfiguration];
        NSURL *hostURL;
#ifdef  DEBUG
        hostURL = [NSURL URLWithString:cfg.debugDomain];
#else
        hostURL = [NSURL URLWithString:cfg.releaseDomain];
#endif
        SecPolicyRef policyRef = SecPolicyCreateSSL(true, (__bridge CFStringRef)hostURL.host);
        
        OSStatus    status;
        SecTrustRef serverTrust;
        // noErr == status?
        NSArray *certs = loadTLSAuthorizationCertFiles();
        status = SecTrustCreateWithCertificates(CFBridgingRetain(certs), policyRef, &serverTrust);
        status = SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)certs);
        // noErr == status?
        SecTrustResultType trustResult;
        status = SecTrustEvaluate(serverTrust, &trustResult);
        // noErr == status?
        if(kSecTrustResultProceed == trustResult || kSecTrustResultUnspecified == trustResult) {
            // all good
            completionHandler(true);
        } else {
            CFArrayRef arrayRefTrust = SecTrustCopyProperties(serverTrust);
            NSLog(@"error in connection occured\n%@", arrayRefTrust);
            completionHandler(false);
        }
    }
}

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"%s",__FUNCTION__);
    //[self readSocketData];
    [self authorizedInImmediately];
}

#pragma mark -------------------------------socket timeout---------------------------------

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    self.mSocketClosedManualy = false;
    self.mSocketState = FLKIMStateDisconnected;
    [self.mSocket disconnect];
    return 0.f;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag elapsed:(NSTimeInterval)elapsed bytesDone:(NSUInteger)length {
    self.mSocketClosedManualy = false;
    self.mSocketState = FLKIMStateDisconnected;
    [self.mSocket disconnect];
    return 0.f;
}

#pragma mark -------------------------------socket data---------------------------------

- (void)readSocketData {
    [self.mSocket readDataToLength:FLK_PACKET_LENGTH withTimeout:-1.0 tag:FLKIMTagReadLength];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"%s----tag:%zd",__FUNCTION__,tag);
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    //NSLog(@"%s---data:%@",__FUNCTION__,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    if (tag == FLKIMTagWriteHeartBeat) {
        
    } else if (tag == FLKIMTagWritePacket) {
        
    } else if (tag == FLKIMTagReadLength) {
        //读取payload长度
        int32_t length;
        [data getBytes:&length length:sizeof(int32_t)];
        length = CFSwapInt32BigToHost(length);
        //start realy read payload contents
        [self.mSocket readDataToLength:length withTimeout:-1 tag:FLKIMTagReadPayload];
        
    } else if (tag == FLKIMTagReadPayload) {
        
        if (data.length > 0) {
            NSError *error = nil;
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&error];
            if (error || object == nil) {
                NSLog(@"read data error:%@",error.localizedDescription);
                //continue read data
                [self readSocketData];
                return;
            }
            
            //dispatch message
            [self dispatchMsg2MulticastDelegate4Data:data];
        }
        
        //continue read data
        [self readSocketData];
    }
}

#pragma mark -- filter authorization message for session key

- (void)dispatchMsg2MulticastDelegate4Data:(NSData *)aData {
    if (aData.length == 0) {
        return;
    }
    FLKPacket *pack = [FLKPacket packetWithData:aData];
    NSDictionary *msg = [pack payloadMap];
    NSString *cmd = [msg objectForKey:@"command"];
    NSString *ret = [msg objectForKey:@"result"];
    NSError *error = nil;
    if (ret.length > 0 && ![ret isEqualToString:@"ok"]) {
        NSString *reason = [msg objectForKey:@"reason"];
        if (reason.length == 0) {
            reason = @"FLK IM Received error!";
        }
        error = [NSError errorWithDomain:reason code:-1 userInfo:nil];
    }
    [self.multiDelegate didReceivedPacket:pack withCmd:cmd withError:error];
}

@end
