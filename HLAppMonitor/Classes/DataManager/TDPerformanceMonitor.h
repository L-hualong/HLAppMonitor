//
//  TDPerformanceMonitor.h
//  TDTestAPP
//
//  Created by guoxiaoliang on 2018/6/22.
//  Copyright © 2018 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDPerformanceMonitor : NSObject
//堆栈信息
@property(nonatomic ,strong)NSMutableArray *backtraceLoggerArray;
+ (instancetype)sharedInstance;
- (void)start;
- (void)stop;
//获得 App 的 CPU占用率的方法：
- (float)getCpuUsage;
//获取当前App Memory的使用情况
- (NSUInteger)getResidentMemory;
//获取设备的物理内存
- (NSUInteger)getPhysicalMemory;
@end
