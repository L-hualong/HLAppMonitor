//
//  TDGlobalTimer.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDGlobalTimer.h"
#import "TDDispatchAsync.h"

static NSUInteger td_timer_time_interval = 1;
static dispatch_source_t td_global_timer = NULL;
static CFMutableDictionaryRef td_global_callbacks = NULL;
//upload
static NSUInteger td_uploadTimer_time_interval = 1 * 60;
static dispatch_source_t td_uploadGlobal_timer = NULL;
static CFMutableDictionaryRef td_uploadGlobal_callbacks = NULL;

@implementation TDGlobalTimer


CF_INLINE void __TDSyncExecute(dispatch_block_t block) {
    TDDispatchQueueAsyncBlockInBackground(^{
        assert(block != nil);
        block();
    });
}
CF_INLINE void __TDUploadSyncExecute(dispatch_block_t block) {
    TDDispatchQueueAsyncBlockInBackground(^{
        assert(block != nil);
        block();
    });
}
CF_INLINE void __TDInitGlobalCallbacks() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /*
         创建可变字典
         CFDictionaryCreateMutable ( CFAllocatorRef allocator, 
         const void **keys, 
         const void **values, 
         CFIndex numValues, 
         const CFDictionaryKeyCallBacks*keyCallBacks, 
         const CFDictionaryValueCallBacks*valueCallBacks );
         allocator:为新字典分配内存。通过NULL或kCFAllocatorDefault使用当前默认的分配器。
         keys:key的数组
         values:value的数组
         numValues:键值对数目。>=0 && >=实际数目。
         keyCallBacks:键的回调。
         valueCallBacks:值的回调。
         可以使用CFDictionaryAddValue和CFDictionarySetValue方法。注意,当我们向字典中增加键值对时，这些键值对并不会被复制，仅仅只是引用计数加1
         从字典中删除键值对，则可以使用CFDictionaryRemoveValue方法。键值对被移除后，他们的引用计数就会减1.
         CFDictionaryAddValue                     增加键值对
         
         CFDictionaryRemoveAllValues         移除所有键值对
         
         CFDictionaryRemoveValue               移除单个键值对
         
         CFDictionaryReplaceValue               替换单个键值对
         
         CFDictionarySetValue                      设置某个键值对

         */
        td_global_callbacks = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    });
}

CF_INLINE void __TDResetTimer() {
    if (td_global_timer != NULL) {
        dispatch_source_cancel(td_global_timer);
    }
    /*
     GCD中除了主要的Dispatch Queue外，还有较次要的Dispatch Source。它是BSD系内核惯有功能kqueue的包装。
     kqueue是在XUN内核中发生各种事件时，在应用程序编程方执行处理的技术。其CPU负荷非常小，尽量不占用资源。kqueue可以说是应用程序处理XUN内核中发生的各种事件的方法中最优秀的一种
     1、DISPATCH_SOURCE_TYPE_DATA_ADD 变量增加
     2、DISPATCH_SOURCE_TYPE_DATA_OR 变量 OR
     3、DISPATCH_SOURCE_TYPE_MACH_SEND MACH端口发送
     4、DISPATCH_SOURCE_TYPE_MACH_RECV MACH端口接收
     5、DISPATCH_SOURCE_TYPE_MEMORYPRESSURE 内存压力 (注：iOS8后可用)
     6、DISPATCH_SOURCE_TYPE_PROC 检测到与进程相关的事件
     7、DISPATCH_SOURCE_TYPE_READ 可读取文件映像
     8、DISPATCH_SOURCE_TYPE_SIGNAL 接收信号
     9、DISPATCH_SOURCE_TYPE_TIMER 定时器
     10、DISPATCH_SOURCE_TYPE_VNODE 文件系统有变更
     11、DISPATCH_SOURCE_TYPE_WRITE 可写入文件映像
     
     第一个参数：dispatch_source_type_t type为设置GCD源方法的类型，前面已经列举过了。
     第二个参数：uintptr_t handle Apple的API介绍说，暂时没有使用，传0即可。
     第三个参数：unsigned long mask Apple的API介绍说，使用DISPATCH_TIMER_STRICT，会引起电量消耗加剧，毕竟要求精确时间，所以一般传0即可，视业务情况而定。
     第四个参数：dispatch_queue_t _Nullable queue 队列，将定时器事件处理的Block提交到哪个队列之上。可以传Null，默认为全局队列
     
     作者：ibabyblue
     链接：https://www.jianshu.com/p/d64ee601fd47
     來源：简书
     简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。
     TDDispatchQueueAsyncBlockInDefault(^{}):放在哪个队列中执行
     */
    //执行回调代码放在默认队列执行
    td_global_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, TDDispatchQueueAsyncBlockInDefault(^{}));
    /*
     第一个参数：dispatch_source_t source......不用说了
     第二个参数：dispatch_time_t start, 定时器开始时间，类型为 dispatch_time_t，其API的abstract标明可参照dispatch_time()和dispatch_walltime()，同为设置时间，但是后者为“钟表”时间，相对比较准确，所以选择使用后者。dispatch_walltime(const struct timespec *_Nullable when, int64_t delta),参数when可以为Null，默认为获取当前时间，参数delta为增量，即获取当前时间的基础上，增加X秒的时间为开始计时时间，此处传0即可。
     第三个参数：uint64_t interval，定时器间隔时长，由业务需求而定。
     第四个参数：uint64_t leeway， 允许误差，此处传0即可。
     */
    dispatch_source_set_timer(td_global_timer, DISPATCH_TIME_NOW, td_timer_time_interval * NSEC_PER_SEC, 0);
    /*
     第一个参数：dispatch_source_t source，...不用说了。
     第二个参数：dispatch_block_t _Nullable handler，定时器执行的动作，需要处理的业务逻辑Block。
     */
    dispatch_source_set_event_handler(td_global_timer, ^{
        NSUInteger count = CFDictionaryGetCount(td_global_callbacks);
        void * callbacks[count];
        //返回一个 keys的C数组 和 一个vlaue的C数组。callbacks:vlaue数组
        //将字典里block执行
        CFDictionaryGetKeysAndValues(td_global_callbacks, NULL, (const void **)callbacks);
        for (uint idx = 0; idx < count; idx++) {
            dispatch_block_t callback = (__bridge dispatch_block_t)callbacks[idx];
            callback();
        }
    });
}
//upload 上传文件
CF_INLINE void __TDUploadInitGlobalCallbacks() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        /*
         创建可变字典
         CFDictionaryCreateMutable ( CFAllocatorRef allocator, 
         const void **keys, 
         const void **values, 
         CFIndex numValues, 
         const CFDictionaryKeyCallBacks*keyCallBacks, 
         const CFDictionaryValueCallBacks*valueCallBacks );
         allocator:为新字典分配内存。通过NULL或kCFAllocatorDefault使用当前默认的分配器。
         keys:key的数组
         values:value的数组
         numValues:键值对数目。>=0 && >=实际数目。
         keyCallBacks:键的回调。
         valueCallBacks:值的回调。
         可以使用CFDictionaryAddValue和CFDictionarySetValue方法。注意,当我们向字典中增加键值对时，这些键值对并不会被复制，仅仅只是引用计数加1
         从字典中删除键值对，则可以使用CFDictionaryRemoveValue方法。键值对被移除后，他们的引用计数就会减1.
         CFDictionaryAddValue                     增加键值对
         
         CFDictionaryRemoveAllValues         移除所有键值对
         
         CFDictionaryRemoveValue               移除单个键值对
         
         CFDictionaryReplaceValue               替换单个键值对
         
         CFDictionarySetValue                      设置某个键值对
         
         */
        td_uploadGlobal_callbacks = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    });
}

CF_INLINE void __TDUploadResetTimer() {
    if (td_uploadGlobal_timer != NULL) {
        dispatch_source_cancel(td_uploadGlobal_timer);
    }
    /*
     GCD中除了主要的Dispatch Queue外，还有较次要的Dispatch Source。它是BSD系内核惯有功能kqueue的包装。
     kqueue是在XUN内核中发生各种事件时，在应用程序编程方执行处理的技术。其CPU负荷非常小，尽量不占用资源。kqueue可以说是应用程序处理XUN内核中发生的各种事件的方法中最优秀的一种
     1、DISPATCH_SOURCE_TYPE_DATA_ADD 变量增加
     2、DISPATCH_SOURCE_TYPE_DATA_OR 变量 OR
     3、DISPATCH_SOURCE_TYPE_MACH_SEND MACH端口发送
     4、DISPATCH_SOURCE_TYPE_MACH_RECV MACH端口接收
     5、DISPATCH_SOURCE_TYPE_MEMORYPRESSURE 内存压力 (注：iOS8后可用)
     6、DISPATCH_SOURCE_TYPE_PROC 检测到与进程相关的事件
     7、DISPATCH_SOURCE_TYPE_READ 可读取文件映像
     8、DISPATCH_SOURCE_TYPE_SIGNAL 接收信号
     9、DISPATCH_SOURCE_TYPE_TIMER 定时器
     10、DISPATCH_SOURCE_TYPE_VNODE 文件系统有变更
     11、DISPATCH_SOURCE_TYPE_WRITE 可写入文件映像
     
     第一个参数：dispatch_source_type_t type为设置GCD源方法的类型，前面已经列举过了。
     第二个参数：uintptr_t handle Apple的API介绍说，暂时没有使用，传0即可。
     第三个参数：unsigned long mask Apple的API介绍说，使用DISPATCH_TIMER_STRICT，会引起电量消耗加剧，毕竟要求精确时间，所以一般传0即可，视业务情况而定。
     第四个参数：dispatch_queue_t _Nullable queue 队列，将定时器事件处理的Block提交到哪个队列之上。可以传Null，默认为全局队列
     
     作者：ibabyblue
     链接：https://www.jianshu.com/p/d64ee601fd47
     來源：简书
     简书著作权归作者所有，任何形式的转载都请联系作者获得授权并注明出处。
     TDDispatchQueueAsyncBlockInDefault(^{}):放在哪个队列中执行
     */
    //执行回调代码放在默认队列执行
    td_uploadGlobal_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, TDDispatchQueueAsyncBlockInDefault(^{}));
    /*
     第一个参数：dispatch_source_t source......不用说了
     第二个参数：dispatch_time_t start, 定时器开始时间，类型为 dispatch_time_t，其API的abstract标明可参照dispatch_time()和dispatch_walltime()，同为设置时间，但是后者为“钟表”时间，相对比较准确，所以选择使用后者。dispatch_walltime(const struct timespec *_Nullable when, int64_t delta),参数when可以为Null，默认为获取当前时间，参数delta为增量，即获取当前时间的基础上，增加X秒的时间为开始计时时间，此处传0即可。
     第三个参数：uint64_t interval，定时器间隔时长，由业务需求而定。
     第四个参数：uint64_t leeway， 允许误差，此处传0即可。
     */
    dispatch_source_set_timer(td_uploadGlobal_timer, DISPATCH_TIME_NOW, td_uploadTimer_time_interval * NSEC_PER_SEC, 0);
    /*
     第一个参数：dispatch_source_t source，...不用说了。
     第二个参数：dispatch_block_t _Nullable handler，定时器执行的动作，需要处理的业务逻辑Block。
     */
    dispatch_source_set_event_handler(td_uploadGlobal_timer, ^{
        NSUInteger count = CFDictionaryGetCount(td_global_callbacks);
        void * callbacks[count];
        //返回一个 keys的C数组 和 一个vlaue的C数组。callbacks:vlaue数组
        //将字典里block执行
        CFDictionaryGetKeysAndValues(td_uploadGlobal_callbacks, NULL, (const void **)callbacks);
        for (uint idx = 0; idx < count; idx++) {
            dispatch_block_t callback = (__bridge dispatch_block_t)callbacks[idx];
            callback();
        }
    });
}
//开始执行
CF_INLINE void __TDAutoSwitchTimer() {
    if (CFDictionaryGetCount(td_global_callbacks) > 0) {
        if (td_global_timer == NULL) {
            __TDResetTimer();
            //定时器创建完成并不会运行，需要主动去触发
            dispatch_resume(td_global_timer);
        }
    } else {
        if (td_global_timer != NULL) {
            //取消源事件处理的回调
            dispatch_source_cancel(td_global_timer);
            //释放定时器
            td_global_timer = NULL;
        }
    }
}
//upload开始执行
CF_INLINE void __TDUploadAutoSwitchTimer() {
    if (CFDictionaryGetCount(td_uploadGlobal_callbacks) > 0) {
        if (td_uploadGlobal_timer == NULL) {
            __TDUploadResetTimer();
            //定时器创建完成并不会运行，需要主动去触发
            dispatch_resume(td_uploadGlobal_timer);
        }
    } else {
        if (td_uploadGlobal_timer != NULL) {
            //取消源事件处理的回调
            dispatch_source_cancel(td_uploadGlobal_timer);
            //释放定时器
            td_uploadGlobal_timer = NULL;
        }
    }
}
+ (NSString *)registerTimerCallback: (dispatch_block_t)callback {
    NSString * key = [NSString stringWithFormat: @"%.2f", [[NSDate date] timeIntervalSince1970]];
    [self registerTimerCallback: callback key: key];
    return key;
}
+ (void)registerTimerCallback: (dispatch_block_t)callback key: (NSString *)key {
    if (!callback) { return; }
    //初始化保存block执行的字典
    __TDInitGlobalCallbacks();
    //后端处理block
    __TDSyncExecute(^{
        //设置某个键值对
        CFDictionarySetValue(td_global_callbacks, (__bridge void *)key, (__bridge void *)[callback copy]);
        //开启定时器执行block回调
        __TDAutoSwitchTimer();
    });
}
//upload 上传文件的定时器
+ (NSString *)uploadRegisterTimerCallback: (dispatch_block_t)callback {
    NSString * key = [NSString stringWithFormat: @"%.2f", [[NSDate date] timeIntervalSince1970]];
    [self uploadRegisterTimerCallback: callback key: key];
    return key;
}
+ (void)uploadRegisterTimerCallback: (dispatch_block_t)callback key: (NSString *)key {
    if (!callback) { return; }
    //初始化保存block执行的字典
    __TDUploadInitGlobalCallbacks();
    //后端处理block
    __TDUploadSyncExecute(^{
        //设置某个键值对
        CFDictionarySetValue(td_uploadGlobal_callbacks, (__bridge void *)key, (__bridge void *)[callback copy]);
        //开启定时器执行block回调
        __TDUploadAutoSwitchTimer();
    });
}
//注销定时器
+ (void)resignTimerCallbackWithKey: (NSString *)key {
    if (key == nil) { return; }
    __TDInitGlobalCallbacks();
    __TDSyncExecute(^{
        CFDictionaryRemoveValue(td_global_callbacks, (__bridge void *)key);
        __TDAutoSwitchTimer();
    });
}

+ (void)setCallbackInterval: (NSUInteger)interval {
    if (interval <= 0) { interval = 1; }
    td_timer_time_interval = interval;
}
//upload 上传文件的定时器
+ (void)uploadResignTimerCallbackWithKey: (NSString *)key {
    if (key == nil) { return; }
    __TDUploadInitGlobalCallbacks();
    __TDUploadSyncExecute(^{
        CFDictionaryRemoveValue(td_uploadGlobal_callbacks, (__bridge void *)key);
        __TDUploadAutoSwitchTimer();
    });
}

+ (void)setUploadCallbackInterval: (NSUInteger)interval {
    if (interval <= 0) { interval = 1; }
    td_uploadTimer_time_interval = interval;
}
@end
