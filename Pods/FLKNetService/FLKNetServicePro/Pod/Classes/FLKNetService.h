//
//  FLKNetService.h
//  FLKNetServicePro
//
//  Created by nanhu on 2016/11/11.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import "FLKNetCore.h"

NS_ASSUME_NONNULL_BEGIN

/**
 common logic api service
 */
@interface FLKComAPI : FLKNetCore

@end

/**
 contact logic api service
 */
@interface FLKPimAPI : FLKNetCore

@end

/**
 cloud storage logic api service
 */
@interface FLKCloudAPI : FLKNetCore

@end

/**
 media(image/audio/video) logic api service
 */
@interface FLKMediaAPI : FLKNetCore

@end

#pragma mark -- Network Manager --
/**
 *
 ATS Dictionary:
 {
 NSExceptionDomains =     {
 "112.74.77.9" =         {
 NSExceptionAllowsInsecureHTTPLoads = true;
 NSExceptionMinimumTLSVersion = "TLSv1.0";
 NSExceptionRequiresForwardSecrecy = false;
 };
 };
 }
 */
@interface FLKNetworkManager : NSObject

/**
 start engine with network configuration

 @param cfg for network
 */
+ (void)startWithConfiguration:(FLKNetConfiguration *)cfg;

/**
 update authoziation info if network did load balance successful

 @param token new token
 @param key HTTP header key
 */
+ (BOOL)updateAuthoziedToken:(NSString *)token forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
