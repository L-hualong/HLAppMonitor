//
//  TDApplicationMemory.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct TDApplicationMemoryUsage
{
    double usage;   ///< 已用内存(MB)
    double total;   ///< 总内存(MB)
    double ratio;   ///< 占用比率
} TDApplicationMemoryUsage;

/*!
 *  @brief  应用内存占用
 */
@interface TDApplicationMemory : NSObject

- (TDApplicationMemoryUsage)currentUsage;
@end
