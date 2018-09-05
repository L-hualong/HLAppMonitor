//
//  TDCPUDisplayer.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <UIKit/UIKit.h>


/*!
 *  @brief  CPU占用展示器
 */
@interface TDCPUDisplayer : UIView

- (void)displayCPUUsage: (double)usage;
@end
