#import "MyWindow.h"

@implementation MyWindow

- (IBAction)sayHello:(id)sender
{
	NSBeginAlertSheet(@"Hi!", nil, nil, nil, self, self, nil, nil, NULL, @"Hello, %@!", nameTextField.stringValue.length ? nameTextField.stringValue : @"Person-with-no-name");
}

@end
