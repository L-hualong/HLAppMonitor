//
//  TDFPSMonitor.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDFPSMonitor : NSObject

+ (instancetype)sharedMonitor;

- (void)startMonitoring;
- (void)stopMonitoring;
//获取帧率
- (double)getFPS;
@end
