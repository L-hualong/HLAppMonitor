//
//  TDPerformanceDataManager.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/28.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDPerformanceDataManager : NSObject

//是否开始缓存
@property(nonatomic,assign)BOOL isStartCasch;

//计数
//@property(nonatomic,assign)NSInteger logNum;

@property(nonatomic,strong)NSMutableString *normalDataStr;

+ (instancetype)sharedInstance;

- (void)normalDataStrAppendwith:(NSString*)str;

- (NSString *)getRenderWithClassName:(NSString *)className withRenderTime:(NSString *)renderTime;

- (void)writeToFileWith:(NSData *)data;

//异步获取数据,生命周期方法名
- (void)asyncExecuteClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod withUniqueIdentifier:(NSString *)uniqueIdentifier;
/**
 定时将数据字符串写入沙盒文件
 
 @param intervaTime 上传文件时间间隔,basicTime 基本性能数据获取间隔时间
 */
- (void)startRecordDataIntervalTime: (NSInteger)intervaTime withBasicTime:(NSInteger)basicTime;
//定时将数据字符串写入沙盒文件 兼容之前写main分支代码
- (void)startToCollectPerformanceData;
//停止写入监控性能数据
- (void)stopUploadResourceData;
@end
