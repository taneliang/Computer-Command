//
//  AppDelegate.h
//  Computer Command
//
//  Created by Tan E-Liang on 2/7/12.
//  Copyright (c) 2012 Tan E-Liang. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Transceiver.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSSpeechRecognizerDelegate>

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSSpeechRecognizer *speechRecognizer;

@property (weak) IBOutlet NSTextField *actionLabel;
@property (weak) IBOutlet NSTextField *timestampLabel;

@end
