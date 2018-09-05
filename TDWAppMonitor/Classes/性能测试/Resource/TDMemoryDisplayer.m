//
//  TDMemoryDisplayer.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDMemoryDisplayer.h"
#import "TDDispatchAsync.h"
#import "TDAsyncLabel.h"

#define TD_HIGH_MEMORY_USAGE (([NSProcessInfo processInfo].physicalMemory / 1024 / 1024) / 2)
@interface TDMemoryDisplayer ()
@property (nonatomic, strong) TDAsyncLabel * displayerLabel;
@end
@implementation TDMemoryDisplayer

- (instancetype)initWithFrame: (CGRect)frame {
    if (self = [super initWithFrame: frame]) {
        CAShapeLayer * bgLayer = [CAShapeLayer layer];
        bgLayer.fillColor = [UIColor colorWithWhite: 0 alpha: 0.7].CGColor;
        bgLayer.path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame)) cornerRadius: 5].CGPath;
        [self.layer addSublayer: bgLayer];
        
        self.displayerLabel = [[TDAsyncLabel alloc] initWithFrame: self.bounds];
        self.displayerLabel.textColor = [UIColor whiteColor];
        self.displayerLabel.textAlignment = NSTextAlignmentCenter;
        self.displayerLabel.font = [UIFont fontWithName: @"Menlo" size: 14];
        [self addSubview: self.displayerLabel];
    }
    return self;
}

- (void)displayUsage: (double)usage {
    TDDispatchQueueAsyncBlockInBackground(^{
        NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%.1f", usage] attributes: @{ NSFontAttributeName: _displayerLabel.font, NSForegroundColorAttributeName: [UIColor colorWithHue: 0.27 * (0.8 - usage / TD_HIGH_MEMORY_USAGE) saturation: 1 brightness: 0.9 alpha: 1] }];
        [attributed appendAttributedString: [[NSAttributedString alloc] initWithString: @"MB" attributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: _displayerLabel.font }]];
        self.displayerLabel.attributedText = attributed;
    });
}


@end
