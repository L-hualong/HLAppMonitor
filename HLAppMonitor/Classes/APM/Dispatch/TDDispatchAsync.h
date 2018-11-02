//
//  TDDispatchAsync.h
//  TuanDaiV4
//
//  Created by guoxiaoliang on 2018/6/25.
//  Copyright © 2018 Dee. All rights reserved.
//

#import <Foundation/Foundation.h>
/*
 用于指示系统工作的性质和重要性。使用更高质量的服务类接收更多的资源比工作时较低的服务质量类资源争用。
 NSQualityOfServiceUserInitiated:用于执行工作由用户显式地请求,并为结果必须立即提出,以便进行进一步的用户交互。例如,加载后的电子邮件用户已经选择消息列表
 NSQualityOfServiceUserInteractive:用于直接参与提供一个交互式UI。例如,处理控制事件或绘制到屏幕上。
 NSQualityOfServiceUtility:用于执行工作,用户不太可能立即等待结果。这项工作可能要求的用户或自动启动,并经常在用户可见使用一个非模态的进度时间表。例如,定期更新内容或批量文件操作,如媒体导入。
 NSQualityOfServiceBackground:用于工作,不是用户发起的或可见的。在一般情况下,用户并不知道这项工作甚至发生。例如,预抓取内容,搜索索引,备份,或与外部系统的数据同步
 NSQualityOfServiceDefault:表明你没有明确的服务质量信息。只要有可能,一个适当的服务质量决定可用的来源。否则,一些服务质量水平NSQualityOfServiceUserInteractive和NSQualityOfServiceUtility之间使用。
 */
typedef NS_ENUM(NSInteger, TDQualityOfService) {
    TDQualityOfServiceUserInteractive = NSQualityOfServiceUserInteractive,
    TDQualityOfServiceUserInitiated = NSQualityOfServiceUserInitiated,
    TDQualityOfServiceUtility = NSQualityOfServiceUtility,
    TDQualityOfServiceBackground = NSQualityOfServiceBackground,
    TDQualityOfServiceDefault = NSQualityOfServiceDefault,
};


dispatch_queue_t TDDispatchQueueAsyncBlockInQOS(TDQualityOfService qos, dispatch_block_t block);
dispatch_queue_t TDDispatchQueueAsyncBlockInUserInteractive(dispatch_block_t block);
dispatch_queue_t TDDispatchQueueAsyncBlockInUserInitiated(dispatch_block_t block);
dispatch_queue_t TDDispatchQueueAsyncBlockInBackground(dispatch_block_t block);
dispatch_queue_t TDDispatchQueueAsyncBlockInDefault(dispatch_block_t block);
dispatch_queue_t TDDispatchQueueAsyncBlockInUtility(dispatch_block_t block);
