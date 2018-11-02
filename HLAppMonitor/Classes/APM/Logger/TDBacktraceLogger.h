//
//  TDBacktraceLogger.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/26.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TDLOG NSLog(@"%@",[TDBacktraceLogger td_backtraceOfCurrentThread]);
#define TDLOG_MAIN NSLog(@"%@",[TDBacktraceLogger td_backtraceOfMainThread]);
#define TDLOG_ALL NSLog(@"%@",[TDBacktraceLogger td_backtraceOfAllThread]);

/*!
 *  @brief  线程堆栈上下文输出
 */
@interface TDBacktraceLogger : NSObject

+ (NSString *)td_backtraceOfAllThread;
+ (NSString *)td_backtraceOfCurrentThread;
+ (NSString *)td_backtraceOfMainThread;
+ (NSString *)td_backtraceOfNSThread:(NSThread *)thread;
@end
