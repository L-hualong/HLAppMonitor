//
//  TDDispatchAsync.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDDispatchAsync.h"
#import <libkern/OSAtomic.h>


#ifndef TDDispatchAsync_m
#define TDDispatchAsync_m
#endif
// inline 关键字实际上仅是建议内联并不强制内联,加入static 后则内联了, 所以在头文件中用inline时务必加入static，否则当inline不内联时就和普通函数在头文件中定义一样，当多个c文件包含时就会重定义。所以加入static代码健壮性高，如果都内联了实际效果上是一样的
#define TD_INLINE static inline
#define TD_QUEUE_MAX_COUNT 32


typedef struct __TDDispatchContext {
    const char * name;
    void ** queues;
    uint32_t queueCount;
    int32_t offset;
} *DispatchContext, TDDispatchContext;

//执行队列优先级
TD_INLINE dispatch_queue_priority_t __TDQualityOfServiceToDispatchPriority(TDQualityOfService qos) {
    switch (qos) {
        case TDQualityOfServiceUserInteractive: return DISPATCH_QUEUE_PRIORITY_HIGH;
        case TDQualityOfServiceUserInitiated: return DISPATCH_QUEUE_PRIORITY_HIGH;
        case TDQualityOfServiceUtility: return DISPATCH_QUEUE_PRIORITY_LOW;
        case TDQualityOfServiceBackground: return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
        case TDQualityOfServiceDefault: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
        default: return DISPATCH_QUEUE_PRIORITY_DEFAULT;
    }
}
/*
 指定全局队列的服务质量（QOS）
 dispatch_queue_priority_t（DISPATCH_QUEUE_PRIORITY_HIGH，DISPATCH_QUEUE_PRIORITY_DEFAULT，DISPATCH_QUEUE_PRIORITY_LOW，DISPATCH_QUEUE_PRIORITY_BACKGROUND）中的值，这些值映射为一个适合QOS的级别。
 
 QOS_CLASS_USER_INTERACTIVE，QOS_CLASS_USER_INQOS_CLASS_USER_INITIATED，QOS_CLASS_UTILITY，QOS_CLASS_BACKGROUND。运用user-interactive或user-initiated任务的全局队列要比一般在后台运行的任务优先级要高
 
 dispatch_queue_create(const char *label, dispatch_queue_attr_t attr);
 dispatch_release函数释放掉这个队列
 任何被提交到一个队列中还没有执行的block都有这个队列的引用，所以这个队列是不会被释放掉的，直到所有还没有执行的block都完成以后才会被释放掉。
 label，一个字符串，被附加到队列中用于标识队列的唯一性。由于应用、库和框架都可以创建他们自己的调度队列，所以推荐采用反转DNS（com.example.myqueue）的命名方式。label这个参数是可选的，也可以是NULL
 attr，在OS X v10.7及以后或iOS 4.3及以后的版本中，指定DISPATCH_QUEUE_SERIAL（或NULL）去创建一个串行队列，指定DISPATCH_QUEUE_CONCURRENT去创建一个并行队列。在更早的版本中，这个歌参数只能被指定为NULL
 */
TD_INLINE qos_class_t __TDQualityOfServiceToQOSClass(TDQualityOfService qos) {
    switch (qos) {
        case TDQualityOfServiceUserInteractive: return QOS_CLASS_USER_INTERACTIVE;
        case TDQualityOfServiceUserInitiated: return QOS_CLASS_USER_INITIATED;
        case TDQualityOfServiceUtility: return QOS_CLASS_UTILITY;
        case TDQualityOfServiceBackground: return QOS_CLASS_BACKGROUND;
        case TDQualityOfServiceDefault: return QOS_CLASS_DEFAULT;
        default: return QOS_CLASS_UNSPECIFIED;
    }
}
/*
 dispatch_queue_attr_make_with_qos_class(dispatch_queue_attr_t attr, dispatch_qos_class_t qos_class, int_relative_priority);
 返回一个属性，适用于创建一个想要的服务质量信息的调度队列。主要用于dispatch_queue_create函数。适用于OS X v10.10及以后或iOS v8.0及以后的版本。
 当你想要创建一个指定服务质量（QOS）级别的GCD队列的时候，在调用dispatch_queue_create函数之前先要调用本函数。这个函数结合了你指定的QOS信息的调度队列类型属性，并且返回了一个可以传递到dispatch_queue_create函数中的值。你通过这个函数指定了这个QOS的值，这个值要优先于从调度队列目标队列中继承的优先级
 全局队列的优先级与QOS的等级映射关系如下：
 DISPATCH_QUEUE_PRIORITY_HIGH  <===>  QOS_CLASS_USER_INITIATED
 DISPATCH_QUEUE_PRIORITY_DEFAULT    <===> QOS_CLASS_UTILITY
 DISPATCH_QUEUE_PRIORITY_LOW  <===> QOS_CLASS_UTILITY
 DISPATCH_QUEUE_PRIORITY_BACKGROUND  <===>  QOS_CLASS_BACKGROUND
 */
TD_INLINE dispatch_queue_attr_t __TDQoSToQueueAttributes(TDQualityOfService qos) {
    dispatch_qos_class_t qosClass = __TDQualityOfServiceToQOSClass(qos);
    //串行队列
    return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qosClass, 0);
};

TD_INLINE dispatch_queue_t __TDQualityOfServiceToDispatchQueue(TDQualityOfService qos, const char * queueName) {
    if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0) {
        dispatch_queue_attr_t attr = __TDQoSToQueueAttributes(qos);
        return dispatch_queue_create(queueName, attr);
    } else {
        //串行队列
        dispatch_queue_t queue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
        /*
         dispatch_set_target_queue(dispatch_object_t object, dispatch_queue_t queue);:给GCD对象设置目标队列，这个目标队列负责处理这个对象。目标对象决定了它是调用对象的终结器对象。此外，修改某些对象的目标队列可以改变它们的行为
         一个调度队列的优先级是继承自它的目标队列的。使用dispatch_get_global_queue函数去获得一个合适的目标队列，这个目标队列就是你所需的优先级。
         
         如果你提交一个block到一个串行队列中，并且这个串行队列的目标队列是一个不同的串行队列，那么这个block将不会与其他被提交到这个目标队列的block或者任何其他有相同目标队列的队列同时调用
         */
        dispatch_set_target_queue(queue, dispatch_get_global_queue(__TDQualityOfServiceToDispatchPriority(qos), 0));
        return queue;
    }
}

TD_INLINE DispatchContext __TDDispatchContextCreate(const char * name,
                                                      uint32_t queueCount,
                                                      TDQualityOfService qos) {
    /*
     void *calloc(size_t n, size_t size)；
      在内存的动态存储区中分配n个长度为size的连续空间，函数返回一个指向分配起始地址的指针；如果分配不成功，返回NUL
     一般使用后要使用 free(起始地址的指针) 对内存进行释放，不然内存申请过多会影响计算机的性能，以至于得重启电脑
     */
    DispatchContext context = calloc(1, sizeof(TDDispatchContext));
    if (context == NULL) { return NULL; }
    
    context->queues = calloc(queueCount, sizeof(void *));
    if (context->queues == NULL) {
        free(context);
        return NULL;
    }
    for (int idx = 0; idx < queueCount; idx++) {
        context->queues[idx] = (__bridge_retained void *)__TDQualityOfServiceToDispatchQueue(qos, name);
    }
    context->queueCount = queueCount;
    if (name) {
        context->name = strdup(name);
    }
    context->offset = 0;
    return context;
}

TD_INLINE void __TDDispatchContextRelease(DispatchContext context) {
    if (context == NULL) { return; }
    if (context->queues != NULL) { free(context->queues);  }
    if (context->name != NULL) { free((void *)context->name); }
    context->queues = NULL;
    if (context) { free(context); }
}

TD_INLINE dispatch_semaphore_t __TDSemaphore() {
    static dispatch_semaphore_t semaphore;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        semaphore = dispatch_semaphore_create(0);
    });
    return semaphore;
}
//取出队列
TD_INLINE dispatch_queue_t __TDDispatchContextGetQueue(DispatchContext context) {
    dispatch_semaphore_wait(__TDSemaphore(), dispatch_time(DISPATCH_TIME_NOW, DISPATCH_TIME_FOREVER));
    uint32_t offset = (uint32_t)OSAtomicIncrement32(&context->offset);
    dispatch_queue_t queue = (__bridge dispatch_queue_t)context->queues[offset % context->queueCount];
    dispatch_semaphore_signal(__TDSemaphore());
    if (queue) { return queue; }
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}
//获取上下文
TD_INLINE DispatchContext __TDDispatchContextGetForQos(TDQualityOfService qos) {
    static DispatchContext contexts[5];
    int count = (int)[NSProcessInfo processInfo].activeProcessorCount;
    count = MIN(1, MAX(count, TD_QUEUE_MAX_COUNT));
    switch (qos) {
        case TDQualityOfServiceUserInteractive: {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                contexts[0] = __TDDispatchContextCreate("com.tuandaiguo.user_interactive", count, qos);
            });
            return contexts[0];
        }
            
        case TDQualityOfServiceUserInitiated: {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                contexts[1] = __TDDispatchContextCreate("com.tuandaiguo.user_initated", count, qos);
            });
            return contexts[1];
        }
            
        case TDQualityOfServiceUtility: {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                contexts[2] = __TDDispatchContextCreate("com.tuandaiguo.utility", count, qos);
            });
            return contexts[2];
        }
            
        case TDQualityOfServiceBackground: {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                contexts[3] = __TDDispatchContextCreate("com.tuandaiguo.background", count, qos);
            });
            return contexts[3];
        }
            
        case TDQualityOfServiceDefault:
        default: {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                contexts[4] = __TDDispatchContextCreate("com.tuandaiguo.default", count, qos);
            });
            return contexts[4];
        }
    }
}

dispatch_queue_t TDDispatchQueueAsyncBlockInQOS(TDQualityOfService qos, dispatch_block_t block) {
    if (block == nil) { return NULL; }
    DispatchContext context = __TDDispatchContextGetForQos(qos);
    dispatch_queue_t queue = __TDDispatchContextGetQueue(context);
    dispatch_async(queue, block);
    return queue;
}

dispatch_queue_t TDDispatchQueueAsyncBlockInUserInteractive(dispatch_block_t block) {
    return TDDispatchQueueAsyncBlockInQOS(TDQualityOfServiceUserInteractive, block);
}

dispatch_queue_t TDDispatchQueueAsyncBlockInUserInitiated(dispatch_block_t block) {
    return TDDispatchQueueAsyncBlockInQOS(TDQualityOfServiceUserInitiated, block);
}

dispatch_queue_t TDDispatchQueueAsyncBlockInUtility(dispatch_block_t block) {
    return TDDispatchQueueAsyncBlockInQOS(TDQualityOfServiceUtility, block);
}

dispatch_queue_t TDDispatchQueueAsyncBlockInBackground(dispatch_block_t block) {
    return TDDispatchQueueAsyncBlockInQOS(TDQualityOfServiceBackground, block);
}

dispatch_queue_t TDDispatchQueueAsyncBlockInDefault(dispatch_block_t block) {
    return TDDispatchQueueAsyncBlockInQOS(TDQualityOfServiceDefault, block);
}
