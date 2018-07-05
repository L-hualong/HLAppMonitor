//
//  TDPerformanceDataManager.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/28.
//  Copyright © 2018 Dee. All rights reserved.
//性能获取数据管理者

#import "TDPerformanceDataManager.h"
#import "TDPerformanceDataModel.h"
#import "TDGlobalTimer.h"
#import "TDDispatchAsync.h"
#import "TDPerformanceMonitor.h"
#import "TDFPSMonitor.h"
#import <HLAppMonitor/HLAppMonitor-Swift.h>
//#import <TDWKit/TDWKit-Swift.h>
@interface TDPerformanceDataManager () <NetworkEyeDelegate>
{
    
}

@end

static NSInteger logNum = 1;

@implementation TDPerformanceDataManager

static inline dispatch_queue_t td_log_IO_queue() {
    static dispatch_queue_t td_log_IO_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        td_log_IO_queue = dispatch_queue_create("com.tuandaiguo.td_log_IO_queue", NULL);
    });
    return td_log_IO_queue;
}

+ (instancetype)sharedInstance
{
    static TDPerformanceDataManager * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TDPerformanceDataManager alloc] init];
    });
    return instance;
}

#pragma mark - Private
- (NSString *)createFilePath {
    static NSString * const kLoggerDatabaseFileName = @"app_logger";
    NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent: kLoggerDatabaseFileName];
    NSFileManager * manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath: filePath]) {
        [manager createDirectoryAtPath: filePath withIntermediateDirectories: YES attributes: nil error: nil];
        NSLog(@"path=%@",filePath);
    }
    return filePath;
}
static NSString * td_resource_recordDataIntervalTime_callback_key;
//写入沙盒里
- (void)recordDataIntervalTime: (NSInteger)intervaTime {
    self.isStartCasch = YES;
    //开启网络流量监控
    [NetworkEye addWithObserver:self];
    //设置定时器间隔
//    [TDGlobalTimer setCallbackInterval:intervaTime * 1000];
    if (td_resource_monitorData_callback_key != nil) {return;}
    
    //监听数据
    __weak typeof(self) weakSelf = self;
    td_resource_recordDataIntervalTime_callback_key = [[TDGlobalTimer registerTimerCallback: ^{
        dispatch_async(td_log_IO_queue(), ^{
            //首先获取一次app信息
            if (logNum == 1) {
                [weakSelf getAppBaseInfo];
                NSData *normalData = [weakSelf.normalDataStr dataUsingEncoding:NSUTF8StringEncoding];
                [weakSelf writeToFileWith:normalData];
            }
            //nomarData
            [weakSelf startResourceData];
            NSData *normalData = [weakSelf.normalDataStr dataUsingEncoding:NSUTF8StringEncoding];
            [weakSelf writeToFileWith:normalData];
            
//            if (weakSelf.pageDataArray.count > 0) {
//                 NSData *pageData = [weakSelf.pageDataArray TDJSONData];
//                 [data1 appendData:pageData];
//            }
            
            //堆栈信息
//            NSArray * backtraceLoggerArray = [TDPerformanceMonitor sharedInstance].backtraceLoggerArray.copy;
//            if (backtraceLoggerArray.count > 0) {
//                NSData *backtraceData = [backtraceLoggerArray TDJSONData];
//                [data1 appendData:backtraceData];
//            }
        });
    }] copy];
}

// 文件写入操作
- (void)writeToFileWith:(NSData *)data {
    NSString * filePath = [self createFilePath];
    NSString *fileDicPath = [filePath stringByAppendingPathComponent:@"appLog.txt"];
    // 4.创建文件对接对象
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:fileDicPath];
    NSMutableData *data1 = [NSMutableData data];
    [data1 appendData:data];
    //找到并定位到outFile的末尾位置(在此后追加文件)
    [handle seekToEndOfFile];
    BOOL result = [data1 writeToFile:fileDicPath atomically:YES];
    //关闭读写文件
    [handle closeFile];
    NSLog(@"result=%d",result);
//    [self clearCache];
}
//暂停数据缓存
- (void)stopDataCache {
    self.isStartCasch = NO;
    [self clearCache];
    if (td_resource_monitorData_callback_key == nil) { return; }
    [TDGlobalTimer resignTimerCallbackWithKey: td_resource_recordDataIntervalTime_callback_key];
    
}
//清空缓存
- (void)clearCache {
    self.normalDataStr = [[NSMutableString alloc] initWithString:@""];
    [self.pageDataArray removeAllObjects];
    [[TDPerformanceMonitor sharedInstance].backtraceLoggerArray removeAllObjects];
}
//获取app基本信息数据
- (void)getAppBaseInfo {
    NSString * bid = [[NSBundle mainBundle]bundleIdentifier];
    NSString * appName = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString * appVersion = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString * deviceVersion = [UIDevice currentDevice].systemVersion;
    NSString * deviceName = [UIDevice currentDevice].systemName;
    NSTimeInterval curt = [self currentTime];
    NSString *currntime = [NSString stringWithFormat:@"%.1f",curt];
    NSString * appInfo = [self getStringAppBaseDataTime:currntime withBundleId:bid withAppName:appName withAppVersion:appVersion withDeviceVersion:deviceVersion withDeviceName:deviceName];
    [self.normalDataStr appendString:appInfo];
}

//获取app基本性能数据
static NSString * td_resource_monitorData_callback_key;
- (void)startResourceData {
    if (!self.isStartCasch) {
        return;
    }
    if (td_resource_monitorData_callback_key != nil) { return; }
    //设置定时器间隔
    [TDGlobalTimer setCallbackInterval:2];
//    __weak typeof(self) weakSelf = self;
    
//    td_resource_monitorData_callback_key = [[TDGlobalTimer registerTimerCallback: ^{
    NSTimeInterval curt = [self currentTime];
    NSString *currntime = [NSString stringWithFormat:@"%.1f",curt];
    double fps = [[TDFPSMonitor sharedMonitor] getFPS];
    NSString *fpsStr = [NSString stringWithFormat:@"%d",(int)fps];
    double appRam = [[Memory applicationUsage][0] doubleValue];
    NSString *appRamStr = [NSString stringWithFormat:@"%.1f",appRam];
    double activeRam = [[Memory systemUsage][1] doubleValue];
    double inactiveRam = [[Memory systemUsage][2] doubleValue];
    double wiredRam = [[Memory systemUsage][3] doubleValue];
    double totleSysRam = [[Memory systemUsage][5] doubleValue];
    double sysRamPercent = ((activeRam + inactiveRam + wiredRam)/totleSysRam) *100;
    NSString *sysRamPercentStr = [NSString stringWithFormat:@"%.1f",sysRamPercent];
    double appCpu = [CPU applicationUsage];
    NSString *appCpuStr = [NSString stringWithFormat:@"%.1f",appCpu];
    NSString *sysCpu = [CPU systemUsage][0];
    NSString *userCpu = [CPU systemUsage][1];
    NSString *niceCpu = [CPU systemUsage][3] ;
    double systemCpu = sysCpu.doubleValue + userCpu.doubleValue + niceCpu.doubleValue;
    NSString *systemCpuStr = [NSString stringWithFormat:@"%.1f",systemCpu];
    __block NSString *appNetReceivedStr = @"";
    [Store.shared networkByteDidChangeWithChange:^(double byte) {
        appNetReceivedStr = [NSString stringWithFormat:@"%.1f",byte/1024];
    }];
    NSString *normS = [self getStringResourceDataTime:currntime withFPS:fpsStr withAppRam:appRamStr withSysRam:sysRamPercentStr withAppCpu:appCpuStr withSysCpu:systemCpuStr withAppNetReceived:appNetReceivedStr];
    [self.normalDataStr appendString:normS];
//    }] copy];
}
- (void)stopResourceData {
    if (td_resource_monitorData_callback_key == nil) { return; }
    [TDGlobalTimer resignTimerCallbackWithKey: td_resource_monitorData_callback_key];
}
//异步获取数据,生命周期方法名
- (void)syncExecuteClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod {
    if (!self.isStartCasch) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self syncExecute:^{
        NSString *hookS = [weakSelf getStringExecuteClassName:className withStartTime:startTime withEndTime:endTime withHookMethod:hookMethod];
        [weakSelf.pageDataArray addObject:hookS];
    }];
}
//app基本性能数据
- (NSString *)getStringResourceDataTime:(NSString *)currntTime withFPS:(NSString *)fps withAppRam:(NSString *)appRam withSysRam:(NSString *)sysRam withAppCpu:(NSString *)appCpu withSysCpu:(NSString *)sysCpu
    withAppNetReceived:(NSString *)appNetReceived{
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^normalCollect",logNum,currntTime];
    @synchronized (self) {
        logNum += 1;
        [att appendFormat:@"^%@",appCpu]; //百分比
        [att appendFormat:@"^%@",sysCpu]; //百分比
        [att appendFormat:@"^%@",appRam]; //Byte
        [att appendFormat:@"^%@",sysRam]; //百分比
        [att appendFormat:@"^%@",fps];
        [att appendFormat:@"^%@",appNetReceived]; //KB
        [att appendFormat:@"%@",@"\n"];
    }
    return att.copy;
    
}
//app基本信息数据
- (NSString *)getStringAppBaseDataTime:(NSString *)currntTime withBundleId:(NSString *)bid
                           withAppName:(NSString *)appName withAppVersion:(NSString *)appVersion
                           withDeviceVersion:(NSString *)deviceVersion withDeviceName:(NSString *)deviceName{
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^appCollect",logNum,currntTime];
    @synchronized (self) {
        logNum += 1;
        [att appendFormat:@"^%@",bid];
        [att appendFormat:@"^%@",appName];
        [att appendFormat:@"^%@",appVersion];
        [att appendFormat:@"^%@",deviceVersion];
        [att appendFormat:@"^%@",deviceName];
        [att appendFormat:@"%@",@"\n"];
    }
    return att.copy;
    
}
- (NSString *)getStringExecuteClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod {
    NSString *hookSt = [NSString stringWithFormat:@"Instrumentation.%@",hookMethod];
    NSMutableString *muStt = [[NSMutableString alloc]initWithFormat:@"%@",hookSt];
    [muStt appendFormat:@"^%@",className];
    [muStt appendFormat:@"^%@",startTime];
    [muStt appendFormat:@"^%@",endTime];
    return muStt.copy;
}
- (void)syncExecute: (dispatch_block_t)block {
    assert(block != nil);
    if ([NSThread isMainThread]) {
        TDDispatchQueueAsyncBlockInUtility(block);
    } else {
        block();
    }
}

//获取当前时间
- (NSTimeInterval)currentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}
- (NSMutableString *)normalDataStr {
    if (_normalDataStr) {
        return _normalDataStr;
    }
    _normalDataStr = [[NSMutableString alloc] init];
    return _normalDataStr;
}
- (NSMutableArray *)pageDataArray {
    if (_pageDataArray) {
        return _pageDataArray;
    }
    _pageDataArray = [[NSMutableArray alloc]init];
    return _pageDataArray;
}
#pragma mark - NetworkEyeDelegate
- (void)networkEyeDidCatchWith:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data
{
    if (response != nil) {
        [Store.shared addNetworkByte:response.expectedContentLength];
    }

}


@end
