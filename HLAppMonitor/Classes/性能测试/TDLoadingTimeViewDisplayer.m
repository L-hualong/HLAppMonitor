//
//  TDLoadingTimeViewDisplayer.m
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/27.
//  Copyright © 2018 Dee. All rights reserved.
//

#import "TDLoadingTimeViewDisplayer.h"
#import "TDDispatchAsync.h"
#import "TDAsyncLabel.h"

@interface TDLoadingTimeViewDisplayer ()
@property (nonatomic, strong) TDAsyncLabel * displayerLabel;
@end
@implementation TDLoadingTimeViewDisplayer

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
- (void)displayLoadingTime: (NSString *)loadingTime {
    
    TDDispatchQueueAsyncBlockInDefault(^{
        NSMutableAttributedString * attributed = [[NSMutableAttributedString alloc] initWithString: loadingTime attributes: @{ NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: _displayerLabel.font }];
       
        self.displayerLabel.attributedText = attributed;
    });
}

@end
