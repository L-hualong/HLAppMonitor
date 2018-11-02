//
//  TDNetFlowDataSource.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/18.
//

#import <Foundation/Foundation.h>
#import "TDNetworkTrafficLog.h"
NS_ASSUME_NONNULL_BEGIN

@interface TDNetFlowDataSource : NSObject

@property (nonatomic, assign) long long uploadFlow;//上行流量
@property (nonatomic, assign) long long downFlow;//下行流量

+ (TDNetFlowDataSource *)shareInstance;

- (void)addHttpModel:(TDNetworkTrafficLog *)httpModel;
- (void)setNetworkTrafficData:(long long)uploadData withDownFlow:(long long)downData;
- (void)clear;
@end

NS_ASSUME_NONNULL_END
