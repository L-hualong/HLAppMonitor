//
//  TDPerformanceMonitor.h
//  TDTestAPP
//
//  Created by guoxiaoliang on 2018/6/22.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TDPerformanceMonitorDelegate <NSObject>
- (void)performanceMonitorCatonInformation:(NSString *)startTime withEndTime: (NSString *)endTime withCatonStackInformation: (NSString *)mainThreadBacktrace;
@end
@interface TDPerformanceMonitor : NSObject
@property(nonatomic,weak)id<TDPerformanceMonitorDelegate> delegate;
+ (instancetype)sharedInstance;

//timeInterval 耗时间隔  已毫秒为单位
- (void)startListeningTimeInterval:(double)timeInterval;
- (void)stop;
//获得 App 的 CPU占用率的方法：
- (float)getCpuUsage;
//获取当前App Memory的使用情况
- (NSUInteger)getResidentMemory;
//获取设备的物理内存
- (NSUInteger)getPhysicalMemory;
@end
