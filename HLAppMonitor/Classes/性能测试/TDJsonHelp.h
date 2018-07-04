//
//  TDJsonHelp.h
//  Pods
//
//  Created by tuandai on 15/1/15.
//
//

#import <Foundation/Foundation.h>

#pragma mark Serializing methods
////////////

@interface NSString (TDJSONKitSerializing)


/**
 *  NSString转化为data
 */

- (NSData *)TDJSONData;

/**
 *  jsonString转化为数组，或字典
 */

- (id)objectFromTDJSONString;

@end

@interface NSArray (TDJSONKitSerializing)

/**
 *  数组转化为data
 */

- (NSData *)TDJSONData;

/**
 *  数组转化为jsonString
 */

- (NSString *)TDJSONString;

@end


@interface NSDictionary (TDJSONKitSerializing)

/**
 *  字典转换为data
 */

- (NSData *)TDJSONData;

/**
 *  字典转换为jsonString
 */

- (NSString *)TDJSONString;

@end

@interface NSData (TDJSONKitDeserializing)

/**
 *  JsonData转换为不可变数组，字典
 */

- (id)objectFromTDJSONData;

@end
