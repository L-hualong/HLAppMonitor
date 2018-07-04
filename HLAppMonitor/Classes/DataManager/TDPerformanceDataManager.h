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
@property(nonatomic,assign)NSInteger logNum;

@property(nonatomic,strong)NSMutableString *normalDataStr;
//控制器停留数据
@property(nonatomic,strong)NSMutableArray *pageDataArray;

+ (instancetype)sharedInstance;

//异步获取数据,生命周期方法名
- (void)syncExecuteClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod;
//写入沙盒里
- (void)recordDataIntervalTime: (NSInteger)intervaTime;
@end
