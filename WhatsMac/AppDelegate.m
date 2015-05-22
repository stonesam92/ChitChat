#import "AppDelegate.h"
#import "WKWebView+Private.h"
#import "WAMWebView.h"

@import WebKit;
@import Sparkle;

@interface AppDelegate () <NSWindowDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSView* titlebarView;
@property (weak, nonatomic) NSWindow *legal;
@property (weak, nonatomic) NSWindow *faq;
@property (strong, nonatomic) NSString *notificationCount;
@end

@implementation AppDelegate

- (WKWebViewConfiguration*)webViewConfig {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    // inject js into webview
    NSURL *pathToJS = [[NSBundle mainBundle] URLForResource:@"inject" withExtension:@"js"];
    NSString *injectedJS = [NSString stringWithContentsOfURL:pathToJS encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:injectedJS
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                   forMainFrameOnly:NO];
    [contentController addUserScript:userScript];
    [contentController addScriptMessageHandler:self name:@"notification"];
    config.userContentController = contentController;
    
    #if DEBUG
    [config.preferences setValue:@YES forKey:@"developerExtrasEnabled"];
    #else
    WKUserScript *noRightClickJS = [[WKUserScript alloc] initWithSource:
                                    @"document.addEventListener('contextmenu',"
                                    "function(event) {"
                                        "event.preventDefault();"
                                    "});"
                                                          injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                       forMainFrameOnly:NO];
    [contentController addUserScript:noRightClickJS];
    #endif
    return config;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSInteger windowStyleFlags = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask | NSFullSizeContentViewWindowMask;
    _notificationCount = @"";
    _window = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, 800, 600)
                                          styleMask:windowStyleFlags
                                            backing:NSBackingStoreBuffered
                                              defer:YES];
    _window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    _window.titleVisibility = NSWindowTitleHidden;
    _window.titlebarAppearsTransparent = YES;
    _window.minSize = CGSizeMake(640, 400);
    _window.releasedWhenClosed = NO;
    _window.delegate = self;
    _window.frameAutosaveName = @"main";
    _window.movableByWindowBackground = YES;
    _window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    [_window center];
    
    _titlebarView = [_window standardWindowButton:NSWindowCloseButton].superview;
    [self updateWindowTitlebar];

    _webView = [[WAMWebView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                  configuration:[self webViewConfig]];
    
    _window.contentView = _webView;
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    
    //Whatsapp web only works with specific user agents
    _webView._customUserAgent = @"Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36";
    
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://web.whatsapp.com"]];
    [_webView loadRequest:urlRequest];
    [_window makeKeyAndOrderFront:self];
    
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    [self.window makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    [self.window makeKeyAndOrderFront:self];
    return YES;
}

- (void)windowDidResize:(NSNotification *)notification {
    [self updateWindowTitlebar];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    NSString *title = change[NSKeyValueChangeNewKey];
    if ([title isEqualToString:@"WhatsApp Web"]) {
        self.notificationCount = @"";
    } else {
        NSRegularExpression* regex =
        [NSRegularExpression regularExpressionWithPattern:@"\\(([0-9]+)\\) WhatsApp Web"
                                                  options:0
                                                    error:nil];
        NSTextCheckingResult* match = [regex firstMatchInString:title
                                                        options:0
                                                          range:NSMakeRange(0, title.length)];
        if (match) {
            self.notificationCount = [title substringWithRange:[match rangeAtIndex:1]];
        }
    }
}

- (NSWindow*)legal {
    if (!_legal) {
        _legal = [self createWindow:@"legal" title:@"Legal" URL:@"https://www.whatsapp.com/legal/"];
    }
    return _legal;
}

- (NSWindow*)faq {
    if (!_faq) {
        _faq = [self createWindow:@"faq" title:@"FAQ" URL:@"http://www.whatsapp.com/faq/web"];
    }
    return _faq;
}

- (void)setNotificationCount:(NSString *)notificationCount {
    if (![_notificationCount isEqualToString:notificationCount]) {
        [[NSApp dockTile] setBadgeLabel:notificationCount];
    }
    _notificationCount = notificationCount;
}

#pragma mark MenuBar Actions
- (IBAction)find:(NSMenuItem*)sender {
    [self.webView evaluateJavaScript:@"activateSearchField();"
                   completionHandler:nil];
}

- (IBAction)newConversation:(NSMenuItem*)sender {
    [self.webView evaluateJavaScript:@"newConversation();"
                   completionHandler:nil];
}

- (IBAction)showLegal:(id)sender {
    [self.legal makeKeyAndOrderFront:self];
}

- (IBAction)showFAQ:(id)sender {
    [self.faq makeKeyAndOrderFront:self];
}

- (IBAction)reloadPage:(id)sender {
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://web.whatsapp.com"]];
    [self.webView loadRequest:urlRequest];
}

- (void)setActiveConversationAtIndex:(NSString*)index {
    [self.webView evaluateJavaScript:
     [NSString stringWithFormat:@"setActiveConversationAtIndex(%@)", index]
                   completionHandler:nil];
}

#pragma mark WebView Delegate Methods


- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL;
    
    if ([url.host hasSuffix:@"whatsapp.com"] || [url.host hasSuffix:@"whatsapp.net"] ||
        [url.scheme isEqualToString:@"file"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

- (void)webView:(WKWebView*)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Failed navigation with error: %@", error);
    [self showFailedConnectionPage];
}

- (void)webView:(WKWebView*)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"Failed navigation with error: %@", error);
    [self showFailedConnectionPage];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [[NSWorkspace sharedWorkspace] openURL:navigationAction.request.URL];
    }
    
    return nil;
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSURLResponse *response = (NSHTTPURLResponse*)navigationResponse.response;
    
    if ([response.URL.host hasSuffix:@"whatsapp.net"] &&
        [response isKindOfClass:[NSHTTPURLResponse class]]) {
        
        decisionHandler(WKNavigationResponsePolicyCancel);
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        NSString *contentDisposition = httpResponse.allHeaderFields[@"Content-Disposition"];
        if ([contentDisposition hasPrefix:@"attachment"]) {
            NSString *filename = [contentDisposition componentsSeparatedByString:@"\""][1];
            [self downloadMedia:httpResponse.URL filename:filename];
        } else {
            //media link no longer valid
            NSLog(@"media no longer available");
        }
    } else {
        //else it is an internal web.whatsapp.com page
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSArray *messageBody = message.body;
    NSUserNotification *notification = [NSUserNotification new];
    notification.title = messageBody[0];
    notification.subtitle = messageBody[1];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

# pragma mark Utils
- (void)updateWindowTitlebar {
    const CGFloat kTitlebarHeight = 59;
    const CGFloat kFullScreenButtonYOrigin = 3;
    CGRect windowFrame = _window.frame;
    BOOL fullScreen = (_window.styleMask & NSFullScreenWindowMask) == NSFullScreenWindowMask;
    
    // Set size of titlebar container
    NSView *titlebarContainerView = _titlebarView.superview;
    CGRect titlebarContainerFrame = titlebarContainerView.frame;
    titlebarContainerFrame.origin.y = windowFrame.size.height - kTitlebarHeight;
    titlebarContainerFrame.size.height = kTitlebarHeight;
    titlebarContainerView.frame = titlebarContainerFrame;
    
    // Set position of window buttons
    CGFloat buttonX = 12; // initial LHS margin, matching Safari 8.0 on OS X 10.10.
    NSView *closeButton = [self.window standardWindowButton:NSWindowCloseButton];
    NSView *minimizeButton = [self.window standardWindowButton:NSWindowMiniaturizeButton];
    NSView *zoomButton = [self.window standardWindowButton:NSWindowZoomButton];
    for (NSView *buttonView in @[closeButton, minimizeButton, zoomButton]){
        CGRect buttonFrame = buttonView.frame;
        
        // in fullscreen, the titlebar frame is not governed by kTitlebarHeight but rather appears to be fixed by the system.
        // thus, we set a constant Y origin for the buttons when in fullscreen.
        buttonFrame.origin.y = fullScreen ?
        kFullScreenButtonYOrigin :
        round((kTitlebarHeight - buttonFrame.size.height) / 2.0);
        
        buttonFrame.origin.x = buttonX;
        
        // spacing for next button, matching Safari 8.0 on OS X 10.10.
        buttonX += buttonFrame.size.width + 6;
        
        [buttonView setFrameOrigin:buttonFrame.origin];
    };
    
}

- (void)downloadMedia:(NSURL*)mediaURL filename:(NSString*)filename{
    NSString *pathToDownload = [NSString stringWithFormat:@"~/Downloads/%@", filename];
    NSData *mediaData = [NSData dataWithContentsOfURL:mediaURL];
    [mediaData writeToFile:[pathToDownload stringByExpandingTildeInPath] atomically:YES];
}

- (NSWindow*)createWindow:(NSString*)identifier title:(NSString*)title URL:(NSString*)url {
    NSUInteger windowStyle = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSFullSizeContentViewWindowMask;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectMake(0, 0, 1040, 800) styleMask:windowStyle backing:NSBackingStoreBuffered defer:YES];
    window.minSize = CGSizeMake(200, 100);
    [window center];
    window.frameAutosaveName = identifier;
    window.title = title;
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [webView setFrame:[window.contentView bounds]];
    webView.translatesAutoresizingMaskIntoConstraints = YES;
    webView.autoresizesSubviews = YES;
    webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    window.contentView = webView;
    
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [webView loadRequest:req];
    
    window.releasedWhenClosed = YES;
    CFBridgingRetain(window);
    return window;
}

- (void)showFailedConnectionPage {
    NSURL *failedPageURL = [[NSBundle mainBundle] URLForResource:@"noConnection" withExtension:@"html"];
    NSURLRequest *failedPageRequest = [NSURLRequest requestWithURL:failedPageURL];
    [self.webView loadRequest:failedPageRequest];
}
@end
