//
//  TDFluencyStackMonitor.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/8/15.
//利用fps 监控主线程卡顿情况

#import "TDFluencyStackMonitor.h"
#import "../性能测试/Logger/TDBacktraceLogger.h"

static BOOL td_is_monitoring = NO;
static dispatch_semaphore_t td_semaphore;
static int thresholdTimeCount = 100;
static double thresholdTime = 250;

@interface TDFluencyStackMonitor ()

@property(nonatomic,strong)NSMutableArray *stackArray;
@end
@implementation TDFluencyStackMonitor
{
    CADisplayLink *displayLink;
    int timeOut;
    long long startTime;
}
static inline dispatch_queue_t __td_fluecy_monitor_queue() {
    static dispatch_queue_t td_fluecy_monitor_queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        td_fluecy_monitor_queue = dispatch_queue_create("com.sindrilin.lxd_monitor_queue", NULL);
    });
    return td_fluecy_monitor_queue;
}
+ (instancetype)sharedInstance {
    
    static TDFluencyStackMonitor * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TDFluencyStackMonitor alloc] init];
    });
    return instance;
}
- (void)startWithThresholdTime:(double)threshold {
    
    if (td_is_monitoring) { return; }
    self ->startTime = 0;
    td_is_monitoring = YES;
    if (threshold > 0) {
         thresholdTimeCount = threshold / 16.667;
    }else{
         thresholdTimeCount = thresholdTime / 16.667;
    }
    td_semaphore = dispatch_semaphore_create(0);
    dispatch_async(__td_fluecy_monitor_queue(), ^{
        
        CADisplayLink * displayLink = [CADisplayLink displayLinkWithTarget: self selector: @selector(screenRenderCall)];
        [self ->displayLink invalidate];
        self ->displayLink = displayLink;
        
        [self ->displayLink addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSDefaultRunLoopMode];
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, CGFLOAT_MAX, NO);
    });
}
- (void)stop {
    if (!td_is_monitoring) { return; }
    td_is_monitoring = NO;
}
- (void)screenRenderCall {
    //进来做个标记
    __block BOOL flag = YES;
     //监听主线是否空闲
    dispatch_async(dispatch_get_main_queue(), ^{
        //如果执行了表示主线程有空闲
        flag = NO;
        dispatch_semaphore_signal(td_semaphore);
    });
    long st = dispatch_semaphore_wait(td_semaphore, dispatch_time(DISPATCH_TIME_NOW, 16.667*NSEC_PER_MSEC));
    //这里要初始化信号量,因为前面出现卡顿情况下,发送信号量过多会导致检测不到卡顿情况,现在是按帧率一帧一帧去检测卡顿情况
    td_semaphore = dispatch_semaphore_create(0);
    if (st != 0) { //st不等于0表示没有成功唤醒,指导超时才会执行以下代码
        if (flag) {
            if (++self ->timeOut < thresholdTimeCount) { 
                if (self ->timeOut == 1) {//表示开始卡顿
                    self ->startTime = [self currentTime];
                }
                return; 
            }
            long long endTime = [self currentTime];
            NSString *string = [NSString stringWithFormat:@"startTime=%lld---endTime=%lld",self ->startTime,endTime];
            [self stitchingCatonStackData:string withIsEmpty:NO];
            NSLog(@"卡死了----%ld",st);
        }
    }else{
        //如果能走这里来就是前面没有出现卡顿或者出现卡顿情况现在恢复了
        if (self ->timeOut > 0) {//表示前面出现了卡顿了以后就没有出现卡顿了
            
            long long endTime = [self currentTime];
            NSString *string = [NSString stringWithFormat:@"endTime=%lld",endTime];
            [self stitchingCatonStackData:string withIsEmpty:YES];
        }
    }
    self ->timeOut = 0;
}
//记录堆栈信息
- (NSString *)recodeLogger {
    //获取堆栈信息
    NSString *threamData =  [TDBacktraceLogger td_backtraceOfAllThread];
    return  threamData;
}
//拼接堆栈信息,isEmpty是否清空stackArray
- (void)stitchingCatonStackData:(NSString *)stackString withIsEmpty:(BOOL)isEmpty {
    [self.stackArray addObject:stackString];
    if (isEmpty) {//清空
        NSArray *stackA = self.stackArray.copy;
        [self.backtraceLoggerArray addObject:stackA];
        [self.stackArray removeAllObjects];
    }
}
//获取当前时间
- (long long)currentTime {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970] * 1000;
    long long dTime = [[NSNumber numberWithDouble:time] longLongValue]; 
    return dTime;
}
- (NSMutableArray *)backtraceLoggerArray {
    if (_backtraceLoggerArray) {
        return _backtraceLoggerArray;
    }
    _backtraceLoggerArray = [[NSMutableArray alloc]init];
    return _backtraceLoggerArray;
}
- (NSMutableArray *)stackArray {
    if (_stackArray) {
        return _stackArray;
    }
    _stackArray = [[NSMutableArray alloc]init];
    return _stackArray;
}
@end
