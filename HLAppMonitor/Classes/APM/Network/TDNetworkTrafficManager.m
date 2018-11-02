//
//  TDNetworkTrafficManager.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import "TDNetworkTrafficManager.h"

@interface TDNetworkTrafficManager ()

@end

@implementation TDNetworkTrafficManager

#pragma mark - Public

+ (TDNetworkTrafficManager *)manager {
    static TDNetworkTrafficManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[TDNetworkTrafficManager alloc] init];
    });
    return manager;
}

+ (void)startWithProtocolClasses:(NSArray *)protocolClasses {
    [self manager].protocolClasses = protocolClasses;
    [TDURLProtocol start];
}

+ (void)start {
    [self manager].protocolClasses = @[[TDURLProtocol class]];
    [TDURLProtocol start];
}

+ (void)end {
    [TDURLProtocol end];
}

@end
