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


@property (nonatomic, strong) NSMutableArray<TDNetworkTrafficLog *> *httpModelArray;

+ (TDNetFlowDataSource *)shareInstance;

- (void)addHttpModel:(TDNetworkTrafficLog *)httpModel;

- (void)clear;
@end

NS_ASSUME_NONNULL_END
