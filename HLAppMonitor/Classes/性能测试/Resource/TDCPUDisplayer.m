//
//  TDCPUDisplayer.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDCPUDisplayer.h"
#import "TDDispatchAsync.h"
#import "TDAsyncLabel.h"

@interface TDCPUDisplayer ()
@property (nonatomic, strong) TDAsyncLabel * displayerLabel;
@end
@implementation TDCPUDisplayer

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

- (void)displayCPUUsage: (double)usage {
    int use = usage;
    TDDispatchQueueAsyncBlockInDefault(^{
        NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] initWithString: @"CPU" attributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: _displayerLabel.font }];
        [attributed appendAttributedString: [[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d%%", use] attributes: @{ NSFontAttributeName: _displayerLabel.font, NSForegroundColorAttributeName: [UIColor colorWithHue: 0.27 * (0.8 - (use / 100.)) saturation: 1 brightness: 0.9 alpha: 1] }]];
        self.displayerLabel.attributedText = attributed;
    });
}


@end
