//
//  TDDispatchQperation.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDDispatchOperation.h"
#import "TDDispatchAsync.h"

#ifndef TDDispatchAsync_m
#define TD_INLINE static inline
#endif

#define TD_FUNCTION_OVERLOAD __attribute__((overloadable))


TD_INLINE TD_FUNCTION_OVERLOAD void __TDLockExecute(dispatch_block_t block, dispatch_time_t threshold);

TD_INLINE TD_FUNCTION_OVERLOAD void __TDLockExecute(dispatch_block_t block) {
    __TDLockExecute(block, dispatch_time(DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER));
}

TD_INLINE TD_FUNCTION_OVERLOAD void __TDLockExecute(dispatch_block_t block, dispatch_time_t threshold) {
    if (block == nil) { return ; }
    static dispatch_semaphore_t TD_queue_semaphore;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        TD_queue_semaphore = dispatch_semaphore_create(0);
    });
    dispatch_semaphore_wait(TD_queue_semaphore, threshold);
    block();
    dispatch_semaphore_signal(TD_queue_semaphore);
}


@interface TDDispatchOperation ()

@property (nonatomic, assign) BOOL isCanceled;
@property (nonatomic, assign) BOOL isExcuting;
@property (nonatomic, assign) dispatch_queue_t queue;
@property (nonatomic, assign) dispatch_queue_t (*asyn)(dispatch_block_t);
@property (nonatomic, copy) TDCancelableBlock cancelableBlock;

@end

@implementation TDDispatchOperation

+ (instancetype)dispatchOperationWithBlock: (dispatch_block_t)block {
    return [self dispatchOperationWithCancelableBlock: ^(TDDispatchOperation *operation) {
        if (!operation.isCanceled) {
            block();
        }
    } inQos: NSQualityOfServiceDefault];
}

+ (instancetype)dispatchOperationWithBlock: (dispatch_block_t)block inQoS: (NSQualityOfService)qos {
    return [self dispatchOperationWithCancelableBlock: ^(TDDispatchOperation *operation) {
        if (!operation.isCanceled) {
            block();
        }
    } inQos: qos];
}

+ (instancetype)dispatchOperationWithCancelableBlock:(TDCancelableBlock)block {
    return [self dispatchOperationWithCancelableBlock: block inQos: NSQualityOfServiceDefault];
}

+ (instancetype)dispatchOperationWithCancelableBlock:(TDCancelableBlock)block inQos: (NSQualityOfService)qos {
    return [[self alloc] initWithBlock: block inQos: qos];
}

- (instancetype)initWithBlock: (TDCancelableBlock)block inQos: (NSQualityOfService)qos {
    if (block == nil) { return nil; }
    if (self = [super init]) {
        switch (qos) {
            case NSQualityOfServiceUserInteractive:
                self.asyn = TDDispatchQueueAsyncBlockInUserInteractive;
                break;
            case NSQualityOfServiceUserInitiated:
                self.asyn = TDDispatchQueueAsyncBlockInUserInitiated;
                break;
            case NSQualityOfServiceDefault:
                self.asyn = TDDispatchQueueAsyncBlockInDefault;
                break;
            case NSQualityOfServiceUtility:
                self.asyn = TDDispatchQueueAsyncBlockInUtility;
                break;
            case NSQualityOfServiceBackground:
                self.asyn = TDDispatchQueueAsyncBlockInBackground;
                break;
            default:
                self.asyn = TDDispatchQueueAsyncBlockInDefault;
                break;
        }
        self.cancelableBlock = block;
    }
    return self;
}

- (void)dealloc {
    [self cancel];
}

- (void)start {
    __TDLockExecute(^{
        self.queue = self.asyn(^{
            self.cancelableBlock(self);
            self.cancelableBlock = nil;
        });
        self.isExcuting = YES;
    });
}

- (void)cancel {
    __TDLockExecute(^{
        self.isCanceled = YES;
        if (!self.isExcuting) {
            self.asyn = NULL;
            self.cancelableBlock = nil;
        }
    });
}
@end
