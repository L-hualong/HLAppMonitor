//
//  TDLoadingTimeMonitor.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/27.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDLoadingTimeMonitor.h"
//#import "TDDispatchAsync.h"

#import "TDLoadingTimeViewDisplayer.h"
#import "TDTopWindow.h"
#import "TDGlobalTimer.h"
@interface TDLoadingTimeMonitor ()
@property (nonatomic, strong) TDLoadingTimeViewDisplayer * loadingTimeView;
@end
@implementation TDLoadingTimeMonitor

+ (instancetype)sharedInstance
{
    static TDLoadingTimeMonitor * instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[TDLoadingTimeMonitor alloc] init];
        [instance startMonitoring];
    });
    return instance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        _loadingTimeView = [[TDLoadingTimeViewDisplayer alloc]initWithFrame:CGRectMake(0, 60, UIScreen.mainScreen.bounds.size.width, 20)];
      //  CGFloat centerX = round(CGRectGetWidth([UIScreen mainScreen].bounds) / 4);
//        _loadingTimeView.center = CGPointMake(centerX, _loadingTimeView.center.y);
    }
    return self;
}
static NSString * td_loadingTime_monitor_callback_key;
- (void)updateData:(NSString *)loadingData {
    if (self) {
        [self.loadingTimeView displayLoadingTime:loadingData];
        NSLog(@"有值了");
    }
}
- (void)startMonitoring {
    
    [[TDTopWindow topWindow] addSubview: self.loadingTimeView];
}

- (void)stopMonitoring {
    [self.loadingTimeView removeFromSuperview];
    
}
@end
