//
//  TDNetFlowDataSource.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/18.
//

#import "TDNetFlowDataSource.h"

@implementation TDNetFlowDataSource
{
     dispatch_semaphore_t semaphore;
}
- (instancetype)init{
    self = [super init];
    if (self) {
        _httpModelArray = [NSMutableArray array];
        semaphore = dispatch_semaphore_create(1);
    }
    return self;
}
+ (TDNetFlowDataSource *)shareInstance {
    static dispatch_once_t once;
    static TDNetFlowDataSource *instance;
    dispatch_once(&once, ^{
        instance = [[TDNetFlowDataSource alloc] init];
    });
    return instance;
}

- (void)addHttpModel:(TDNetworkTrafficLog *)httpModel {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [_httpModelArray insertObject:httpModel atIndex:0];
    dispatch_semaphore_signal(semaphore);
}

- (void)clear {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [_httpModelArray removeAllObjects];
    dispatch_semaphore_signal(semaphore);
}
@end
