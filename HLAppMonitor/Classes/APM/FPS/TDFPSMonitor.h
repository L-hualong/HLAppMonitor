//
//  TDFPSMonitor.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TDFPSMonitorDelegate <NSObject> 
// 可选实现的方法
@optional
//fpsCount 1秒内或者大于1s(出现卡顿时),帧率次数,catonTime卡顿时长,currntTime当前时间,stackInformation:堆栈信息
- (void)fpsMonitor: (NSUInteger)fpsCount withCatonTime: (double)catonTime withCurrentTime:(NSString *)currntTime withStackInformation: (NSString *)stackInformation;
//获取帧率时间
- (void)fpsFrameCurrentTime:(NSString *)currentTime;
@end
@interface TDFPSMonitor : NSObject
@property(nonatomic,weak)id<TDFPSMonitorDelegate>delegate;
+ (instancetype)sharedMonitor;

- (void)startMonitoring;
- (void)stopMonitoring;
//获取帧率
- (double)getFPS;
@end
