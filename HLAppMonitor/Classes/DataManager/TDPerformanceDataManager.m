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
#import "TDFluencyStackMonitor.h"
@interface TDPerformanceDataManager () <NetworkEyeDelegate,LeakEyeDelegate,CrashEyeDelegate,ANREyeDelegate>
{
    LeakEye *leakEye;
    ANREye *anrEye;
    //开始时间
    long long startTime;

}

@end

static long logNum = 1;
static long fileNum = 1;

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

/**
 定时将数据字符串写入沙盒文件

 @param intervaTime 上传文件时间间隔,basicTime 基本性能数据获取间隔时间
 */
- (void)startRecordDataIntervalTime: (NSInteger)intervaTime withBasicTime:(NSInteger)basicTime {
    self ->startTime = [self currentTime];
    //开启fps监控
    [[TDFPSMonitor sharedMonitor]startMonitoring];
    self.isStartCasch = YES;
    [self clearTxt];
    //第一次先记录APP基础信息
    [self getAppBaseInfo];
    //开启网络流量监控
    [NetworkEye addWithObserver:self];
    //开启内存泄漏检测
    self->leakEye = [[LeakEye alloc] init];
    self->leakEye.delegate = self;
    [self->leakEye open];
    //开启奔溃检测
    [CrashEye addWithDelegate:self];
    //开启anrEye
    self->anrEye = [[ANREye alloc] init];
    self->anrEye.delegate = self;
    [self->anrEye openWith:1];
     //基本性能数据获取定时器
    [self startBasicResourceDataTime:basicTime];
   // [[TDFluencyStackMonitor sharedInstance]startWithThresholdTime:200];
    if (td_resource_recordDataIntervalTime_callback_key != nil) {return;}
    //设置定时器间隔
    [TDGlobalTimer setUploadCallbackInterval:intervaTime];
    //监听数据
    __weak typeof(self) weakSelf = self;
    td_resource_recordDataIntervalTime_callback_key = [[TDGlobalTimer uploadRegisterTimerCallback: ^{
        dispatch_async(td_log_IO_queue(), ^{
            //将String写入文件
            
            //结束时间
            long long curt = [self currentTime];
            NSString *currntime = [NSString stringWithFormat:@"%lld",curt];
            [weakSelf getStringResourceDataTime:currntime withStartOrEndTime:currntime withIsStartTime:NO];
            NSData *normalData = [weakSelf.normalDataStr dataUsingEncoding:NSUTF8StringEncoding];
            [weakSelf writeToFileWith:normalData];
    
        });
    }] copy];
}
//定时将数据字符串写入沙盒文件 兼容之前写main分支代码
- (void)recordDataIntervalTime: (NSInteger)intervaTime {
    //默认数据设置60s上传文件间隔,1s获取基本性能数据间隔
    [[TDPerformanceDataManager sharedInstance]startRecordDataIntervalTime:60 withBasicTime:1];
}
// 文件写入操作
- (void)writeToFileWith:(NSData *)data {
    NSString * filePath = [self createFilePath];//@"/Users/mobileserver/Desktop/performanceData/applog"
    NSString *fileDicPath = [@"/Users/mobileserver/Desktop/performanceData/applog" stringByAppendingPathComponent:@"appLogIOS.txt"];
    // NSString *fileDicPath = [NSString stringWithFormat:@"/Users/mobileserver/Desktop/applog.txt"];
    if (fileNum == 1) {
        fileNum += 1;
        [[NSData new] writeToFile:fileDicPath atomically:YES];
    }
    // 4.创建文件对接对象
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:fileDicPath];
    //找到并定位到outFile的末尾位置(在此后追加文件)
    [handle seekToEndOfFile];
    [handle writeData:data];
    //关闭读写文件
    [handle closeFile];
    [self clearCache];
}

- (void)normalDataStrAppendwith:(NSString*)str {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    [self.normalDataStr appendString:str];
    dispatch_semaphore_signal(sema);
}

//logNum加1
- (void)logNumAddOne {
    dispatch_semaphore_t sema = dispatch_semaphore_create(1);
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    logNum += 1;
    dispatch_semaphore_signal(sema);
}

//暂停数据缓存
- (void)stopDataCache {
    self.isStartCasch = NO;
    [self clearCache];
    if (td_resource_monitorData_callback_key == nil) { return; }
    [TDGlobalTimer resignTimerCallbackWithKey: td_resource_recordDataIntervalTime_callback_key];
    
}
//清空txt文件
- (void)clearTxt {
    NSString * filePath = [self createFilePath];//@"/Users/mobileserver/Desktop/performanceData/applog"
    NSString *fileDicPath = [@"/Users/mobileserver/Desktop/performanceData/applog" stringByAppendingPathComponent:@"appLogIOS.txt"];
    // 4.创建文件对接对象
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:fileDicPath];
    [handle truncateFileAtOffset:0];
    
}
//清空缓存
- (void)clearCache {
    self.normalDataStr = [[NSMutableString alloc] initWithString:@""];
    [[TDPerformanceMonitor sharedInstance].backtraceLoggerArray removeAllObjects];
}
//获取app基本信息数据
- (void)getAppBaseInfo {
    if (logNum != 1) {
        return;
    }
    NSString * bid = [[NSBundle mainBundle]bundleIdentifier];
    NSString * appName = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleDisplayName"];
    NSString * appVersion = [[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString * deviceVersion = [UIDevice currentDevice].systemVersion;
    NSString * deviceName = [UIDevice currentDevice].systemName;
    //开始监控时间传给gt,一开始取出时间
    NSString *currntime = [NSString stringWithFormat:@"%lld",self ->startTime];
    NSString * appInfo = [self getStringAppBaseDataTime:currntime withBundleId:bid withAppName:appName withAppVersion:appVersion withDeviceVersion:deviceVersion withDeviceName:deviceName];
    [self normalDataStrAppendwith:appInfo];
}

//获取app基本性能数据
static NSString * td_resource_monitorData_callback_key;
- (void)startBasicResourceDataTime:(NSInteger)intervaTime {
    if (!self.isStartCasch) {
        return;
    }
    if (td_resource_monitorData_callback_key != nil) { return; }
    
    //设置定时器间隔
    [TDGlobalTimer setCallbackInterval:intervaTime];
  __weak typeof(self) weakSelf = self;
    
  td_resource_monitorData_callback_key = [[TDGlobalTimer registerTimerCallback: ^{
    long long curt = [self currentTime];
    NSString *currntime = [NSString stringWithFormat:@"%lld",curt];
      //fps
    double fps = [[TDFPSMonitor sharedMonitor] getFPS];
    NSString *fpsStr = [NSString stringWithFormat:@"%d",(int)fps];
    //内存
    double appRam = [[Memory applicationUsage][0] doubleValue];
    NSString *appRamStr = [NSString stringWithFormat:@"%.1f",appRam];
    double activeRam = [[Memory systemUsage][1] doubleValue];
    double inactiveRam = [[Memory systemUsage][2] doubleValue];
    double wiredRam = [[Memory systemUsage][3] doubleValue];
    double totleSysRam = [[Memory systemUsage][5] doubleValue];
    double sysRamPercent = ((activeRam + inactiveRam + wiredRam)/totleSysRam) *100;
    NSString *sysRamPercentStr = [NSString stringWithFormat:@"%.1f",sysRamPercent];
      //CPU
    double appCpu = [CPU applicationUsage];
    NSString *appCpuStr = [NSString stringWithFormat:@"%.1f",appCpu];
    NSString *sysCpu = [CPU systemUsage][0];
    NSString *userCpu = [CPU systemUsage][1];
    NSString *niceCpu = [CPU systemUsage][3] ;
    double systemCpu = sysCpu.doubleValue + userCpu.doubleValue + niceCpu.doubleValue;
    NSString *systemCpuStr = [NSString stringWithFormat:@"%.1f",systemCpu];
    __block NSString *appNetReceivedStr = @"0.0";
      //流量
    [Store.shared networkByteDidChangeWithChange:^(double byte) {
        appNetReceivedStr = [NSString stringWithFormat:@"%.1f",byte/1024];
    }];
    NSString *normS = [weakSelf getStringResourceDataTime:currntime withFPS:fpsStr withAppRam:appRamStr withSysRam:sysRamPercentStr withAppCpu:appCpuStr withSysCpu:systemCpuStr withAppNetReceived:appNetReceivedStr];
    [self normalDataStrAppendwith:normS];
   }] copy];
}
//停止监控基本数据获取
- (void)stopResourceData {
    if (td_resource_monitorData_callback_key == nil) { return; }
    [TDGlobalTimer resignTimerCallbackWithKey: td_resource_monitorData_callback_key];
    td_resource_monitorData_callback_key = NULL;
}
//停止写入监控性能数据
- (void)stopUploadResourceData {
    [self stopResourceData];
    if (td_resource_recordDataIntervalTime_callback_key == nil) { return; }
    [TDGlobalTimer uploadResignTimerCallbackWithKey: td_resource_recordDataIntervalTime_callback_key];
     td_resource_recordDataIntervalTime_callback_key = NULL;
}
////拼接开始或结束时间 startEndTime: 开始或结束时间 ,isStartTime是否开始还是结束时间
- (void)getStringResourceDataTime:(NSString *)currntTime withStartOrEndTime:(NSString *)startEndTime withIsStartTime:(BOOL) isStartTime {
    if (isStartTime) {
        //将开始时间拼接在这里
        NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^startResourceDataTime", logNum,currntTime];
        @synchronized (self) {
            [self logNumAddOne];
            [att appendFormat:@"^%@",startEndTime]; //开始时间
            [att appendFormat:@"^%@",@"\n"];
        }
         [self normalDataStrAppendwith:att];
    }else{
        //将结束时间拼接在这里
        NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^stopResourceDataTime", logNum,currntTime];
        @synchronized (self) {
            [self logNumAddOne];
            [att appendFormat:@"^%@",startEndTime]; //开始时间
            [att appendFormat:@"^%@",@"\n"];
        }
         [self normalDataStrAppendwith:att];
    }
}
//异步获取数据,生命周期方法名
- (void)asyncExecuteClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod withUniqueIdentifier:(NSString *)uniqueIdentifier {
    if (!self.isStartCasch) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    [self asyncExecute:^{
        long long curt = [self currentTime];
        NSString *currntime = [NSString stringWithFormat:@"%lld",curt];
        NSString *hookS = [weakSelf getStringExecuteTime:currntime withClassName:className withStartTime:startTime withEndTime:endTime withHookMethod:hookMethod  withUniqueIdentifier: uniqueIdentifier];
        [weakSelf normalDataStrAppendwith:hookS];
    }];
}
//app基本性能数据
- (NSString *)getStringResourceDataTime:(NSString *)currntTime withFPS:(NSString *)fps withAppRam:(NSString *)appRam withSysRam:(NSString *)sysRam withAppCpu:(NSString *)appCpu withSysCpu:(NSString *)sysCpu
    withAppNetReceived:(NSString *)appNetReceived{
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^normalCollect", logNum,currntTime];
    @synchronized (self) {
        [self logNumAddOne];
        [att appendFormat:@"^%@",appCpu]; //百分比
        [att appendFormat:@"^%@",sysCpu]; //百分比
        [att appendFormat:@"^%@",appRam]; //Byte
        [att appendFormat:@"^%@",sysRam]; //百分比
        [att appendFormat:@"^%@",fps];
        [att appendFormat:@"^%@",appNetReceived]; //KB
        [att appendFormat:@"^%@",@"\n"];
    }
    return att.copy;
    
}
//app基本信息数据
- (NSString *)getStringAppBaseDataTime:(NSString *)currntTime withBundleId:(NSString *)bid
                           withAppName:(NSString *)appName withAppVersion:(NSString *)appVersion
                           withDeviceVersion:(NSString *)deviceVersion withDeviceName:(NSString *)deviceName{
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^appCollect", logNum,currntTime];
    @synchronized (self) {
        [self logNumAddOne];
        [att appendFormat:@"^%@",bid];
        [att appendFormat:@"^%@",appName];
        [att appendFormat:@"^%@",appVersion];
        [att appendFormat:@"^%@",deviceVersion];
        [att appendFormat:@"^%@",deviceName];
        [att appendFormat:@"^100"];
        [att appendFormat:@"^%@",@"\n"];
    }
    return att.copy;
    
}
//页面生命周期方法,uniqueIdentifier:页面唯一标识
- (NSString *)getStringExecuteTime:(NSString *)currntTime withClassName:(NSString *)className withStartTime:(NSString *)startTime withEndTime:(NSString *)endTime withHookMethod:(NSString *)hookMethod withUniqueIdentifier:(NSString *)uniqueIdentifier{
    NSMutableString *hookSt = [[NSMutableString alloc]initWithFormat:@"%ld^%@^%@", logNum,currntTime,hookMethod];
    @synchronized (self) {
        [self logNumAddOne];
        [hookSt appendFormat:@"^%@",className];
        [hookSt appendFormat:@"^%@",uniqueIdentifier];
        [hookSt appendFormat:@"^%@",startTime];
        [hookSt appendFormat:@"^%@",endTime];
        [hookSt appendFormat:@"^%@",@"\n"];
    }
    return hookSt.copy;
}
//页面渲染时间
- (NSString *)getRenderWithClassName:(NSString *)className withRenderTime:(NSString *)renderTime {
    long long curt = [self currentTime];
    NSString *currntime = [NSString stringWithFormat:@"%lld",curt];
    NSMutableString *renderStr = [[NSMutableString alloc]initWithFormat:@"%ld^%@^renderCollect", logNum,currntime];
    @synchronized (self) {
        [self logNumAddOne];
        [renderStr appendFormat:@"^%@",className];
        [renderStr appendFormat:@"^%@",renderTime];
        [renderStr appendFormat:@"^%@",@"\n"];
    }
    return renderStr.copy;
}
- (void)asyncExecute: (dispatch_block_t)block {
    assert(block != nil);
    if ([NSThread isMainThread]) {
        TDDispatchQueueAsyncBlockInUtility(block);
    } else {
        block();
    }
}

//获取当前时间
- (long long)currentTime {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970] * 1000;
    long long dTime = [[NSNumber numberWithDouble:time] longLongValue]; 
    return dTime;
}
- (NSMutableString *)normalDataStr {
    if (_normalDataStr) {
        return _normalDataStr;
    }
    _normalDataStr = [[NSMutableString alloc] init];
    return _normalDataStr;
}
#pragma mark - GodEyeDelegate

//网络流量
- (void)networkEyeDidCatchWith:(NSURLRequest *)request response:(NSURLResponse *)response data:(NSData *)data
{
    if (response != nil) {
        [Store.shared addNetworkByte:response.expectedContentLength];
    }

}
//检测到内存泄漏
-(void)leakEye:(LeakEye *)leakEye didCatchLeak:(NSObject *)object
{
    long long curt = [self currentTime];
    NSString *currntTime = [NSString stringWithFormat:@"%lld",curt];
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^leakCollect",logNum,currntTime];
    @synchronized (self) {
        [self logNumAddOne];
        [att appendFormat:@"^%@",NSStringFromClass(object.classForCoder)];
        [att appendFormat:@"^%@",object];
        [att appendFormat:@"^%@",@"\n"];
    }
    [self normalDataStrAppendwith:att];
}

//检测到crash
- (void)crashEyeDidCatchCrashWith:(CrashModel *)model
{
    NSString *str = [self getCrashInfoWithModel:model];
    [self normalDataStrAppendwith:str];
}

//app的crash数据
- (NSString *)getCrashInfoWithModel:(CrashModel *)model {
    
    NSString *type = model.type;
    NSString *name = model.name;
    NSString *reason = model.reason;
    NSString *appinfo = model.appinfo;
    NSString *callStack = model.callStack;
    
    long long curt = [self currentTime];
    NSString *currntTime = [NSString stringWithFormat:@"%lld",curt];
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^CrashCollect", logNum,currntTime];
    @synchronized (self) {
        [self logNumAddOne];
        [att appendFormat:@"^%@",type];
        [att appendFormat:@"^%@",name];
        [att appendFormat:@"^%@",reason];
        [att appendFormat:@"^%@",appinfo];
        [att appendFormat:@"^%@",callStack];
        [att appendFormat:@"^%@",@"\n"];
    }
    return att.copy;
    
}

//检测到卡顿
- (void)anrEyeWithAnrEye:(ANREye *)anrEye catchWithThreshold:(double)threshold mainThreadBacktrace:(NSString *)mainThreadBacktrace allThreadBacktrace:(NSString *)allThreadBacktrace
{
//    //##&&**###INRCollect作为唯一标识
//    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^", logNum,[self getCurrntTime]];
//    @synchronized (self) {
//        [self logNumAddOne];
//        [att appendFormat:@"^%f",threshold];
//        [att appendFormat:@"%@^%@%@",@"\n",@"##&&**###INRCollectAllThreadBacktrace",@"\n"];
//        [att appendFormat:@"%@",mainThreadBacktrace];
//        [att appendFormat:@"%@^%@%@",@"\n",@"##&&**###INRCollectAllThreadBacktrace",@"\n"];
//        [att appendFormat:@"%@",allThreadBacktrace];
//        [att appendFormat:@"^%@",@"\n"];
//    }
//    [self normalDataStrAppendwith:att];
}
- (void)anrEyeWithAnrEye:(ANREye *)anrEye startTime:(int64_t)startTime endTime:(int64_t)endTime catchWithThreshold:(double)threshold mainThreadBacktrace:(NSString *)mainThreadBacktrace allThreadBacktrace:(NSString *)allThreadBacktrace {
    //NSMutableString *mainThradB = [[NSMutableString alloc]init];
    NSString *mainThradB = [mainThreadBacktrace stringByReplacingOccurrencesOfString:@"\n" withString:@"#&####"];
    //##&&**###INRCollect作为唯一标识
    NSMutableString *att = [[NSMutableString alloc]initWithFormat:@"%ld^%@^INRCollectMainThread", (long)logNum,[self getCurrntTime]];
    @synchronized (self) {
        [self logNumAddOne];
     //   long long startTime1 = self ->startTime;
        //开始时间
        [att appendFormat:@"^%lld",startTime];
        //结束时间
        [att appendFormat:@"^%lld",endTime];
        //卡顿时长
        [att appendFormat:@"^%lld",endTime - startTime];
       // [att appendFormat:@"%@^%@%@",@"\n",@"##&&**###INRCollectAllThreadBacktrace",@"\n"];
        [att appendFormat:@"^%@",mainThradB];
      //  [att appendFormat:@"%@^%@%@",@"\n",@"##&&**###INRCollectAllThreadBacktrace",@"\n"];
       // [att appendFormat:@"%@",allThreadBacktrace];
        [att appendFormat:@"^%@",@"\n"];
    }
    [self normalDataStrAppendwith:att];
}

- (NSString *)getCurrntTime {
    long long curt = [self currentTime];
    NSString *currntTime = [NSString stringWithFormat:@"%lld",curt];
    return currntTime;
}


@end
