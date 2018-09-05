//
//  TDResourceMonitor.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RESOURCE_MONITOR [TDResourceMonitor new]
typedef NS_ENUM(NSInteger, TDResourceMonitorType)
{
    TDResourceMonitorTypeDefault = (1 << 2) | (1 << 3),
    TDResourceMonitorTypeSystemCpu = 1 << 0,   ///<    监控系统CPU使用率，优先级低
    TDResourceMonitorTypeSystemMemory = 1 << 1,    ///<    监控系统内存使用率，优先级低
    TDResourceMonitorTypeApplicationCpu = 1 << 2,  ///<    监控应用CPU使用率，优先级高
    TDResourceMonitorTypeApplicationMemoty = 1 << 3,   ///<    监控应用内存使用率，优先级高
};
/*!
 *  @brief  硬件资源监控
 */
@interface TDResourceMonitor : NSObject

+ (instancetype)monitorWithMonitorType: (TDResourceMonitorType)monitorType;
- (void)startMonitoring;
- (void)stopMonitoring;
@end
