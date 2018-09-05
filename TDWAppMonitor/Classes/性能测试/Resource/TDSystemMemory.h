//
//  TDSystemMemory.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct TDSystemMemoryUsage
{
    double free;    ///< 自由内存(MB)
    double wired;   ///< 固定内存(MB)
    double active;  ///< 正在使用的内存(MB)
    double inactive;    ///< 缓存、后台内存(MB)
    double compressed;  ///< 压缩内存(MB)
    double total;   ///< 总内存(MB)
} TDSystemMemoryUsage;

/*!
 *  @brief  系统内存使用
 */
@interface TDSystemMemory : NSObject

- (TDSystemMemoryUsage)currentUsage;
@end
