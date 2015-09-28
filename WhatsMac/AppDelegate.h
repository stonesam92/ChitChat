#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSResponder <NSApplicationDelegate>
@property(readonly) NSWindow* window;
- (void)setActiveConversationAtIndex:(NSString*)index;
- (BOOL)shouldPropagateMouseUpEvent:(NSEvent*)theEvent;
- (BOOL)shouldPropagateMouseDownEvent:(NSEvent*)theEvent;
- (BOOL)shouldPropagateMouseDraggedEvent:(NSEvent*)theEvent;

@end

