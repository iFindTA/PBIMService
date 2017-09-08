//
//  FLKIMService.h
//  FLKIMServicePro
//
//  Created by nanhu on 2016/11/16.
//  Copyright © 2016年 nanhu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLKIMTypes.h"

/**
 IM service
 *
 *  Dependency:
 *  ----------Private Pods:-----------
 *  FLKNetService
 *  MulticastDelegate
 *
 *  ----------Public Pods:------------
 *  CocoaAsyncSocket
 *  -------------------------
 *
 */

NS_ASSUME_NONNULL_BEGIN

#pragma mark -- IM's Packet

@interface FLKPacket : NSObject

/**
 the payload json data
 */
@property (nonatomic, strong, readonly, getter=payloadData) NSData *payloadData;

/**
 the payload json map
 */
@property (nonatomic, strong, readonly, getter=payloadMap) NSDictionary *payloadMap;

/**
 This flag indicate the received packet's msg id
 */
@property (nonatomic, copy, readonly) NSString * mid;

/**
 factory method to create packet

 @param aMap the info of payload
 @return packet
 */
+ (FLKPacket *)packetWithMap:(NSDictionary *)aMap;

/**
 factory method to create packet

 @param aData : packet data
 @return packet
 */
+ (FLKPacket *)packetWithData:(NSData *)aData;

@end

#pragma mark -- IM's service

@interface FLKIMService : NSObject

/**
 im service current state
 */
@property (nonatomic, assign, readonly) FLKIMState mSocketState;

/**
 current session identifier
 */
@property (nonatomic, copy, nullable) NSString * curSID;

/**
 singletone mode

 @return the instance
 */
+ (FLKIMService *)shared;

/**
 dispose singletone
 */
+ (void)released;

#pragma mark -- multicast delegate
- (void)addDelegate:(id)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;
- (void)removeDelegate:(id)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;

/**
 start im engine
 */
- (void)startService;

/**
 authorzied in
 
 @param cfgs user's account and passwd and so on.
 */
- (void)authorizedWithPacket:(FLKPacket *)cfgs;

/**
 start im engine, auto login when did connected to host

 @param cfgs user's account and passwd and so on.
 */
- (void)startServiceWithAuthorization:(FLKPacket *)cfgs;

/**
 send packet method

 @param payload the msg to send to server
 */
- (void)sendPacket:(FLKPacket *)payload;

@end

@protocol FLKIMServiceDelegate <NSObject>

@optional

/**
 called when connection state changed

 @param state the state
 */
- (void)connectionDidChanged2State:(FLKIMState)state;

/**
 received a new message

 @param pack :json type dictionary
 @param cmd :type for message
 @param error :nil value for 'OK', otherwise occured an error!
 *
 *
 @example:
 command = auth;
 "first_login" = 0;
 from = 13023622337;
 result = ok;
 "session_key" = 3f4d0645cfef29fab516b5ded454dd4e36b6f44b;
 timestamp = "2016-11-21T05:46:38Z";
 to = 13023622337;
 type = "enterprise_user";
 @see more on:http://192.168.10.100/redmine/documents/63
 *
 */
- (void)didReceivedPacket:(FLKPacket *)pack withCmd:(NSString *)cmd withError:(NSError * _Nullable)error;

@end

FOUNDATION_EXPORT NSString * const FLK_IM_MSG_COMMAND_AUTHOR;

FOUNDATION_EXPORT NSString * const FLK_IM_MSG_COMMAND_MESSAGE;

NS_ASSUME_NONNULL_END
