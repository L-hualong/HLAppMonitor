//
//  TDDispatchOperation.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TDDispatchOperation;
typedef void(^TDCancelableBlock)(TDDispatchOperation * operation);

/*!
 *  @brief  派发任务封装
 */
@interface TDDispatchOperation : NSObject

@property (nonatomic, readonly) BOOL isCanceled;
@property (nonatomic, readonly) dispatch_queue_t queue;

+ (instancetype)dispatchOperationWithBlock: (dispatch_block_t)block;
+ (instancetype)dispatchOperationWithBlock: (dispatch_block_t)block inQoS: (NSQualityOfService)qos;

+ (instancetype)dispatchOperationWithCancelableBlock:(TDCancelableBlock)block;
+ (instancetype)dispatchOperationWithCancelableBlock:(TDCancelableBlock)block inQos: (NSQualityOfService)qos;

- (void)start;
- (void)cancel;
@end
