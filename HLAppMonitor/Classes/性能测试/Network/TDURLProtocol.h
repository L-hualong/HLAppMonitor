//
//  TDURLProtocol.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
//网络请求类型
typedef enum: NSInteger {
    TDNetworkTrafficDataTypeRequest = 0,
    TDNetworkTrafficDataTypeResponse = 1,
} TDNetworkTrafficDataType;
@interface TDURLProtocol : NSURLProtocol

/** 开启网络请求拦截 */
+ (void)start;
/** 停止网络请求拦截 */
+ (void)end;
@end

NS_ASSUME_NONNULL_END
