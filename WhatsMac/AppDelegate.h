#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (void)setActiveConversationAtIndex:(NSString*)index;
- (BOOL)shouldPropagateMouseUpEvent:(NSEvent*)theEvent;
- (BOOL)shouldPropagateMouseDraggedEvent:(NSEvent*)theEvent;

@property BOOL hasReplyButton NS_AVAILABLE(10_9, NA);

// Optional placeholder for inline reply field.
@property (copy) NSString *responsePlaceholder NS_AVAILABLE(10_9, NA);

// When a notification has been responded to, the NSUserNotificationCenter delegate
// didActivateNotification: will be called with the notification with the activationType
// set to NSUserNotificationActivationTypeReplied and the response set on the response property
@property (readonly) NSAttributedString *response NS_AVAILABLE(10_9, NA);

@end

