//
//  TDSystemCPU.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDSystemCPU.h"
#import <mach/vm_map.h>
#import <mach/mach_host.h>
#import <mach/processor_info.h>

static NSArray * previousCPUInfo;


/// processor_info_array_t结构数据偏移位
typedef NS_ENUM(NSInteger, TDCPUInfoOffsetState)
{
    TDCPUInfoOffsetStateSystem = 0,
    TDCPUInfoOffsetStateUser = 1,
    TDCPUInfoOffsetStateNice = 2,
    TDCPUInfoOffsetStateIdle = 3,
    TDCPUInfoOffsetStateMask = 4,
};

/// cpu信息结构体
static NSUInteger TDSystemCPUInfoCount = 4;
typedef struct TDSystemCPUInfo {
    NSUInteger system;  ///< 系统态占用。
    NSUInteger user;    ///< 用户态占用。
    NSUInteger nice;    ///< nice加权的用户态占用。
    NSUInteger idle;    ///< 空闲占用
} TDSystemCPUInfo;

/// 结构体构造转换
static inline TDSystemCPUInfo __TDSystemCPUInfoMake(NSUInteger system, NSUInteger user, NSUInteger nice, NSUInteger idle) {
    return (TDSystemCPUInfo){ system, user, nice, idle };
}

static inline NSString * TDStringFromSystemCPUInfo(TDSystemCPUInfo systemCPUInfo) {
    return [NSString stringWithFormat: @"%lu-%lu-%lu-%lu", systemCPUInfo.system, systemCPUInfo.user, systemCPUInfo.nice, systemCPUInfo.idle];
}

static inline TDSystemCPUInfo TDSystemCPUInfoFromString(NSString * string) {
    NSArray * infos = [string componentsSeparatedByString: @"-"];
    if (infos.count == TDSystemCPUInfoCount) {
        return __TDSystemCPUInfoMake(
                                      [infos[TDCPUInfoOffsetStateSystem] integerValue],
                                      [infos[TDCPUInfoOffsetStateUser] integerValue],
                                      [infos[TDCPUInfoOffsetStateNice] integerValue],
                                      [infos[TDCPUInfoOffsetStateIdle] integerValue]);
    }
    return (TDSystemCPUInfo){ 0 };
}

@interface TDSystemCPU ()
@property (nonatomic, assign) double systemRatio;
@property (nonatomic, assign) double userRatio;
@property (nonatomic, assign) double niceRatio;
@property (nonatomic, assign) double idleRatio;

@property (nonatomic, copy) NSArray<NSString *> * cpuInfos;
@end
@implementation TDSystemCPU


- (TDSystemCPUUsage)currentUsage {
    return [self generateSystemCpuUsageWithCpuInfos: [self generateCpuInfos]];
}

- (NSArray<NSString *> *)generateCpuInfos {
    natural_t cpu_processor_count = 0;
    natural_t cpu_processor_info_count = 0;
    processor_info_array_t cpu_processor_infos = NULL;
    
    kern_return_t result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpu_processor_count, &cpu_processor_infos, &cpu_processor_info_count);
    if ( result == KERN_SUCCESS && cpu_processor_infos != NULL ) {
        NSMutableArray * infos = [NSMutableArray arrayWithCapacity: cpu_processor_count];
        for (int idx = 0; idx < cpu_processor_count; idx++) {
            NSInteger offset = TDCPUInfoOffsetStateMask * idx;
            
            double system, user, nice, idle;
            if (previousCPUInfo.count > idx) {
                TDSystemCPUInfo previousInfo = TDSystemCPUInfoFromString(previousCPUInfo[idx]);
                system = cpu_processor_infos[offset + TDCPUInfoOffsetStateSystem] - previousInfo.system;
                user = cpu_processor_infos[offset + TDCPUInfoOffsetStateUser] - previousInfo.user;
                nice = cpu_processor_infos[offset + TDCPUInfoOffsetStateNice] - previousInfo.nice;
                idle = cpu_processor_infos[offset + TDCPUInfoOffsetStateIdle] - previousInfo.idle;
            } else {
                system = cpu_processor_infos[offset + TDCPUInfoOffsetStateSystem];
                user = cpu_processor_infos[offset + TDCPUInfoOffsetStateUser];
                nice = cpu_processor_infos[offset + TDCPUInfoOffsetStateNice];
                idle = cpu_processor_infos[offset + TDCPUInfoOffsetStateIdle];
            }
            TDSystemCPUInfo info = __TDSystemCPUInfoMake( system, user, nice, idle );
            [infos addObject: TDStringFromSystemCPUInfo(info)];
        }
        
        vm_size_t cpuInfoSize = sizeof(int32_t) * cpu_processor_count;
        vm_deallocate(mach_task_self_, (vm_address_t)cpu_processor_infos, cpuInfoSize);
        return infos;
    }
    return nil;
}

- (TDSystemCPUUsage)generateSystemCpuUsageWithCpuInfos: (NSArray<NSString *> *)cpuInfos {
    if (cpuInfos.count == 0) { return (TDSystemCPUUsage){ 0 }; }
    double system = 0, user = 0, nice = 0, idle = 0;
    for (NSString * cpuInfoString in cpuInfos) {
        TDSystemCPUInfo cpuInfo = TDSystemCPUInfoFromString(cpuInfoString);
        system += cpuInfo.system;
        user += cpuInfo.user;
        nice += cpuInfo.nice;
        idle += cpuInfo.idle;
    }
    system /= cpuInfos.count;
    user /= cpuInfos.count;
    nice /= cpuInfos.count;
    idle /= cpuInfos.count;
    
    double total = system + user + nice + idle;
    return (TDSystemCPUUsage){
        .system = system / total,
        .user = user / total,
        .nice = nice / total,
        .idle = idle / total,
    };
}

@end
