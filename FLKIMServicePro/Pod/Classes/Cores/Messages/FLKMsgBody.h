//
//  FLKMsgBody.h
//  FLKIMServicePro
//
//  Created by nanhujiaju on 2017/2/24.
//  Copyright © 2017年 nanhu. All rights reserved.
//

#import "FLKMsgBase.h"

@interface FLKMsgBody : FLKMsgBase

/**
 message body type, see in 'FLKIMType.h' file
 */
@property (nonatomic, assign, readonly) FLKMsgBodyType bodyType;

@end
