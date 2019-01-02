//
//  TDPerformanceDataManager.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/28.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *pathFlag = @"filePath";
//监控指标
typedef enum _TDMonitoringIndicators
{
    _TDMonitoringIndicatorsALL = 1,//所有的
    _TDMonitoringIndicatorsBase = 2,//基本性能数据
    _TDMonitoringIndicatorsFPS = 3,//帧率FPS
    _TDMonitoringIndicatorsNetwork = 4,//网络
    _TDMonitoringIndicatorsCaton = 5,//卡顿
    _TDMonitoringIndicatorsCrash = 6,//崩溃
} TDMonitoringIndicators;
@interface TDPerformanceDataManager : NSObject

//计数
//@property(nonatomic,assign)NSInteger logNum;

@property(nonatomic,strong)NSMutableString *normalDataStr;

+ (instancetype)sharedInstance;

- (void)normalDataStrAppendwith:(NSString*)str;

- (NSString *)getRenderWithClassName:(NSString *)className withRenderTime:(NSString *)renderTime;

- (void)writeToFileWith:(NSData *)data;

//异步获取数据,生命周期方法名
- (void)asyncExecuteClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod withUniqueIdentifier:(NSString *)uniqueIdentifier;
///**
// 定时将数据字符串写入沙盒文件
// 
// @param intervaTime 上传文件时间间隔,basicTime 基本性能数据获取间隔时间
// */
//- (void)startRecordDataIntervalTime: (NSInteger)intervaTime withBasicTime:(NSInteger)basicTime;
//定时将数据字符串写入沙盒文件 兼容之前写main分支代码
- (void)startToCollectPerformanceData;
//停止写入监控性能数据
- (void)stopUploadResourceData;
//停止监控性能
- (void)stopAppPerformanceMonitor;
//改变监控指标状态 Indicators:监控指标,isStartMonitor:监控是否开启与关闭
- (void)didChangeMonitoringIndicators: (TDMonitoringIndicators)Indicators withChangeStatus:(BOOL)isStartMonitor;
//清空txt文件
- (void)clearTxt;
//写入沙盒
- (void)writeSandbox;
@end
