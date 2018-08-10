//
//  TDAPMControllerMonitor.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/27.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDAPMControllerMonitor.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/ldsyms.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <mach-o/nlist.h>
#include <string.h>
#import <objc/message.h>
#import "TDLoadingTimeMonitor.h"
#import "TDPerformanceDataManager.h"
unsigned int tdCount;
const char **tdClasses;
static NSTimeInterval renderStartTime = 0;
@interface TDAPMControllerMonitor ()

@end
@implementation TDAPMControllerMonitor

+ (void)load {
    
    int imageCount = (int)_dyld_image_count();
    
    for(int iImg = 0; iImg < imageCount; iImg++) {
        
        const char* path = _dyld_get_image_name((unsigned)iImg);
        NSString *imagePath = [NSString stringWithUTF8String:path];
        
        NSBundle* mainBundle = [NSBundle mainBundle];
        NSString* bundlePath = [mainBundle bundlePath];
        
        if ([imagePath containsString:bundlePath] && ![imagePath containsString:@".dylib"]) {
            tdClasses = objc_copyClassNamesForImage(path, &tdCount);
            for (int i = 0; i < tdCount; i++) {
                NSString *className = [NSString stringWithCString:tdClasses[i] encoding:NSUTF8StringEncoding];
                
                if (![className isEqualToString:@""] && className && ![className hasPrefix:@"Assets"] && ![className hasPrefix:@"UI"]) {
                    Class cls = NSClassFromString(className);
                    if ([cls isSubclassOfClass:[UIViewController class]]) {
//                        NSLog(@"class:%@",cls);
                        
                        [self toHookAllMethod:cls];
                    }
                }
            }
        }
    }
}
+ (void)toHookAllMethod:(Class)cls {
    [self toHookLoadView:cls];
    [self toHookViewDidLoad:cls];
    [self toHookViewWillAppear:cls];
    [self toHookViewDidAppear:cls];
    [self toHookViewWillDisappear:cls];
    [self toHookViewDidDisappear:cls];
}

+ (void)toHookLoadView:(Class)class {
    SEL selector = @selector(loadView);
    
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    void (^swizzledBlock)(UIViewController *) = ^(UIViewController *viewController) {
        long long start = [self currentTime];
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 8) {
             ((void(*)(id, SEL))objc_msgSend)(viewController, swizzledSelector);
        }else{
            //ios8下特殊写法  
            ((void(*)(id,SEL, id,id))objc_msgSend)(viewController, swizzledSelector, nil, nil);  
        }
        long long end = [self currentTime];
//        NSTimeInterval cast = end - start;
//        NSDictionary *dict = @{@"type": [[NSNumber alloc]initWithInt:4],@"currntTime": [NSString stringWithFormat:@"%f",start],@"content":[[NSString alloc]initWithUTF8String:class_getName(class)]};
        //NSLog(@"swizzled loadView Start %@ %f %@",viewController.class,start,[[NSString alloc]initWithUTF8String:class_getName(class)]);
        NSString *className = [[NSString alloc]initWithUTF8String:class_getName(class)];
        NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@%p",className,class];
        [[TDPerformanceDataManager sharedInstance] syncExecuteClassName:className withStartTime:[NSString stringWithFormat:@"%lld",start] withEndTime:[NSString stringWithFormat:@"%lld",end] withHookMethod:@"loadView" withUniqueIdentifier: uniqueIdentifier];
    };
    [self replaceImplementationOfKnownSelector:selector onClass:class withBlock:swizzledBlock swizzledSelector:swizzledSelector];
}
+ (void)toHookViewDidLoad:(Class)class {
    SEL selector = @selector(viewDidLoad);
    
    SEL swizzledSelector = [self swizzledSelectorForSelector:selector];
    
    void (^swizzledBlock)(UIViewController *) = ^(UIViewController *viewController) {
        long long start = [self currentTime];
        renderStartTime = start;
        if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 8) {
            ((void(*)(id, SEL))objc_msgSend)(viewController, swizzledSelector);
        }else{
            //ios8下特殊写法  
            ((void(*)(id,SEL, id,id))objc_msgSend)(viewController, swizzledSelector, nil, nil);  
        }
        long long end = [self currentTime];
      //  NSLog(@"swizzled viewDidLoad %@ %f %@",viewController.class,cast,[[NSString alloc]initWithUTF8String:class_getName(class)]);
       // NSString *att1 = [NSString stringWithFormat:@"%@=%f",viewController.class,cast];
        //viewdidLoad加载时间
       // [[TDLoadingTimeMonitor sharedInstance] updateData:att1];
        NSString *className = [[NSString alloc]initWithUTF8String:class_getName(class)];
        NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@%p",className,class];
        [[TDPerformanceDataManager sharedInstance] syncExecuteClassName:className withStartTime:[NSString stringWithFormat:@"%lld",start] withEndTime:[NSString stringWithFormat:@"%lld",end] withHookMethod:@"viewDidLoad" withUniqueIdentifier: uniqueIdentifier];
    };
    [self replaceImplementationOfKnownSelector:selector onClass:class withBlock:swizzledBlock swizzledSelector:swizzledSelector];
}

+ (void)toHookViewWillAppear:(Class)class {
    SEL originalSelector = @selector(viewWillAppear:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    
    void (^swizzleBlock)(UIViewController *vc,BOOL animated) = ^(UIViewController *vc, BOOL animated) {
        long long start = [self currentTime];
        ((void(*)(id, SEL, BOOL))objc_msgSend)(vc, swizzledSelector, animated);
        long long end = [self currentTime];
//        NSTimeInterval cast = end - start;
//        NSLog(@"swizzled viewWillAppear %@ %f %@",vc.class,cast,[[NSString alloc]initWithUTF8String:class_getName(class)]);
        
    };
    [self replaceImplementationOfKnownSelector:originalSelector onClass:class withBlock:swizzleBlock swizzledSelector:swizzledSelector];
}

+ (void)toHookViewDidAppear:(Class)class {
    SEL originalSelector = @selector(viewDidAppear:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    
    void (^swizzleBlock)(UIViewController *vc,BOOL animated) = ^(UIViewController *vc, BOOL animated) {
        long long start = [self currentTime];
        ((void(*)(id, SEL, BOOL))objc_msgSend)(vc, swizzledSelector, animated);
        long long end = [self currentTime];
        long long renderTime = end - renderStartTime;
        NSString* renderStr = [[TDPerformanceDataManager sharedInstance] getRenderWithClassName:[[NSString alloc]initWithUTF8String:class_getName(class)] withRenderTime:[NSString stringWithFormat:@"%lld",renderTime]];
     //   [[TDPerformanceDataManager sharedInstance] normalDataStrAppendwith:renderStr];
//        NSTimeInterval cast = end - start;
//        NSLog(@"swizzled viewDidAppearStart %@ %f %@",vc.class,start,[[NSString alloc]initWithUTF8String:class_getName(class)]);
//        NSDictionary *dict = @{@"type": [[NSNumber alloc]initWithInt:4],@"currntTime": [NSString stringWithFormat:@"%f",start],@"content":[[NSString alloc]initWithUTF8String:class_getName(class)]};
        NSString *className = [[NSString alloc]initWithUTF8String:class_getName(class)];
        NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@%p",className,class];
        [[TDPerformanceDataManager sharedInstance] syncExecuteClassName:className withStartTime:[NSString stringWithFormat:@"%lld",start] withEndTime:[NSString stringWithFormat:@"%lld",end] withHookMethod:@"viewDidAppear" withUniqueIdentifier: uniqueIdentifier];
    };
    [self replaceImplementationOfKnownSelector:originalSelector onClass:class withBlock:swizzleBlock swizzledSelector:swizzledSelector];
}

+ (void)toHookViewWillDisappear:(Class)class {
    SEL originalSelector = @selector(viewWillDisappear:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    void (^swizzleBlock)(UIViewController *vc,BOOL animated) = ^(UIViewController *vc, BOOL animated) {
        long long start = [self currentTime];
        ((void(*)(id, SEL, BOOL))objc_msgSend)(vc, swizzledSelector, animated);
        long long end = [self currentTime];
        long long cast = end - start;
      //  NSLog(@"swizzled viewWillDisappear %@ %f %@",vc.class,cast,[[NSString alloc]initWithUTF8String:class_getName(class)]);
    };
    [self replaceImplementationOfKnownSelector:originalSelector onClass:class withBlock:swizzleBlock swizzledSelector:swizzledSelector];
}

+ (void)toHookViewDidDisappear:(Class)class {
    
    SEL originalSelector = @selector(viewDidDisappear:);
    SEL swizzledSelector = [self swizzledSelectorForSelector:originalSelector];
    //方法实现
    void (^swizzleBlock)(UIViewController *vc,BOOL animated) = ^(UIViewController *vc, BOOL animated) {
        long long start = [self currentTime];
        ((void(*)(id, SEL, BOOL))objc_msgSend)(vc, swizzledSelector, animated);
        long long end = [self currentTime];
        long long cast = end - start;
       // NSLog(@"swizzled viewDidDisappear %@ %f %@",vc.class,cast,[[NSString alloc]initWithUTF8String:class_getName(class)]);
//        NSDictionary *dict = @{@"type": [[NSNumber alloc]initWithInt:4],@"currntTime": [NSString stringWithFormat:@"%f",end],@"content":[[NSString alloc]initWithUTF8String:class_getName(class)]};
        NSString *className = [[NSString alloc]initWithUTF8String:class_getName(class)];
        NSString *uniqueIdentifier = [NSString stringWithFormat:@"%@%p",className,class];
        NSLog(@"class=%@",uniqueIdentifier);
        [[TDPerformanceDataManager sharedInstance] syncExecuteClassName: className withStartTime:[NSString stringWithFormat:@"%lld",start] withEndTime:[NSString stringWithFormat:@"%lld",end] withHookMethod:@"viewDidDisappear" withUniqueIdentifier: uniqueIdentifier];
    };
    [self replaceImplementationOfKnownSelector:originalSelector onClass:class withBlock:swizzleBlock swizzledSelector:swizzledSelector];
}


+ (BOOL)replaceImplementationOfKnownSelector:(SEL)originalSelector onClass:(Class)class withBlock:(id)block swizzledSelector:(SEL)swizzledSelector {
    //返回一个指定的特定类的实例方法。
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    if (!originalMethod) {
        return NO;
    }
#ifdef __IPHONE_6_0
    //创建一个指向函数的指针,调用方法被调用时指定的块。
    IMP implementation = imp_implementationWithBlock((id)block);
#else
    IMP implementation = imp_implementationWithBlock((__bridge void *)block);
#endif
    //方法交换应该保证唯一性和原子性,唯一性：应该尽可能在＋load方法中实现，这样可以保证方法一定会调用且不会出现异常。
   // 原子性：使用dispatch_once来执行方法交换，这样可以保证只运行一次。
    //给类添加一个方法
    class_addMethod(class, swizzledSelector, implementation, method_getTypeEncoding(originalMethod));
    //class_getInstanceMethod     得到类的实例方法,
    //class_getClassMethod          得到类的类方法 
    //获取类的实例方法
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    /*
     class_addMethod:动态给类添加一个方法
     cls：被添加方法的类
     name：可以理解为方法名，这个貌似随便起名，比如我们这里叫sayHello2
     imp：实现这个方法的函数
     types：一个定义该函数返回值类型和参数类型的字符串，这个具体会在后面讲
     
     //获取通过SEL获取一个方法class_getInstanceMethod
     
     //获取一个方法的实现 method_getImplementation
     //获取一个OC实现的编码类型method_getTypeEncoding
     //給方法添加实现class_addMethod
     //用一个方法的实现替换另一个方法的实现class_replaceMethod
     //交换两个方法的实现 method_exchangeImplementations
     
     class_addMethod:如果发现方法已经存在，会失败返回，也可以用来做检查用,我们这里是为了避免源方法没有实现的情况;如果方法没有存在,我们则先尝试添加被替换的方法的实现
     1.如果返回成功:则说明被替换方法没有存在.也就是被替换的方法没有被实现,我们需要先把这个方法实现,然后再执行我们想要的效果,用我们自定义的方法去替换被替换的方法. 这里使用到的是class_replaceMethod这个方法. class_replaceMethod本身会尝试调用class_addMethod和method_setImplementation，所以直接调用class_replaceMethod就可以了)
     
     2.如果返回失败:则说明被替换方法已经存在.直接将两个方法的实现交换即

     */
    //先尝试給源方法添加实现，这里是为了避免源方法没有实现的情况
    BOOL didAddMethod = class_addMethod(class,
                                        originalSelector,
                                        method_getImplementation(swizzledMethod),
                                        method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {//添加成功：将源方法的实现替换到交换方法的实现
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    }
    else {
        //添加失败：说明源方法已经有实现，直接将两个方法的实现交换即可
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    return YES;
}

+ (long long)currentTime {
   NSTimeInterval time = [[NSDate date] timeIntervalSince1970] * 1000;
   long long dTime = [[NSNumber numberWithDouble:time] longLongValue]; 
    return dTime;//[[NSDate date] timeIntervalSince1970] * 1000;
}

+ (SEL)swizzledSelectorForSelector:(SEL)selector {
    // 保证 selector 为唯一的，不然会死循环
    return NSSelectorFromString([NSString stringWithFormat:@"MA_Swizzle_%x_%llu_%@", arc4random(), [self currentTime], NSStringFromSelector(selector)]);
}

@end
