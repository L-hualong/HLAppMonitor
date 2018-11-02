//
//  NSURLRequest+MSDoggerMonitor.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import "NSURLRequest+MSDoggerMonitor.h"
#import "GZIP/NSData+GZIP.h"
@implementation NSURLRequest (MSDoggerMonitor)

/*
  iOS 中 NSURLRequest 的 allHTTPHeaderFields 属性就对应上文提到的首部字段，HTTPBody 则对应报文主体
  但是allHTTPHeaderFields 并不包含在实际请求的全部首部字段，比如 Cookie，但 Cookie 是造成首部膨胀的罪魁祸首
 */
- (NSUInteger)dgm_getLineLength {
    NSString *lineStr = [NSString stringWithFormat:@"%@ %@ %@\n", self.HTTPMethod, self.URL.path, @"HTTP/1.1"];
    NSData *lineData = [lineStr dataUsingEncoding:NSUTF8StringEncoding];
    return lineData.length;
}
- (NSUInteger)dgm_getHeadersLengthWithCookie {
    NSUInteger headersLength = 0;
    
    NSDictionary<NSString *, NSString *> *headerFields = self.allHTTPHeaderFields;
    //对应 URL 的 Cookie 信息
    NSDictionary<NSString *, NSString *> *cookiesHeader = [self dgm_getCookies];
    
    // 添加 cookie 信息
    if (cookiesHeader.count) {
        NSMutableDictionary *headerFieldsWithCookies = [NSMutableDictionary dictionaryWithDictionary:headerFields];
        [headerFieldsWithCookies addEntriesFromDictionary:cookiesHeader];
        headerFields = [headerFieldsWithCookies copy];
    }
    NSLog(@"%@", headerFields);
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
    return headersLength;
}
- (NSDictionary<NSString *, NSString *> *)dgm_getCookies {
    NSDictionary<NSString *, NSString *> *cookiesHeader;
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    //只不过我们拿到 allHTTPHeaderFields 之后，会去调用 -[NSHTTPCookieStorage cookiesForURL:] 方法获得对应 URL 的 Cookie 信息，然后调用 -[NSHTTPCookie requestHeaderFieldsWithCookies:cookies] 以首部字段形式返回，最后将 Cookie 的首部字段加入 allHTTPHeaderFields 中，具体代码如下：
    NSArray<NSHTTPCookie *> *cookies = [cookieStorage cookiesForURL:self.URL];
    if (cookies.count) {
        cookiesHeader = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
    }
    return cookiesHeader;
}
//body
- (NSUInteger)dgm_getBodyLength {
    NSDictionary<NSString *, NSString *> *headerFields = self.allHTTPHeaderFields;
    NSUInteger bodyLength = [self.HTTPBody length];
    
    if ([headerFields objectForKey:@"Content-Encoding"]) {
        NSData *bodyData;
        if (self.HTTPBody == nil) {
            uint8_t d[1024] = {0};
            NSInputStream *stream = self.HTTPBodyStream;
            NSMutableData *data = [[NSMutableData alloc] init];
            [stream open];
            while ([stream hasBytesAvailable]) {
                NSInteger len = [stream read:d maxLength:1024];
                if (len > 0 && stream.streamError == nil) {
                    [data appendBytes:(void *)d length:len];
                }
            }
            bodyData = [data copy];
            [stream close];
        } else {
            bodyData = self.HTTPBody;
        }
        //模拟gzipp压缩
        bodyLength = [[bodyData gzippedData] length];
    }
    
    return bodyLength;
    //跟didi一样,跟charles比很正确
//    NSData *httpBody;
//    NSURLRequest *request = self;
//    if (request.HTTPBody) {
//        httpBody = request.HTTPBody;
//    }else{
//        if ([request.HTTPMethod isEqualToString:@"POST"]) {
//            if (!request.HTTPBody) {
//                uint8_t d[1024] = {0};
//                NSInputStream *stream = request.HTTPBodyStream;
//                NSMutableData *data = [[NSMutableData alloc] init];
//                [stream open];
//                while ([stream hasBytesAvailable]) {
//                    NSInteger len = [stream read:d maxLength:1024];
//                    if (len > 0 && stream.streamError == nil) {
//                        [data appendBytes:(void *)d length:len];
//                    }
//                }
//                httpBody = [data copy];
//                [stream close];
//            }
//        }
//    }
//    return [httpBody length];
}
@end
