//
//  TDNetworkTrafficLog.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDNetworkTrafficLog : NSObject
@property (nonatomic,copy) NSString * path;
@property (nonatomic,copy) NSString * host;
@property (nonatomic,assign) NSInteger type;
@property (nonatomic,assign) NSInteger lineLength;
@property (nonatomic,assign) NSInteger headerLength;
@property (nonatomic,assign) NSInteger length;
@property (nonatomic,assign) NSInteger bodyLength;
@property (nonatomic, copy) NSString *startTime;
@property (nonatomic, copy) NSString *endTime;
@property (nonatomic, copy) NSString *uploadFlow;//上行流量
@property (nonatomic, copy) NSString *downFlow;//下行流量
//发生时间
@property (nonatomic,copy) NSString * occurTime;
- (void)settingOccurTime;
@end

NS_ASSUME_NONNULL_END
