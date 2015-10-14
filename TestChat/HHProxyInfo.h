//
//  SRProxyInfo.h
//  SocketRocket
//
//  Created by Hu, Hao on 12/10/15.
//
//


#import <Foundation/Foundation.h>



typedef void(^ProxyCompletion)(NSString* host, NSUInteger port, NSError* error);

@interface HHProxyInfo : NSObject


+(instancetype) proxyInfo;

@property(nonatomic,assign) BOOL isHTTPEnable;
@property(nonatomic,assign) NSUInteger HTTPProxyPort;
@property(nonatomic,copy) NSString* HTTPProxyHost;

@property(nonatomic,assign) BOOL isAutoConfigEnable;


@property(nonatomic,copy) NSString* autoConfigURL;

-(void) fetchProxyInfoForURL:(NSURL*) url completion:(ProxyCompletion) completion;


@end
