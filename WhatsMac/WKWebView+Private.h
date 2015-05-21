#import <WebKit/WebKit.h>

@interface WKWebView (Private)
@property (copy, setter=_setCustomUserAgent:) NSString *_customUserAgent;
@end
