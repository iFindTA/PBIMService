//
//  FLKIMTypes.h
//  FLKIMServicePro
//
//  Created by nanhujiaju on 2017/2/23.
//  Copyright © 2017年 nanhu. All rights reserved.
//

#ifndef FLKIMTypes_h
#define FLKIMTypes_h

/**
 IM state(未链接、正在链接、已链接)
 */
typedef NS_ENUM(NSUInteger, FLKIMState) {
    FLKIMStateDisconnected                      =   1   <<  0,
    FLKIMStateConnecting                        =   1   <<  1,
    FLKIMStateConnected                         =   1   <<  2,
};

/**
 device type. such as iPhone/android/iPad
 */
typedef NS_ENUM(NSUInteger, FLKDeviceType) {
    FLKDeviceTypeUnknown                        =   1   <<  0,
    FLKDeviceTypePC                             =   1   <<  1,
    FLKDeviceTypeMac                            =   1   <<  2,
    FLKDeviceTypeWeb                            =   1   <<  3,
    FLKDeviceTypeiPad                           =   1   <<  4,
    FLKDeviceTypeiPhone                         =   1   <<  5,
    FLKDeviceTypeAndPad                         =   1   <<  6,//android pad
    FLKDeviceTypeAndPhone                       =   1   <<  7,//android phone
};

/**
 gender type(male/female)
 */
typedef NS_ENUM(NSUInteger, FLKGenderType) {
    FLKGenderTypeUnknown                        =   1   <<  0,
    FLKGenderTypeMale                           =   1   <<  1,
    FLKGenderTypeFemale                         =   1   <<  2,
};

/**
 message send state
 */
typedef NS_ENUM(NSUInteger, FLKMsgSendState) {
    FLKMsgSendStateFailed                       =   1   <<  0,
    FLKMsgSendStateSending                      =   1   <<  1,
    FLKMsgSendStateSuccess                      =   1   <<  2,
};

/**
 chat group type
 */
typedef NS_ENUM(NSUInteger, FLKGroupType) {
    FLKGroupTypeNormal                          =   1   <<  0,
    FLKGroupTypeWork                            =   1   <<  1,//工作组
    FLKGroupTypeDiscussion                      =   1   <<  2,//讨论组
};

/**
 speak state for chat group members, allow/forbid
 */
typedef NS_ENUM(NSUInteger, FLKSpeakState) {
    FLKSpeakStateAllow                          =   1   <<  0,
    FLKSpeakStateForbiden                       =   1   <<  1,//禁言
};

/**
 role of chat group member
 */
typedef NS_ENUM(NSUInteger, FLKMemberRole) {
    FLKMemberRoleCreator                        =   1   <<  0,//创建者 群主
    FLKMemberRoleAdmin                          =   1   <<  1,//管理员
    FLKMemberRoleMember                         =   1   <<  2,//普通÷成员
};

/**
 body type for im message
 */
typedef NS_ENUM(NSUInteger, FLKMsgBodyType) {
    FLKMsgBodyTypeUnknown                       =   1   <<  0,//未知消息类型 显示："该版本不支持查看该消息，请升级最新版！"
    FLKMsgBodyTypeFile                          =   1   <<  1,
    FLKMsgBodyTypeText                          =   1   <<  2,
    FLKMsgBodyTypeImage                         =   1   <<  3,
    FLKMsgBodyTypeAudio                         =   1   <<  4,
    FLKMsgBodyTypeVideo                         =   1   <<  5,
    FLKMsgBodyTypePrompt                        =   1   <<  6,//灰色文本提示，eg修改群昵称可能会有超链接点击（中断voip后的prompt需要点击回拨）
    FLKMsgBodyTypePreview                       =   1   <<  7,//预览, link
    FLKMsgBodyTypeVoipCall                      =   1   <<  8,//未接到的离线call(此类消息只能收到，不能发送!)
    FLKMsgBodyTypeLocation                      =   1   <<  9,
    FLKMsgBodyTypeUserState                     =   1   <<  10,//用户状态（上下线、退出、加入、禁言）
};

/***
 default was 10
 */
FOUNDATION_EXTERN unsigned int FLK_MESSAGE_MIN_LEN;
/**
 generate uniqued id, dependency 'PBKits'
 */
FOUNDATION_EXPORT NSString * generateUniqueMessageID(unsigned int len);

#endif /* FLKIMTypes_h */
