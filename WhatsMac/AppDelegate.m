#import "AppDelegate.h"
#import "WKWebView+Private.h"
#import "WAMWebView.h"
#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@import WebKit;
@import Sparkle;

NSString *const _AppleActionOnDoubleClickKey = @"AppleActionOnDoubleClick";
NSString *const _AppleActionOnDoubleClickNotification = @"AppleNoRedisplayAppearancePreferenceChanged";
NSString* const WAMShouldHideStatusItem = @"WAMShouldHideStatusItem";

@interface AppDelegate () <NSWindowDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, NSUserNotificationCenterDelegate>
@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenuItem *statusItemToggle;
@property (weak, nonatomic) NSWindow *legal;
@property (weak, nonatomic) NSWindow *faq;
@property (strong, nonatomic) NSString *notificationCount;
@property (nonatomic) NSPoint initialDragPosition;
@property (nonatomic) BOOL isDragging;
@property (nonatomic) BOOL doubleClickShouldMinimize;
@end

@implementation AppDelegate

- (WKWebViewConfiguration*)webViewConfig {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *contentController = [[WKUserContentController alloc] init];
    // inject js into webview
    NSURL *pathToJS = [[NSBundle mainBundle] URLForResource:@"inject" withExtension:@"js"];
    NSString *injectedJS = [NSString stringWithContentsOfURL:pathToJS encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:injectedJS
                                                      injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                   forMainFrameOnly:NO];
    NSURL *jqueryURL = [[NSBundle mainBundle] URLForResource:@"jquery" withExtension:@"js"];
    NSString *jquery = [NSString stringWithContentsOfURL:jqueryURL encoding:NSUTF8StringEncoding error:nil];
    WKUserScript *jqueryUserScript = [[WKUserScript alloc] initWithSource:jquery
                                                            injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:NO];
    [contentController addUserScript:jqueryUserScript];
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
    [_window center];
    _window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    _window.titleVisibility = NSWindowTitleHidden;
    _window.titlebarAppearsTransparent = YES;
    _window.minSize = CGSizeMake(640, 400);
    _window.releasedWhenClosed = NO;
    _window.delegate = self;
    _window.frameAutosaveName = @"main";
    _window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
  
    [self updateTitlebarOfWindow:_window fullScreen:NO];
    
    [self doubleClickPreferenceDidChange:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(doubleClickPreferenceDidChange:) name:_AppleActionOnDoubleClickNotification object:nil];
  
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:WAMShouldHideStatusItem]];
    if (![defaults boolForKey:WAMShouldHideStatusItem]) {
      [self createStatusItem];
    } else {
      [self.statusItemToggle setTitle:@"Show Status Icon"];
    }

    _webView = [[WAMWebView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)
                                  configuration:[self webViewConfig]];
    
    _window.contentView = _webView;
    _webView.UIDelegate = self;
    _webView.navigationDelegate = self;
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    
    //Whatsapp web only works with specific user agents
    _webView._customUserAgent = @"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/8.0.7 Safari/600.7.12";
  
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://web.whatsapp.com"]];
    [_webView loadRequest:urlRequest];
    [_window makeKeyAndOrderFront:self];

    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate: self];
    
    [[SUUpdater sharedUpdater] checkForUpdatesInBackground];
}

- (BOOL)shouldPropagateMouseDraggedEvent:(NSEvent*)theEvent {
    if (![theEvent.window isEqual:_window]) {
      return YES;
    }
    
    if (!_isDragging) {
      _isDragging = YES;
      _initialDragPosition = theEvent.locationInWindow;
    }
    
    if (_initialDragPosition.y < (_window.frame.size.height - 59)) {
      return YES;
    }
    
    NSPoint mouseLocation = [NSEvent mouseLocation];
    NSRect newFrame = NSRectFromCGRect(_window.frame);
    newFrame.origin.x = mouseLocation.x - _initialDragPosition.x;
    newFrame.origin.y = mouseLocation.y - _initialDragPosition.y;

    [_window.animator setFrame:newFrame display:YES animate:NO];
    
    return NO;
}

- (BOOL)shouldPropagateMouseUpEvent:(NSEvent *)theEvent {
    if (_isDragging) {
      _isDragging = NO;
      return NO;
    }
    
    if (theEvent.locationInWindow.y >= (_window.frame.size.height - 59)) {
      if (theEvent.clickCount == 2) {
        if (_doubleClickShouldMinimize) {
          [_window miniaturize:self];
        } else {
          [_window zoom:self];
        }
        return NO;
      }
    }
    
    return YES;
}

- (void)doubleClickPreferenceDidChange:(NSNotification*)notification {
    _doubleClickShouldMinimize = [[[NSUserDefaults standardUserDefaults] stringForKey: _AppleActionOnDoubleClickKey] isEqualToString:@"Minimize"] ? YES : NO;
}

- (void)createStatusItem {
    NSImage* image = [NSImage imageNamed:@"statusIconRead"];
    [image setTemplate:YES];

    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [self.statusItem.button setImage:image];
    self.statusItem.button.action = @selector(showAppWindow:);
}

- (IBAction)toggleStatusItem:(id)sender {
    if (self.statusItem != nil) {
      self.statusItem = nil;
      [self.statusItemToggle setTitle:@"Show Status Icon"];
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:WAMShouldHideStatusItem];
    } else {
      [self createStatusItem];
      [self.statusItemToggle setTitle:@"Hide Status Icon"];
      [[NSUserDefaults standardUserDefaults] setBool:NO forKey:WAMShouldHideStatusItem];
    }
}

- (void)showAppWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
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

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    [self updateTitlebarOfWindow:_window fullScreen:YES];
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    [self updateTitlebarOfWindow:_window fullScreen:NO];
}

- (void)windowDidResize:(NSNotification *)notification {
    [self updateTitlebarOfWindow:_window fullScreen:NO];
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
        
        NSInteger badgeCount = notificationCount.integerValue;
        
        if (badgeCount) {
            NSImage* image = [NSImage imageNamed:@"statusIconUnread"];
            [self.statusItem.button setImage:image];
        } else {
            NSImage* image = [NSImage imageNamed:@"statusIconRead"];
            [image setTemplate:YES];

            [self.statusItem.button setImage:image];
            [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
        }
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
    
    if ([url.host hasSuffix:@"whatsapp.com"] || [url.scheme isEqualToString:@"file"]) {
        decisionHandler(WKNavigationActionPolicyAllow);
    } else if ([url.host hasSuffix:@"whatsapp.net"]) {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        NSAlert *downloadMediaAlert = [[NSAlert alloc] init];
        downloadMediaAlert.messageText = @"Downloading Media";
        downloadMediaAlert.informativeText = @"To download media, please just drag and drop it from this window into Finder.";
        [downloadMediaAlert addButtonWithTitle:@"OK"];
        [downloadMediaAlert runModal];
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

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([[self window] isMainWindow]) {
        return;
    }
    NSArray *messageBody = message.body;
    NSUserNotification *notification = [NSUserNotification new];
    notification.hasReplyButton = true;
    notification.responsePlaceholder = @"Reply...";
    notification.title = messageBody[0];
    notification.subtitle = messageBody[1];
    notification.identifier = messageBody[2];
    [[NSUserNotificationCenter defaultUserNotificationCenter] scheduleNotification:notification];
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification {
    return YES;
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification {
    if (notification.activationType == NSUserNotificationActivationTypeReplied){
        NSString* userResponse = notification.response.string;
        //Sending reply to WAWeb
        [self.webView evaluateJavaScript:
         [NSString stringWithFormat:@"openChat(\"%@\")", notification.identifier]
                       completionHandler:nil];
        
        [self.webView evaluateJavaScript:
         [NSString stringWithFormat:@"dispatch(document.querySelector('div.input'), 'textInput', '%@')", userResponse]
                       completionHandler:nil];
        
        [self.webView evaluateJavaScript:
         [NSString stringWithFormat:@"triggerClick();"]
                       completionHandler:nil];
        
        [center removeDeliveredNotification:notification];
        
    } else {
        [self.webView evaluateJavaScript:
         [NSString stringWithFormat:@"openChat(\"%@\")", notification.identifier]
                       completionHandler:nil];
        [center removeDeliveredNotification:notification];
        [_window makeKeyAndOrderFront:self];
    }

}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Uploading Media";
    alert.informativeText = message;
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
    completionHandler();
}

# pragma mark Utils
- (void)updateTitlebarOfWindow:(NSWindow*)window fullScreen:(BOOL)fullScreen {
        const CGFloat kTitlebarHeight = 59;
    const CGFloat kFullScreenButtonYOrigin = 3;
    CGRect windowFrame = window.frame;
  
    // Set size of titlebar container
    NSView *titlebarContainerView = [window standardWindowButton:NSWindowCloseButton].superview.superview;
    CGRect titlebarContainerFrame = titlebarContainerView.frame;
    titlebarContainerFrame.origin.y = windowFrame.size.height - kTitlebarHeight;
    titlebarContainerFrame.size.height = kTitlebarHeight;
    titlebarContainerView.frame = titlebarContainerFrame;
    
    // Set position of window buttons
    CGFloat buttonX = 12; // initial LHS margin, matching Safari 8.0 on OS X 10.10.
    NSView *closeButton = [window standardWindowButton:NSWindowCloseButton];
    NSView *minimizeButton = [window standardWindowButton:NSWindowMiniaturizeButton];
    NSView *zoomButton = [window standardWindowButton:NSWindowZoomButton];
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
