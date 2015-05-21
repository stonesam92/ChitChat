#import "WAMWebView.h"

@implementation WAMWebView

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
    BOOL superResult = [super performKeyEquivalent:theEvent];
    switch (theEvent.keyCode) {
        case 53:        // esc key
        case 124:       // right arrow
        case 123:       // left arrow
            return YES;
            break;
        default:
            return superResult;
            break;
    }
}

@end
