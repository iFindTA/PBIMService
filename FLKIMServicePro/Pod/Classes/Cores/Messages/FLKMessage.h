//
//  FLKMessage.h
//  FLKIMServicePro
//
//  Created by nanhujiaju on 2017/2/24.
//  Copyright © 2017年 nanhu. All rights reserved.
//

#import "FLKMsgBody.h"

/**
 message for im, contain send/received
 */
@interface FLKMessage : FLKMsgBase

NS_ASSUME_NONNULL_BEGIN

/**
 message id that will be uniqued for global
 */
@property (nonatomic, copy) NSString * mID;

/**
 session id for message, single-chat for received account, group-chat for group account(id)
 */
@property (nonatomic, copy) NSString * sID;

/**
 message sender account(mobile phone num and can be group id)
 */
@property (nonatomic, copy) NSString * from;

/**
 message receiver(mobile phone num and can be group id)
 */
@property (nonatomic, copy) NSString * to;

/**
 main to used in group-chat that indecate who send the message
 */
@property (nonatomic, copy) NSString * senderNick;

/**
 used in group-chat that indecate what device type sended the message
 */
@property (nonatomic, assign) FLKDeviceType sendDevice;

/**
 message body payload, @see 'FLKMsgBody.h' file
 */
@property (nonatomic, strong) FLKMsgBody * msgBody;

/**
 timestamp for sended/received point
 */
@property (nonatomic, assign) NSUInteger   timestamp;

/**
 can be readed when received one new message that send from other device
 */
@property (nonatomic, assign) BOOL isRead;

/**
 flag for whether current chat was group-chat or not
 */
@property (nonatomic, assign) BOOL isGroup;

/**
 message send state
 */
@property (nonatomic, assign) FLKMsgSendState sendState;

/**
 user custom-defined extra-datas.
 */
@property (nonatomic, copy) NSString * usrData;

#pragma mark -- create instance method --

/**
 message creator method

 @param receiver for msg
 @param body for msg
 @param group   whether group-chat
 @param gid group id if current chat was group-chat, otherwise was nil
 @return the message instance
 */
- (instancetype)initWithReceiver:(NSString *)receiver withBody:(FLKMsgBody *)body whetherGroup:(BOOL)group andGroupID:(NSString * _Nullable)gid;

@end

NS_ASSUME_NONNULL_END
