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
    long long uploadFlowTotal;//上行流量
    long long downFlowTotal;//下行流量
}
- (instancetype)init{
    self = [super init];
    if (self) {
        //_httpModelArray = [NSMutableArray array];
        _uploadFlow = 0;
        _downFlow = 0;
        uploadFlowTotal = 0;
        downFlowTotal = 0;
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
- (void)setNetworkTrafficData:(long long)uploadData withDownFlow:(long long)downData {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    uploadFlowTotal += uploadData;
    downFlowTotal += downData;
    dispatch_semaphore_signal(semaphore);
}
- (void)addHttpModel:(TDNetworkTrafficLog *)httpModel {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   // [_httpModelArray insertObject:httpModel atIndex:0];
    dispatch_semaphore_signal(semaphore);
}

- (void)clear {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    uploadFlowTotal = 0;
    downFlowTotal = 0;
    dispatch_semaphore_signal(semaphore);
}
- (long long)uploadFlow {
    return uploadFlowTotal;
}
- (long long)downFlow {
    return downFlowTotal;
}
@end
