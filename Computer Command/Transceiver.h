//
//  Transceiver.h
//  Computer Command
//
//  Created by Tan E-Liang on 2/7/12.
//  Copyright (c) 2012 Tan E-Liang. All rights reserved.
//

#import <Foundation/Foundation.h>

//@protocol TransceiverDelegate;

extern NSString * const TransceiverInputNotification;
extern NSString * const TransceiverInputNotificationDictionaryActionName;
extern NSString * const TransceiverInputNotificationDictionaryDetails;

@interface Transceiver : NSScriptCommand

//@property (nonatomic, assign) id<TransceiverDelegate> delegate;

@end

@protocol TransceiverDelegate <NSObject>

//- (void)transceiver:(Transceiver *)transceiver didReceiveValidInput:(NSString *)actionName additionalDetails:(NSDictionary *)details;

@end
