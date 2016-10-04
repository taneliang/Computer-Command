//
//  AppDelegate.m
//  Computer Command
//
//  Created by Tan E-Liang on 2/7/12.
//  Copyright (c) 2012 Tan E-Liang. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] addObserverForName:TransceiverInputNotification object:nil queue:[NSOperationQueue currentQueue] usingBlock:^(NSNotification *note) {
		NSLog(@"%@", note);
		self.timestampLabel.stringValue = [[NSDate date] description];
		self.actionLabel.stringValue = [note userInfo][TransceiverInputNotificationDictionaryActionName];
	}];
	// Insert code here to initialize your applicationll
//	self.speechRecognizer = [[NSSpeechRecognizer alloc] init];
////	[self.speechRecognizer setListensInForegroundOnly:YES];
//	[self.speechRecognizer setDelegate:self];
//	[self.speechRecognizer setCommands:@[@"hello"]];
//	[self.speechRecognizer startListening];
//	NSLog(@"%@", [self.speechRecognizer commands]);
	
//	{
//		// Insert code here to initialize your application
//		unsigned int varCount;
//		
//		Method *vars = class_copyMethodList([NSNotification class], &varCount);
//		
//		for (int i = 0; i < varCount; i++) {
//			Method var = vars[i];
//			
//			const char* name = sel_getName(method_getName(var));
//			unsigned int typeEncoding = method_getNumberOfArguments(var);
//			NSLog(@"%s %u", name, typeEncoding);
//			// do what you wish with the name and type here
//		}
//		
//		free(vars);
//	}
}

- (void)speechRecognizer:(NSSpeechRecognizer *)sender didRecognizeCommand:(id)command {
	NSLog(@"%@ %@", sender, command);
}

@end
