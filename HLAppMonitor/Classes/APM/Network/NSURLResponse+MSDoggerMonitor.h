//
//  NSURLResponse+MSDoggerMonitor.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLResponse (MSDoggerMonitor)
- (NSString *)statusLineFromCF;
- (NSUInteger)dm_getLineLength;
- (NSUInteger)dm_getHeadersLength;
@end

NS_ASSUME_NONNULL_END
