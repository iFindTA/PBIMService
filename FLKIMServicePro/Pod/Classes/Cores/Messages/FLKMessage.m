//
//  FLKMessage.m
//  FLKIMServicePro
//
//  Created by nanhujiaju on 2017/2/24.
//  Copyright © 2017年 nanhu. All rights reserved.
//

#import "FLKMessage.h"
#import <PBKits/PBKits.h>

unsigned int FLK_MESSAGE_MIN_LEN                          =   10;

static NSDateFormatter * dataFormatter() {
    __block NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return formatter;
}

NSString * generateUniqueMessageID(unsigned int len) {
    len = (len < FLK_MESSAGE_MIN_LEN ? FLK_MESSAGE_MIN_LEN:len);
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970];
    NSString *random = [NSString pb_randomString4Length:len];
    random = [random pb_MD5Hash];
    return PBFormat(@"%@%f", random, interval);
}

@implementation FLKMessage

- (instancetype)initWithReceiver:(NSString *)receiver withBody:(FLKMsgBody *)body whetherGroup:(BOOL)group andGroupID:(NSString * _Nullable)gid {
    self = [super init];
    if (self) {
        NSAssert(receiver.length > 0 && body != nil, @"message receiver's address can't be nil!");
        if (group) {
            NSAssert(gid.length > 0, @"can not send msg to null group id!");
        }
        self.msgBody = body;
        self.to = receiver.copy;
        self.from = @"current account";//TODO: replace for local authorized-account
        self.isGroup = group;
        self.sID = (group?gid.copy:receiver.copy);
        self.mID = generateUniqueMessageID(FLK_MESSAGE_MIN_LEN);
    }
    return self;
}

@end
