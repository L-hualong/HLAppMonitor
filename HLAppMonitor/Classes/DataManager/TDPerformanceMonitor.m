//
//  TDPerformanceMonitor.m
//  TDTestAPP
//
//  Created by guoxiaoliang on 2018/6/22.
//  Copyright © 2018 Apple. All rights reserved.
//

#import "TDPerformanceMonitor.h"
#import <mach/mach.h>
#import <mach/task_info.h>
#import<assert.h>
#import <CoreMIDI/CoreMIDI.h>
//#import <CrashReporter/CrashReporter.h>
#import <execinfo.h>
#import "TDBacktraceLogger.h"

#import "sys/utsname.h"
#import <ifaddrs.h>
#import <AdSupport/AdSupport.h>
#include <sys/sysctl.h>
#define BACKTRACE_SIZE   16 
@interface TDPerformanceMonitor ()

@end

@implementation TDPerformanceMonitor
{
    //耗时间隔
    double timeInterval;
    int timeoutCount;
    CFRunLoopObserverRef observer;
     NSMutableArray *_backtrace;
    @public
    dispatch_semaphore_t semaphore;
    CFRunLoopActivity activity;
}

+ (instancetype)sharedInstance
{
    static TDPerformanceMonitor * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TDPerformanceMonitor alloc] init];
    });
    return instance;
}
//获得 App 的 CPU占用率的方法：
- (float)getCpuUsage

{
    kern_return_t           kr = { 0 };
    task_info_data_t        tinfo = { 0 };
    mach_msg_type_number_t  task_info_count = TASK_INFO_MAX;
    
    kr = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    task_basic_info_t       basic_info = { 0 };
    thread_array_t          thread_list = { 0 };
    mach_msg_type_number_t  thread_count = { 0 };
    
    thread_info_data_t      thinfo = { 0 };
    thread_basic_info_t     basic_info_th = { 0 };
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads( mach_task_self(), &thread_list, &thread_count );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    long    tot_sec = 0;
    long    tot_usec = 0;
    float   tot_cpu = 0;
    
    for ( int i = 0; i < thread_count; i++ )
    {
        mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
        
        kr = thread_info( thread_list[i], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count );
        if ( KERN_SUCCESS != kr )
            return 0.0f;
        
        basic_info_th = (thread_basic_info_t)thinfo;
        if ( 0 == (basic_info_th->flags & TH_FLAGS_IDLE) )
        {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }
    
    kr = vm_deallocate( mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t) );
    if ( KERN_SUCCESS != kr )
        return 0.0f;
    
    return tot_cpu * 100.; // CPU 占用百分比
    
}

//获取当前App Memory的使用情况
- (NSUInteger)getResidentMemory

{
    
    struct mach_task_basic_info info;
    
    mach_msg_type_number_t count =MACH_TASK_BASIC_INFO_COUNT;
    
    int r = task_info(mach_task_self(),MACH_TASK_BASIC_INFO, (task_info_t)& info, & count);
    
    if (r == KERN_SUCCESS)
        
    {
        //info.resident_size >> 10;//10-KB   20-MB   
        return info.resident_size;
        
    }
    
    else
        
    {
        
        return -1;
        
    }
    
}
//获取设备的物理内存
- (NSUInteger)getPhysicalMemory {
    
    NSUInteger memory =  [NSProcessInfo processInfo].physicalMemory;
    return memory;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    TDPerformanceMonitor *monitor = (__bridge TDPerformanceMonitor*)info;
    
    // 记录状态值
    monitor->activity = activity;
    // 发送信号
    dispatch_semaphore_t semaphore = monitor->semaphore;
    //增加信号量加1（发送一个信号量信号）,
    dispatch_semaphore_signal(semaphore);
}
- (long long)currentTime {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970] * 1000;
    long long dTime = [[NSNumber numberWithDouble:time] longLongValue]; 
    return dTime;//[[NSDate date] timeIntervalSince1970] * 1000;
}
//timeInterval 耗时间隔  已毫秒为单位
- (void)startListeningTimeInterval:(double)timeInterval
{
    if (observer)
        return;
    self->timeInterval = timeInterval;
    // 创建信号用初始值创建一个信号量
    semaphore = dispatch_semaphore_create(0);
    /* 注册RunLoop状态观察,CFRunLoopObserver提供了一种通用的方法来在运行循环中的不同点处接收回调,每个运行循环观察者一次只能在一个运行循环中注册，尽管它可以添加到该运行循环内的多个运行循环模式中。
     allocator: 分配器用于为新对象分配内存。通过NULL或使用当前的默认分配器。kCFAllocatorDefault
     activities:一组标识标识运行循环的活动阶段，在此期间应该调用观察者。查看阶段列表。要让运行循环中的多个阶段调用观察器
     kCFRunLoopEntry:入口的循环运行,在进入事件处理循环之前。此活动为每个调用发生一次CFRunLoopRun和CFRunLoopRunInMode。
     kCFRunLoopBeforeTimers: 在事件处理循环定时器处理之前
     kCFRunLoopBeforeSources:在事件处理循环之前处理来源。
     kCFRunLoopAfterWaiting:运行循环唤醒后，但在处理唤醒它的事件之前，在事件处理循环内部。只有在当前循环中运行循环实际上进入休眠状态时才会发生此活动
     kCFRunLoopAllActivities:所有事件
     repeats:一个标志，用于标识观察者是否应该只通过运行循环调用一次或每次
     order:指示运行循环观察者处理顺序的优先级索引。当在给定的运行循环模式中将多个运行循环观察器安排在同一活动阶段中时，观察者按照此参数的升序进行处理。通过0，除非有其他理由。
     callout:观察者运行时调用的回调函数
     context:保存运行循环观察者的上下文信息的结构。
     */
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                            kCFRunLoopAllActivities,
                                                            YES,
                                                            0,
                                                            &runLoopObserverCallBack,
                                                            &context);
    //将观察者添加到主线程runloop的common模式下的观察中
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    /**
     dispatch_queue_t serialQueue = dispatch_queue_create("serial", DISPATCH_QUEUE_SERIAL);
     self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, serialQueue);
     dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC, 0);
     
     __block int8_t chokeCount = 0;
     dispatch_semaphore_t t2 = dispatch_semaphore_create(0);
     dispatch_source_set_event_handler(self.timer, ^{
     if (config->activity == kCFRunLoopBeforeWaiting) {
     static BOOL ex = YES;
     if (ex == NO) {
     chokeCount ++;
     if (chokeCount > 40) {
     NSLog(@"差不多卡死了");
     dispatch_suspend(self.timer);
     return ;
     }
     NSLog(@"卡顿了");
     return ;
     }
     dispatch_async(dispatch_get_main_queue(), ^{
     ex = YES;
     dispatch_semaphore_signal(t2);
     });
     BOOL su = dispatch_semaphore_wait(t2, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
     if (su != 0) {
     ex = NO;
     };
     }
     });

     */
    
  //并行队列
    dispatch_queue_t queue = dispatch_queue_create("TDPerformanceMonitorQueue", DISPATCH_QUEUE_CONCURRENT);
    //创建子线程监控
  //  __weak typeof(self) weakSelf = self;
    dispatch_async(queue, ^{
         //子线程开启一个持续的loop用来进行监控
        while (YES)
        {
            // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)//减小信号量（等待一个信号量信号）
            long st = dispatch_semaphore_wait(self->semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
            //st不等于0表示没有成功唤醒,指导超时才会执行以下代码
            if (st != 0)
            {
                if (!self->observer)
                {
                    self->timeoutCount = 0;
                    self->semaphore = 0;
                    self->activity = 0;
                    return;
                }
                //RunLoop 即将触发 Source0 (非port) 回调。kCFRunLoopAfterWaiting, 即停止等待（被唤醒）
                if (self->activity == kCFRunLoopBeforeSources || self->activity == kCFRunLoopAfterWaiting)
                {
                    if (++self->timeoutCount < (self ->timeInterval / 50))
                        continue;
                    
//                    TDLog(@"好像有点儿卡哦");
//                      TDLOG_MAIN // 打印主线程调用栈， TDLOG 打印当前线程，TDLOG_ALL 打印所有线程
                    if (self.delegate && [self.delegate respondsToSelector:@selector(performanceMonitorCatonInformation:withEndTime:withCatonStackInformation:)]) {
                        NSString *threamData =  [TDBacktraceLogger td_backtraceOfMainThread];
                        [self.delegate performanceMonitorCatonInformation:@"" withEndTime:@"" withCatonStackInformation:threamData];
                    }
                }
            }
            self->timeoutCount = 0;
        }
    });
}

- (void)stop
{
    if (!observer)
        return;
    
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    CFRelease(observer);
    observer = NULL;
}
//记录堆栈信息
- (void)recodeLogger {
    //获取堆栈信息
   NSString *threamData =  [TDBacktraceLogger td_backtraceOfMainThread];
//    [self.backtraceLoggerArray appendString:threamData];
  //  NSLog(@"recodeLogger=%@",self.backtraceLoggerArray);
}
- (void)logStack{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    _backtrace = [NSMutableArray arrayWithCapacity:frames];
    for ( i = 0 ; i < frames ; i++ ){
        [_backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
//    TDLog(@"backtrace = %@\n",_backtrace);
}
void dump(void)  
{  
    int j, nptrs;  
    void *buffer[BACKTRACE_SIZE];  
    char **strings;  
    
    nptrs = backtrace(buffer, BACKTRACE_SIZE);  
    printf("dump----------\n");  
    printf("backtrace() returned %d addresses\n", nptrs);  
    
    strings = backtrace_symbols(buffer, nptrs);  
    if (strings == NULL) {  
        perror("backtrace_symbols");  
        exit(EXIT_FAILURE);  
    }  
    
    for (j = 0; j < nptrs; j++)  
        printf("  [%02d] %s\n", j, strings[j]);  
    
    free(strings);  
}  
//获取电量
- (void)getElectricity {
    /*
     UIDeviceBatteryStateUnknown,
     
     UIDeviceBatteryStateUnplugged, // on battery, discharging
     
     UIDeviceBatteryStateCharging, // plugged in, less than100%
     
     UIDeviceBatteryStateFull, // plugged in, at 100%
     */
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
    [[NSNotificationCenter defaultCenter]
     
     addObserverForName:UIDeviceBatteryLevelDidChangeNotification
     
     object:nil queue:[NSOperationQueue mainQueue]
     
     usingBlock:^(NSNotification *notification) {
         
         // Level has changed
         
         NSLog(@"Battery Level Change");
         
         NSLog(@"电池电量：%f%%", [UIDevice currentDevice].batteryLevel * 100);
         
     }];
}

//- (NSMutableString *)backtraceLoggerArray {
//    if (_backtraceLoggerArray) {
//        return _backtraceLoggerArray;
//    }
//    _backtraceLoggerArray = [[NSMutableString alloc]init];
//    return _backtraceLoggerArray;
//}
//设备信息

+ (NSString *)deviceId {
    return [ASIdentifierManager sharedManager].advertisingIdentifier.UUIDString;
}
+ (NSString *)deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    // iPhone
    if ([deviceString isEqualToString:@"iPhone1,1"])                                                                                               return @"iPhone";
    if ([deviceString isEqualToString:@"iPhone1,2"])                                                                                               return @"iPhone 3G";
    if ([deviceString isEqualToString:@"iPhone2,1"])                                                                                               return @"iPhone 3GS";
    if ([deviceString isEqualToString:@"iPhone3,1"] || [deviceString isEqualToString:@"iPhone3,2"] || [deviceString isEqualToString:@"iPhone3,3"]) return @"iPhone 4";
    if ([deviceString isEqualToString:@"iPhone4,1"])                                                                                               return @"iPhone 4s";
    if ([deviceString isEqualToString:@"iPhone5,1"] || [deviceString isEqualToString:@"iPhone5,2"])                                                return @"iPhone 5";
    if ([deviceString isEqualToString:@"iPhone5,3"] || [deviceString isEqualToString:@"iPhone5,4"])                                                return @"iPhone 5c";
    if ([deviceString isEqualToString:@"iPhone6,1"] || [deviceString isEqualToString:@"iPhone6,2"])                                                return @"iPhone 5s";
    if ([deviceString isEqualToString:@"iPhone7,2"])                                                                                               return @"iPhone 6";
    if ([deviceString isEqualToString:@"iPhone7,1"])                                                                                               return @"iPhone 6 Plus";
    if ([deviceString isEqualToString:@"iPhone8,1"])                                                                                               return @"iPhone 6s";
    if ([deviceString isEqualToString:@"iPhone8,2"])                                                                                               return @"iPhone 6s Plus";
    if ([deviceString isEqualToString:@"iPhone8,4"])                                                                                               return @"iPhone SE";
    if ([deviceString isEqualToString:@"iPhone9,1"] || [deviceString isEqualToString:@"iPhone9,3"])                                                return @"iPhone 7";
    if ([deviceString isEqualToString:@"iPhone9,2"] || [deviceString isEqualToString:@"iPhone9,4"])                                                return @"iPhone 7 Plus";
    if ([deviceString isEqualToString:@"iPhone10,1"] || [deviceString isEqualToString:@"iPhone10,4"])                                              return @"iPhone 8";
    if ([deviceString isEqualToString:@"iPhone10,2"] || [deviceString isEqualToString:@"iPhone10,5"])                                              return @"iPhone 8 Plus";
    if ([deviceString isEqualToString:@"iPhone10,3"] || [deviceString isEqualToString:@"iPhone10,6"])                                              return @"iPhone X";
    if ([deviceString isEqualToString:@"iPhone11,8"])                                                                                              return @"iPhone XR";
    if ([deviceString isEqualToString:@"iPhone11,2"])                                                                                              return @"iPhone XS";
    if ([deviceString isEqualToString:@"iPhone11,4"] || [deviceString isEqualToString:@"iPhone11,6"])                                              return @"iPhone XS Max";
    
    
    // iPad
    if ([deviceString isEqualToString:@"iPad1,1"])                                                                                           return @"iPad";
    if ([deviceString isEqualToString:@"iPad2,1"] || [deviceString isEqualToString:@"iPad2,2"] || [deviceString isEqualToString:@"iPad2,3"] || [deviceString isEqualToString:@"iPad2,4"])
        return @"iPad 2";
    if ([deviceString isEqualToString:@"iPad3,1"] || [deviceString isEqualToString:@"iPad3,2"] || [deviceString isEqualToString:@"iPad3,3"]) return @"iPad 3";
    if ([deviceString isEqualToString:@"iPad3,4"] || [deviceString isEqualToString:@"iPad3,5"] || [deviceString isEqualToString:@"iPad3,6"]) return @"iPad 4";
    if ([deviceString isEqualToString:@"iPad6,11"] || [deviceString isEqualToString:@"iPad6,12"])                                            return @"iPad 5";
    if ([deviceString isEqualToString:@"iPad4,1"] || [deviceString isEqualToString:@"iPad4,2"] || [deviceString isEqualToString:@"iPad4,3"]) return @"iPad Air";
    if ([deviceString isEqualToString:@"iPad5,3"] || [deviceString isEqualToString:@"iPad5,4"])                                              return @"iPad Air 2";
    if ([deviceString isEqualToString:@"iPad6,7"] || [deviceString isEqualToString:@"iPad6,8"])                                              return @"iPad Pro (12.9-inch)";
    if ([deviceString isEqualToString:@"iPad6,3"] || [deviceString isEqualToString:@"iPad6,4"])                                              return @"iPad Pro (9.7-inch)";
    if ([deviceString isEqualToString:@"iPad7,1"] || [deviceString isEqualToString:@"iPad7,2"])                                              return @"iPad Pro 2 (12.9-inch)";
    if ([deviceString isEqualToString:@"iPad7,3"] || [deviceString isEqualToString:@"iPad7,4"])                                              return @"iPad Pro (10.5-inch)";
    if ([deviceString isEqualToString:@"iPad2,5"] || [deviceString isEqualToString:@"iPad2,6"] || [deviceString isEqualToString:@"iPad2,7"]) return @"iPad Mini";
    if ([deviceString isEqualToString:@"iPad4,4"] || [deviceString isEqualToString:@"iPad4,5"] || [deviceString isEqualToString:@"iPad4,6"]) return @"iPad Mini 2";
    if ([deviceString isEqualToString:@"iPad4,7"] || [deviceString isEqualToString:@"iPad4,8"] || [deviceString isEqualToString:@"iPad4,9"]) return @"iPad Mini 3";
    if ([deviceString isEqualToString:@"iPad5,1"] || [deviceString isEqualToString:@"iPad5,2"])                                              return @"iPad Mini 4)";
    
    // simulator
    if ([deviceString isEqualToString: @"i386"] || [deviceString isEqualToString:@"x86_64"]) return @"iPhone Simulator";
    
    return deviceString;
}

+ (NSString *)systemVersion {
    return [UIDevice currentDevice].systemVersion;
}
+ (NSString *)appBundleIdentifier {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
}

+ (NSString *)appVersion {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
}

+ (NSString *)appBuildVersion {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
}

+ (NSString *)appName {
    return [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];
}
+ (NSString *)getCPUFramwork {
    NSMutableString *cpu = [[NSMutableString alloc] init];
    size_t size;
    cpu_type_t type;
    cpu_subtype_t subtype;
    size = sizeof(type);
    sysctlbyname("hw.cputype", &type, &size, NULL, 0);
    size = sizeof(subtype);
    sysctlbyname("hw.cpusubtype", &subtype, &size, NULL, 0); // values for cputype and cpusubtype defined in mach/machine.h
    if (type == CPU_TYPE_X86_64) { [cpu appendString:@"x86_64"]; }
    else if (type == CPU_TYPE_X86) { [cpu appendString:@"x86"]; }
    else if (type == CPU_TYPE_ARM) { [cpu appendString:@"ARM"];
        switch(subtype) {
            case CPU_SUBTYPE_ARM_V6: [cpu appendString:@"V6"]; break;
            case CPU_SUBTYPE_ARM_V7: [cpu appendString:@"V7"]; break;
            case CPU_SUBTYPE_ARM_V8: [cpu appendString:@"V8"]; break;
        }
    }
    return cpu;
}
@end
