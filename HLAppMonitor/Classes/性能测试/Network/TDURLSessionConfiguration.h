//
//  TDURLSessionConfiguration.h
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TDURLSessionConfiguration : NSObject


@property (nonatomic,assign) BOOL isSwizzle;

+ (TDURLSessionConfiguration *)defaultConfiguration;

/**
 *  swizzle NSURLSessionConfiguration's protocolClasses method
 */
- (void)load;

/**
 *  make NSURLSessionConfiguration's protocolClasses method is normal
 */
- (void)unload;

@end

NS_ASSUME_NONNULL_END
