//
//  TDTransaction.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/26.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 *  @brief  任务封装
 */
@interface TDTransaction : NSObject

+ (void)begin;
+ (void)commit;

@end
