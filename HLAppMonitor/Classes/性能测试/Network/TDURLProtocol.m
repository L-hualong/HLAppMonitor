//
//  TDURLProtocol.m
//  AFNetworking
//
//  Created by guoxiaoliang on 2018/10/17.
//

#import "TDURLProtocol.h"
#import "TDURLSessionConfiguration.h"
#import "TDNetworkTrafficLog.h"
#import "NSURLRequest+MSDoggerMonitor.h"
#import "NSURLResponse+MSDoggerMonitor.h"
#import "GZIP/NSData+GZIP.h"
#import "TDNetworkTrafficManager.h"
#import "TDNetFlowDataSource.h"
static NSString *const TDHTTP = @"GXLHTTP";

@interface TDURLProtocol() <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *dm_request;
@property (nonatomic, strong) NSURLResponse *dm_response;
@property (nonatomic, strong) NSMutableData *dm_data;
//毫秒
@property (nonatomic, assign) NSTimeInterval startTime;

@end
@implementation TDURLProtocol

#pragma mark - init
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}

+ (void)start {
    TDURLSessionConfiguration *sessionConfiguration = [TDURLSessionConfiguration defaultConfiguration];
    for (id protocolClass in [TDNetworkTrafficManager manager].protocolClasses) {
        [NSURLProtocol registerClass:protocolClass];
    }
    if (![sessionConfiguration isSwizzle]) {
        [sessionConfiguration load];
    }
}

+ (void)end {
    TDURLSessionConfiguration *sessionConfiguration = [TDURLSessionConfiguration defaultConfiguration];
    [NSURLProtocol unregisterClass:[TDURLProtocol class]];
    if ([sessionConfiguration isSwizzle]) {
        [sessionConfiguration unload];
    }
}


/**
 需要监控的请求
 @param request 此次请求
 @return 是否需要监控 
 */
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![request.URL.scheme isEqualToString:@"http"] && ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    // 拦截过的不再拦截
    if ([NSURLProtocol propertyForKey:TDHTTP inRequest:request] ) {
        return NO;
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableReqeust = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:TDHTTP
                     inRequest:mutableReqeust];
    return [mutableReqeust copy];
}

- (void)startLoading {
    NSURLRequest *request = [[self class] canonicalRequestForRequest:self.request];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    self.dm_request = self.request;
     self.startTime = [[NSDate date] timeIntervalSince1970] * 1000;
}

- (void)stopLoading {
    [self.connection cancel];
    
    TDNetworkTrafficLog *model = [[TDNetworkTrafficLog alloc] init];
    model.path = self.request.URL.path;
    model.host = self.request.URL.host;
    model.type = TDNetworkTrafficDataTypeResponse;
    model.lineLength = [self.dm_response dm_getLineLength];
    model.headerLength = [self.dm_response dm_getHeadersLength];
    if ([self.dm_response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self.dm_response;
        NSData *data = self.dm_data;
        if ([[httpResponse.allHeaderFields objectForKey:@"Content-Encoding"] isEqualToString:@"gzip"]) {
            data = [self.dm_data gzippedData];
        }
        model.bodyLength = data.length;
    }
    model.length = model.lineLength + model.headerLength + model.bodyLength;
    [model settingOccurTime];
    [[TDNetFlowDataSource shareInstance]addHttpModel:model];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    [self.client URLProtocol:self didFailWithError:error];
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection{
    return YES;
}

#pragma mark - NSURLConnectionDataDelegate

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
    if (response != nil) {
        self.dm_response = response;
        [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    }
    
    TDNetworkTrafficLog *model = [[TDNetworkTrafficLog alloc] init];
    model.path = request.URL.path;
    model.host = request.URL.host;
    model.type = TDNetworkTrafficDataTypeRequest;
    model.lineLength = [connection.currentRequest dgm_getLineLength];
    model.headerLength = [connection.currentRequest dgm_getHeadersLengthWithCookie];
    model.bodyLength = [connection.currentRequest dgm_getBodyLength];
    model.length = model.lineLength + model.headerLength + model.bodyLength;
    [model settingOccurTime];
    [[TDNetFlowDataSource shareInstance]addHttpModel:model];
    return request;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    self.dm_response = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    [self.dm_data appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [[self client] URLProtocolDidFinishLoading:self];
}

- (NSMutableData *)dm_data {
    if (_dm_data == nil) {
        _dm_data = [NSMutableData data];
    }
    return _dm_data;
}

@end
