//
//  SRProxyInfo.m
//  SocketRocket
//
//  Created by Hu, Hao on 12/10/15.
//
//

#import "HHProxyInfo.h"

#define DEFAULT_TIMEOUT 3.0

ProxyCompletion _proxyCompletion;

@interface HHProxyInfo(){
    @private
   
}

@end

@implementation HHProxyInfo
+(instancetype) sharedInfo{
    static dispatch_once_t onceToken;
    
    static id instance;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    
    return instance;
    
}


-(instancetype) init{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}





+(instancetype) proxyInfo{
    
    HHProxyInfo* proxyInfo = [[HHProxyInfo alloc] init];
    NSDictionary* proxySettings =  CFBridgingRelease(CFNetworkCopySystemProxySettings());
    proxyInfo.isHTTPEnable = [proxySettings[(__bridge NSString*)kCFNetworkProxiesHTTPEnable] boolValue];
    proxyInfo.HTTPProxyPort =[proxySettings[(__bridge NSString*)kCFNetworkProxiesHTTPPort] unsignedIntegerValue];
    proxyInfo.HTTPProxyHost =proxySettings[(__bridge NSString*)kCFNetworkProxiesHTTPProxy];
    proxyInfo.isAutoConfigEnable =[proxySettings[(__bridge NSString*)kCFNetworkProxiesProxyAutoConfigEnable] boolValue];
   // proxyInfo.autoConfigScript = proxySettings[(__bridge NSString*)kCFNetworkProxiesProxyAutoConfigJavaScript];
    proxyInfo.autoConfigURL =proxySettings[(__bridge NSString*)kCFNetworkProxiesProxyAutoConfigURLString];
    return proxyInfo;
}


-(void) fetchProxyInfoForURL:(NSURL*) url completion:(ProxyCompletion) completion{
    
    if (!self.isAutoConfigEnable) {
        if (self.isHTTPEnable) {
            completion(self.HTTPProxyHost, self.HTTPProxyPort,nil);
            return;
        } else{
            NSLog(@"NO HTTP Proxy found.");
            completion(nil, -1, nil);
            return;
        }
    }
    
    
    _proxyCompletion = completion;
    
    BOOL finished = NO;
    
    CFStreamClientContext ctx = {10, &finished, NULL, NULL, NULL};
    
    
    NSURL* proxyURL = [NSURL URLWithString:self.autoConfigURL];
    CFRunLoopSourceRef rls = CFNetworkExecuteProxyAutoConfigurationURL((__bridge CFURLRef)(proxyURL), (__bridge CFURLRef)(url), __GetProxyCallBack, &ctx);
    CFStringRef mode = CFSTR("ProxyRunLoopMode");
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, mode);
    
    CFAbsoluteTime stopTime = CFAbsoluteTimeGetCurrent() + DEFAULT_TIMEOUT;
    
    do{
        CFRunLoopRunInMode(mode, 0.1, TRUE);
    }  while (!finished && CFAbsoluteTimeGetCurrent() < stopTime);
    
    if (finished && rls && CFRunLoopSourceIsValid(rls)) {
        CFRunLoopSourceInvalidate(rls);
    } else if (!finished) {
        NSLog(@"Report Error! timeout.");
    }
    
    if (rls) {
        CFRelease(rls);
    }
    
}


static void __GetProxyCallBack (void *client, CFArrayRef proxyList, CFErrorRef error) {
    
    bool *finished = client;
    *finished = YES;
    
    if (error != NULL) {
        NSError* nserr = (__bridge NSError*)error;
        NSLog(@"Report Error! Cannot get proxy. Reason is %@", nserr.localizedDescription);
        return;
    }
    
    NSArray* proxys =(__bridge NSArray*) proxyList;
    
    if (proxys.count != 0) {
        NSDictionary* firstProxy = proxys.firstObject;
        NSString *proxy = [firstProxy objectForKey:(id)kCFProxyHostNameKey];
        NSUInteger port = [[firstProxy objectForKey:(id)kCFProxyPortNumberKey] unsignedIntegerValue];
        _proxyCompletion(proxy, port, nil);
    } else {
        NSLog(@"No Proxy found.");
        _proxyCompletion(nil, -1, nil);
    }
    
}


@end
