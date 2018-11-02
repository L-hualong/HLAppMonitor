//
//  TDNetworkTrafficManager.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import <Foundation/Foundation.h>
#import "TDURLProtocol.h"
NS_ASSUME_NONNULL_BEGIN

@interface TDNetworkTrafficManager : NSObject

/** 所有 NSURLProtocol 对外设置接口，可以防止其他外来监控 NSURLProtocol */
@property (nonatomic, strong) NSArray *protocolClasses;


/** 单例 */
+ (TDNetworkTrafficManager *)manager;

/** 通过 protocolClasses 启动流量监控模块 */
+ (void)startWithProtocolClasses:(NSArray *)protocolClasses;
/** 仅以 DMURLProtocol 启动流量监控模块 */
+ (void)start;
/** 停止流量监控 */
+ (void)end;
@end

NS_ASSUME_NONNULL_END
