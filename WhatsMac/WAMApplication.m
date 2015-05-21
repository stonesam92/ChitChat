#import "WAMApplication.h"
#import "AppDelegate.h"

@implementation WAMApplication
- (void)sendEvent:(NSEvent *)theEvent {
    if (theEvent.type == NSKeyDown && (theEvent.modifierFlags & NSCommandKeyMask)) {
        NSString *chars = theEvent.charactersIgnoringModifiers;
        if (chars.length == 1) {
            switch ([chars characterAtIndex:0]) {
                case '1' ... '9':
                    [((AppDelegate*)self.delegate) setActiveConversationAtIndex:theEvent.characters];
                    return;
                default:
                    break;
            }
        }
    }
    [super sendEvent:theEvent];
}
@end
