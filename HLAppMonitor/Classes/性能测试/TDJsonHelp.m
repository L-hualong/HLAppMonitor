//
//  TDJsonHelp.m
//  Pods
//
//  Created by tuandai on 15/1/15.
//
//

#import "TDJsonHelp.h"

@implementation NSString (TDJSONKitSerializing)

- (NSData *)TDJSONData
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)objectFromTDJSONString
{
    __autoreleasing NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:[self TDJSONData]
                                                    options:NSJSONReadingAllowFragments
                                                      error:&error];
    
    if (error != nil) {
        NSLog(@"解析错误");
    }else
    {
        return jsonObject;
    }
    return nil;
}

///  兼容后台返回数据为NSString而不是NSArray、NSDictionary时 调用此方法会Crash的问题。
- (NSString *)TDJSONString {
    return self;
}

@end


@implementation NSArray (TDJSONKitSerializing)

- (NSData *)TDJSONData
{
    __autoreleasing NSError *error = nil;
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONReadingAllowFragments error:&error];
        
        if (error != nil) {
            NSLog(@"json系列化错误");
        }else
        {
            return data;
        }
    }
    NSLog(@"json系列化错误");
    
    return nil;
}

- (NSString *)TDJSONString
{
    NSString *result = [[NSString alloc] initWithData:[self TDJSONData]  encoding:NSUTF8StringEncoding];
    return result;
}

@end


@implementation NSDictionary (TDJSONKitSerializing)

- (NSData *)TDJSONData
{
    __autoreleasing NSError *error = nil;
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
        
        if (error != nil) {
            NSLog(@"json系列化错误");
        }else
        {
            return data;
        }
    }
    NSLog(@"json系列化错误");
    
    return nil;
}

- (NSString *)TDJSONString
{
    NSString *result = [[NSString alloc] initWithData:[self TDJSONData]    encoding:NSUTF8StringEncoding];
    
    do {
        result = [result stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"];
    } while ([result rangeOfString:@"\\\\"].location != NSNotFound);
    
    
    return result;
}


@end

@implementation NSData (TDJSONKitSerializing)

- (id)objectFromTDJSONData
{
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:self options:kNilOptions error:&error];
    if (error != nil)
    {
        return nil;
    }
    return result;
}

@end












