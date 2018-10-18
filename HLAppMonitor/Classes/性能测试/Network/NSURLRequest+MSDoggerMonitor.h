//
//  NSURLRequest+MSDoggerMonitor.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLRequest (MSDoggerMonitor)
- (NSUInteger)dgm_getLineLength;
- (NSUInteger)dgm_getHeadersLengthWithCookie;
- (NSDictionary<NSString *, NSString *> *)dgm_getCookies;
- (NSUInteger)dgm_getBodyLength;
@end

NS_ASSUME_NONNULL_END
