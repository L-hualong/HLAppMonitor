//
//  TDFPSDisplayer.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDFPSDisplayer.h"
#import "TDAsyncLabel.h"
#import "TDDispatchAsync.h"
#define TD_FPS_DISPLAYER_SIZE CGSizeMake(54, 20)
@interface TDFPSDisplayer ()
@property (nonatomic, strong) TDAsyncLabel * fpsDisplayer;
@end
@implementation TDFPSDisplayer

- (instancetype)init {
    if (self = [super initWithFrame: CGRectMake((CGRectGetWidth([UIScreen mainScreen].bounds) - TD_FPS_DISPLAYER_SIZE.width) / 2, 30, TD_FPS_DISPLAYER_SIZE.width, TD_FPS_DISPLAYER_SIZE.height)]) {
        CAShapeLayer * bgLayer = [CAShapeLayer layer];
        bgLayer.fillColor = [UIColor colorWithWhite: 0 alpha: 0.7].CGColor;
        bgLayer.path = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, TD_FPS_DISPLAYER_SIZE.width, TD_FPS_DISPLAYER_SIZE.height) cornerRadius: 5].CGPath;
        [self.layer addSublayer: bgLayer];
        
        self.fpsDisplayer = [[TDAsyncLabel alloc] initWithFrame: self.bounds];
        self.fpsDisplayer.textColor = [UIColor whiteColor];
        self.fpsDisplayer.textAlignment = NSTextAlignmentCenter;
        self.fpsDisplayer.font = [UIFont fontWithName: @"Menlo" size: 14];
        [self updateFPS: 60];
        [self addSubview: self.fpsDisplayer];
    }
    return self;
}

- (void)updateFPS: (int)fps {
    TDDispatchQueueAsyncBlockInDefault(^{
        NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] initWithString: [NSString stringWithFormat: @"%d", fps] attributes: @{ NSForegroundColorAttributeName: [UIColor colorWithHue: 0.27 * (fps / 60.0 - 0.2) saturation: 1 brightness: 0.9 alpha: 1], NSFontAttributeName: _fpsDisplayer.font }];
        [attributed appendAttributedString: [[NSAttributedString alloc] initWithString: @"FPS" attributes: @{ NSFontAttributeName: _fpsDisplayer.font, NSForegroundColorAttributeName: [UIColor whiteColor] }]];
        self.fpsDisplayer.attributedText = attributed;
    });
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
