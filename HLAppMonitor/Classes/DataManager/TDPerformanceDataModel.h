//
//  TDPerformanceDataModel.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/28.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TDPerformanceDataModel : NSObject
//类别,1表示cup,2表示FPS,3表示内存大小,4表示页面停留时间
@property(nonatomic,strong)NSNumber *type;
@property(nonatomic,copy)NSString *currntTime;
@property(nonatomic,copy)NSString *content;


@end
