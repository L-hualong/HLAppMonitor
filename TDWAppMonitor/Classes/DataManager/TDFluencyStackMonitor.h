//
//  TDFluencyStackMonitor.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/8/15.
//

#import <Foundation/Foundation.h>

@interface TDFluencyStackMonitor : NSObject

//堆栈信息
@property(nonatomic ,strong)NSMutableArray *backtraceLoggerArray;
+ (instancetype)sharedInstance;
- (void)startWithThresholdTime:(double)threshold;
- (void)stop;
@end
