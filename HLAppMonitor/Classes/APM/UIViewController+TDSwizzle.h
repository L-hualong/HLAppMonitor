//
//  UIViewController+TDSwizzle.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (TDSwizzle)
@property(nonatomic,assign) CFAbsoluteTime viewLoadStartTime;
@end

NS_ASSUME_NONNULL_END
