//
//  TDLoadingTimeMonitor.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/27.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDLoadingTimeMonitor : NSObject
+ (instancetype)sharedInstance;
- (void)updateData:(NSString *)loadingData;
@end
