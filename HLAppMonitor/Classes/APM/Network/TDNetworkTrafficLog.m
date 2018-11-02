//
//  TDNetworkTrafficLog.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import "TDNetworkTrafficLog.h"

@implementation TDNetworkTrafficLog
- (void)settingOccurTime {
    self.occurTime = [self getCurrntTime];
}
- (NSString *)getCurrntTime { 
    long long curt = [self currentTime];
    NSString *currntTime = [NSString stringWithFormat:@"%lld",curt];
    return currntTime;
}
//获取当前时间
- (long long)currentTime {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970] * 1000;
    long long dTime = [[NSNumber numberWithDouble:time] longLongValue]; 
    return dTime;
}
@end
