//
//  TDTransaction.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/26.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDTransaction.h"
#import <sys/time.h>

//延时时间,表示当前时间向后延时一秒为timeout的时间。
#define TDDELAYTIME  dispatch_time_t  t = dispatch_time(DISPATCH_TIME_NOW, 1*1000*1000*1000)

/*这个函数会使传入的信号量dsema的值减1,这个函数的作用是这样的，如果dsema信号量的值大于0，该函数所处线程就继续执行下面的语句，并且将信号量的值减1；如果desema的值为0，那么这个函数就阻塞当前线程等待timeout,超出时间执行下面代码
 返回值也为long型。当其返回0时表示在timeout之前，该函数所处的线程被成功唤醒。当其返回不为0时，表示timeout发生
 在设置timeout时，比较有用的两个宏：DISPATCH_TIME_NOW 和 DISPATCH_TIME_FOREVER。
 
 　　DISPATCH_TIME_NOW　　表示当前；
 　　DISPATCH_TIME_FOREVER　　表示遥远的未来
 */
#define TRANSACTION_LOCK(__lock) dispatch_wait(__lock, DISPATCH_TIME_FOREVER)
/*这个函数会使传入的信号量dsema的值加1
 返回值为long类型，当返回值为0时表示当前并没有线程等待其处理的信号量，其处理
 
 　　的信号量的值加1即可。当返回值不为0时，表示其当前有（一个或多个）线程等待其处理的信号量，并且该函数唤醒了一
 
 　　个等待的线程（当线程有优先级时，唤醒优先级最高的线程；否则随机唤醒）
 */
#define TRANSACTION_UNLOCK(__lock) dispatch_semaphore_signal(__lock);


#pragma mark - Task Queue
@interface TDExecuteTaskQueue : NSObject
@end

@implementation TDExecuteTaskQueue
//执行任务队列
static inline CFMutableArrayRef _td_execute_task_queue() {
    static CFMutableArrayRef td_execute_task_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //创建一个不增加引用计数的数组,kCFAllocatorDefault默认开辟一块空间,0表示不限制内存大小,kCFTypeArrayCallBacks表示使用默认回到函数,返回一个可变数组
        td_execute_task_queue = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    });
    return td_execute_task_queue;
}
//创建一个信号量
static inline dispatch_semaphore_t _td_excute_task_queue_lock() {
    static dispatch_semaphore_t td_transaction_queue_lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //输出一个dispatch_semaphore_t类型且值为value的信号量
        td_transaction_queue_lock = dispatch_semaphore_create(1);
    });
    return td_transaction_queue_lock;
}
//获取执行任务
+ (dispatch_block_t)fetchExecuteTask {
    if (CFArrayGetCount(_td_execute_task_queue()) == 0) { return nil; }
    //保证线程安全
    TRANSACTION_LOCK(_td_excute_task_queue_lock());
    dispatch_block_t executeTask = CFArrayGetValueAtIndex(_td_execute_task_queue(), 0);
    CFArrayRemoveValueAtIndex(_td_execute_task_queue(), 0);
    TRANSACTION_UNLOCK(_td_excute_task_queue_lock());
    return executeTask;
}

+ (void)insertExecuteTask: (dispatch_block_t)block {
    assert(block != nil);
    TRANSACTION_LOCK(_td_excute_task_queue_lock());
    CFArrayAppendValue(_td_execute_task_queue(), (__bridge void *)[block copy]);
    TRANSACTION_UNLOCK(_td_excute_task_queue_lock());
}


@end


#pragma mark - RunLoop Observer
//表示记录代码执行的时间
static struct timeval td_free_loop_entry_time;
//计算时间间隔是否有效有效
static inline bool _td_calculate_time_interval_valid(struct timeval start, struct timeval end) {
    static long td_max_loop_time = NSEC_PER_SEC / 60 * 0.8;
    long time_interval = (end.tv_sec - start.tv_sec) * NSEC_PER_SEC + (end.tv_usec - start.tv_usec);
    return time_interval < td_max_loop_time;
}
//运行循环的空闲时间监听
static void _td_run_loop_free_time_observer(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void * info) {
    //获取当前时间
    gettimeofday(&td_free_loop_entry_time, NULL);
}
//事务运行循环监听
static void _td_transaction_run_loop_observer(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void * info) {
    struct timeval current_time;
    dispatch_block_t executeTask;
    
    do {
        executeTask = [TDExecuteTaskQueue fetchExecuteTask];
        if (executeTask != nil) { executeTask(); }
        else { break; }
        gettimeofday(&current_time, NULL);
    } while( _td_calculate_time_interval_valid(td_free_loop_entry_time, current_time) );
}

#pragma mark - Transaction
@implementation TDTransaction

static bool td_transaction_flag = false;
static inline dispatch_semaphore_t _td_transaction_lock() {
    static dispatch_semaphore_t td_transaction_lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        td_transaction_lock = dispatch_semaphore_create(1);
    });
    return td_transaction_lock;
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFRunLoopRef runloop = CFRunLoopGetMain();
        CFRunLoopObserverRef observer;
        /*
         kCFRunLoopEntry = (1UL << 0),                //  : 即将到 runloop
         kCFRunLoopBeforeTimers = (1UL << 1),         //   : 即将处理 timer 之前
         kCFRunLoopBeforeSources = (1UL << 2),        //    : 即将处理 source 之前
         kCFRunLoopBeforeWaiting = (1UL << 5),       //     : 即将休眠
         kCFRunLoopAfterWaiting = (1UL << 6),        //       : 休眠之后
         kCFRunLoopExit = (1UL << 7),                //        : 退出
         kCFRunLoopAllActivities = 0x0FFFFFFFU      //         : 所有的活动
         
         order：CFRunLoopObserver的优先级，当在Runloop同一运行阶段中有多个CFRunLoopObserver时，根据这个来先后调用CFRunLoopObserver。正常情况下使用0。
         block：回调的block。
         这个block有两个参数：
         observer：正在运行的run loop observe。
         activity：runloop当前的运行阶段。
         返回值：
         新的CFRunLoopObserver对象。
         _ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()。这个函数里会遍历所有待处理的 UIView/CAlayer 以执行实际的绘制和调整，并更新 UI 界面。 
         */
        observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(),
                                           kCFRunLoopBeforeWaiting | kCFRunLoopExit,
                                           true, 0x0,
                                           _td_run_loop_free_time_observer, NULL);
        CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
        CFRelease(observer);
        
        observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(),
                                           kCFRunLoopBeforeWaiting | kCFRunLoopExit,
                                           true,// repeat
                                           0xFFFFFF,// after CATransaction(2000000)
                                           
                                           _td_transaction_run_loop_observer, NULL);
        CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}

+ (void)begin {
    if (td_transaction_flag) { return; }
    TRANSACTION_LOCK(_td_transaction_lock());
    td_transaction_flag = true;
    TRANSACTION_UNLOCK(_td_transaction_lock());
}

+ (void)commit {
    if (!td_transaction_flag) { return; }
    TRANSACTION_LOCK(_td_transaction_lock());
    td_transaction_flag = false;
    TRANSACTION_UNLOCK(_td_transaction_lock());
}
@end
