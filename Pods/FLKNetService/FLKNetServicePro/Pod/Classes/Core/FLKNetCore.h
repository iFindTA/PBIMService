//
//  FLKNetCore.h
//  FLKNetServicePro
//
//  Created by nanhu on 2016/11/28.
//  Copyright © 2016年 nanhu. All rights reserved.
//

/**
 Engine for net request!
 *
 *  Dependicy Library:
 *  <AFNetworking>
 *  <SVProgressHUD>
 *  <RealReachability>
 *  <GCDMulticastDelegate>
 *  <CommonCrypto~1.1Pod>
 *
 @return Network Engine
 */
#import <AFNetworking/AFNetworking.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <RealReachability/RealReachability.h>
#import <MulticastDelegate/GCDMulticastDelegate.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark -- network configuration --

/**
 configuration for network core logic.
 */
@interface FLKNetConfiguration : NSObject

/**
 the domain(or http://host:port) for debug mode, nil for use default domain of flk
 */
@property (nonatomic, copy, nullable) NSString *debugDomain;

/**
 the domain(or http://host:port) for release mode. couldn't be nil! default is flk's release domain.
 */
@property (nonatomic, copy, nonnull) NSString *releaseDomain;

/**
 the domain for ping. default is www.baidu.com
 */
@property (nonatomic, copy, nullable) NSString *pingDomain;

/**
 the interval for timeout request 15~60. default is 30"(sec).
 */
@property (nonatomic, assign) CGFloat timeoutInterval;

/**
 get the default configuration for network core logic

 @return the instance of configuration
 */
+ (FLKNetConfiguration *)defaultConfiguration;

@end

/**
 network state enumerator
 */
typedef NS_ENUM(NSUInteger, FLKNetState) {
    FLKNetStateUnknown                      =   1   <<  0,
    FLKNetStateUnavaliable                  =   1   <<  1,
    FLKNetStateViaWWAN                      =   1   <<  2,
    FLKNetStateViaWiFi                      =   1   <<  3
};

#pragma mark -- network core logics

@interface FLKNetCore : AFHTTPSessionManager

/**
 current net state
 */
@property (nonatomic, assign, readonly) FLKNetState netState;

/**
 network balance configure info maps
 accessServers: 消息服务器地址列表，客户端与服务器之间用TLS连接交互
 multimediaServers: 多媒体服务器地址列表，客户端与服务器之间通过HTTPS交互
 cloudServers: 网盘服务器地址列表，客户端与服务器之间通过HTTPS交互
 pimServers: 通讯录同步服务器列表，客户端与服务器之间通过HTTPS交互
 serviceServers: 其他接口服务器地址列表，该服务器提供如注册、邮箱绑定、密码找回等服务，客户端与服务器直接通过HTTPS交互
 */
@property (nonatomic, strong, readonly) NSDictionary *balanceMap;

/**
 setup network module with configuration.

 @param config the network's setting.
 */
+ (void)setupWithConfiguration:(FLKNetConfiguration *)config;

/**
 singletone mode
 
 @return the instance
 */
+ (instancetype)shared;

/**
 dispose memory source
 */
+ (void)released;

#pragma mark -- HTTP1.1 Basic/Digest Authorize

/**
 HTTP/1.1 Basic Author
 
 @param username usr name
 @param password usr pwd
 */
- (void)setAuthorizationWithUsername:(NSString *)username password:(NSString *)password;

/**
 HTTP/1.1 Basic Author

 @param info :info description
 @param key :HTTP Header key
 */
- (void)setAuthorization:(NSString *)info forKey:(NSString *)key;

/**
 wether net enabled now
 
 @return result
 */
- (BOOL)netvalid;

#pragma mark -- Cancel Request Method --

/**
 cancel request for path
 
 @param aClass the class
 */
- (void)cancelRequestForClass:(nullable Class)aClass;

/**
 cancel all request in the operation queue
 */
- (void)cancelAllRequest;

#pragma mark -- network balance

/**
 load network balance.
 will use local cache when retry failed for maxium counts.
 */
- (void)loadNetworkBalance;

/**
 generate host(domain:port) from balance map

 @param key server identifier, such as pim/cloud etc.
 @return the configures for api server
 */
- (NSDictionary * _Nullable)assembleConfigures4ServerKey:(NSString *)key;

#pragma mark -- multicast delegate

/**
 add delegate for network core logic

 @param delegate the weak delegate reference
 @param delegateQueue delegate callback queue
 */
- (void)addDelegate:(id)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;

#pragma mark -- public request methods --

/**
 Request method throw GET

 @param path uri path for Restful Api
 @param params for the request
 @param cls for the request launched by
 @param view that should be disabled userInterface action while in requesting
 @param hud whether show hud while in requesting
 @param downProgress the progress
 @param success response
 @param failure response
 */
- (void)GET:(NSString *)path parameters:(nullable id)params class:(Class _Nullable)cls view:(UIView * _Nullable)view hudEnable:(BOOL)hud progress:(void (^_Nullable)(NSProgress * _Nonnull progress))downProgress success:(void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObj))success failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure;

/**
 Normal request method throw POST

 @param path the uri path for Restful Api
 @param params for the request
 @param cls for the request launched by
 @param view that should be disabled userInterface action while in requesting
 @param success response
 @param failure response
 */
- (void)POST:(NSString *)path parameters:(nullable id)params class:(Class _Nullable)cls view:(UIView * _Nullable)view success:(void (^)(NSURLSessionDataTask *task, id _Nullable responseObj))success failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError *error))failure;

/**
 Upload datas method

 @param path the uri path for Restful Api
 @param params for the request
 @param cls for the request launched by
 @param view that should be disabled userInterface action while in requesting
 @param block the data for uploading
 @param uploadProgress for current request
 @param success response
 @param failure response
 */
- (void)POST:(NSString *)path parameters:(id)params class:(Class _Nullable)cls view:(UIView * _Nullable)view constructingBodyWithBlock:(void (^)(id<AFMultipartFormData> _Nonnull formData))block progress:(void (^)(NSProgress * _Nonnull progress))uploadProgress success:(void (^)(NSURLSessionDataTask * _Nonnull task, id _Nullable responsObj))success failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error))failure;

/**
 Request method throw PUT
 
 @param path the uri path for Restful Api
 @param params for the request
 @param cls for the request launched by
 @param view request current view
 @param success response
 @param failure response
 */
- (void)PUT:(NSString *)path parameters:(nullable id)params class:(Class _Nullable)cls view:(UIView * _Nullable)view success:(void (^)(NSURLSessionDataTask * task,id _Nullable responseObj))success failure:(void (^)(NSURLSessionDataTask * _Nullable task, NSError * error))failure;

@end

@protocol FLKNetworkCoreDelegate <NSObject>

@optional

/**
 network state did changed callback
 
 @param aState the new state of current network
 @param preState the previous state of current network
 */
- (void)networkStateDidChangeTo:(FLKNetState)aState withPrevious:(FLKNetState)preState;

/**
 did load balance

 @param error null for successfull! otherwise was failed.
 */
- (void)didLoadBalanceWithError:(NSError * _Nullable)error;

@end

/**
 * extern network configuration var
 */
FOUNDATION_EXPORT NSString * const FLK_NETSERVICE_DOMAIN_DEBUG;

FOUNDATION_EXPORT NSString * const FLK_NETSERVICE_DOMAIN_RELEASE;

FOUNDATION_EXPORT NSString * const FLK_NETSERVICE_DOMAIN_PING;

FOUNDATION_EXPORT NSString * const FLK_NETSERVICE_REQUEST_TIME_OUT;

/**
 * extern balance map key
 */
FOUNDATION_EXTERN NSString * const FLK_SERVER_4_COMMON_API_KEY;
FOUNDATION_EXTERN NSString * const FLK_SERVER_4_PIM_API_KEY;
FOUNDATION_EXTERN NSString * const FLK_SERVER_4_CLOUD_API_KEY;
FOUNDATION_EXTERN NSString * const FLK_SERVER_4_MEDIA_API_KEY;

NS_ASSUME_NONNULL_END
