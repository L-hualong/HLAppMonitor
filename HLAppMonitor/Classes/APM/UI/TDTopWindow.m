//
//  TDTopWindow.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDTopWindow.h"
static TDTopWindow * lxd_top_window;

@implementation TDTopWindow

+ (instancetype)topWindow {
#if DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lxd_top_window = [[super allocWithZone: NSDefaultMallocZone()] initWithFrame: [UIScreen mainScreen].bounds];
    });
#endif
    return lxd_top_window;
}

+ (instancetype)allocWithZone: (struct _NSZone *)zone {
    return [self topWindow];
}

- (instancetype)copy {
    return [[self class] topWindow];
}

- (instancetype)initWithFrame: (CGRect)frame {
    if (self = [super initWithFrame: frame]) {
        [super setUserInteractionEnabled: NO];
        [super setWindowLevel: CGFLOAT_MAX];
        
        self.rootViewController = [UIViewController new];
        [self makeKeyAndVisible];
    }
    return self;
}

- (void)setWindowLevel: (UIWindowLevel)windowLevel { }
- (void)setBackgroundColor: (UIColor *)backgroundColor { }
- (void)setUserInteractionEnabled: (BOOL)userInteractionEnabled { }


@end
