//
//  NSURLResponse+MSDoggerMonitor.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import "NSURLResponse+MSDoggerMonitor.h"
#import <dlfcn.h>
typedef CFHTTPMessageRef (*MSURLResponseGetHTTPResponse)(CFURLRef response);
@implementation NSURLResponse (MSDoggerMonitor)

- (NSString *)statusLineFromCF {
    NSURLResponse *response = self;
    NSString *statusLine = @"";
    // 获取CFURLResponseGetHTTPResponse的函数实现
    NSString *funName = @"CFURLResponseGetHTTPResponse";
    //c语言hook
    MSURLResponseGetHTTPResponse originURLResponseGetHTTPResponse =
    dlsym(RTLD_DEFAULT, [funName UTF8String]);
    
    SEL theSelector = NSSelectorFromString(@"_CFURLResponse");
    if ([response respondsToSelector:theSelector] &&
        NULL != originURLResponseGetHTTPResponse) {
        // 获取NSURLResponse的_CFURLResponse
        CFTypeRef cfResponse = CFBridgingRetain([response performSelector:theSelector]);
        if (NULL != cfResponse) {
            // 将CFURLResponseRef转化为CFHTTPMessageRef
            CFHTTPMessageRef messageRef = originURLResponseGetHTTPResponse(cfResponse);
            statusLine = (__bridge_transfer NSString *)CFHTTPMessageCopyResponseStatusLine(messageRef);
            CFRelease(cfResponse);
        }
    }
    return statusLine;
}
- (NSUInteger)dm_getLineLength {
    NSString *lineStr = @"";
    if ([self isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self;
        lineStr = [self statusLineFromCF];
    }
    NSData *lineData = [lineStr dataUsingEncoding:NSUTF8StringEncoding];
    return lineData.length;
}
- (NSUInteger)dm_getHeadersLength {
    NSUInteger headersLength = 0;
    if ([self isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self;
        NSDictionary<NSString *, NSString *> *headerFields = httpResponse.allHeaderFields;
        NSString *headerStr = @"";
        for (NSString *key in headerFields.allKeys) {
            headerStr = [headerStr stringByAppendingString:key];
            headerStr = [headerStr stringByAppendingString:@": "];
            if ([headerFields objectForKey:key]) {
                headerStr = [headerStr stringByAppendingString:headerFields[key]];
            }
            headerStr = [headerStr stringByAppendingString:@"\n"];
        }
        NSData *headerData = [headerStr dataUsingEncoding:NSUTF8StringEncoding];
        headersLength = headerData.length;
    }
    return headersLength;
}
@end
