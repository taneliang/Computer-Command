//
//  Transceiver.m
//  Computer Command
//
//  Created by Tan E-Liang on 2/7/12.
//  Copyright (c) 2012 Tan E-Liang. All rights reserved.
//

#import "Transceiver.h"

NSString * const TransceiverInputNotification = @"TransceiverInputNotification";
NSString * const TransceiverInputNotificationDictionaryActionName = @"TransceiverInputNotificationDictionaryActionName";
NSString * const TransceiverInputNotificationDictionaryDetails = @"TransceiverInputNotificationDictionaryDetails";

@implementation Transceiver

//- (NSString *)processInput:(NSScriptCommand *)input {
//	NSLog(@"HOLYKOW");
//	return @"hey there!";
//}

- (id)performDefaultImplementation {
    NSDictionary *args = [self evaluatedArguments];
    NSLog(@"Got input with arguments: %@", args);
	NSString *input = args[@"input"];
	input = [input stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    return [self processInput:input];
}

/*
 
 Process input documentation:
 
 Required parameter: cmd - States the command/task.
 
 For different commands, different parameters are required:
 
 fwd_applescript - Forwards AppleScript scripts to NSAppleScript for execution. All double quotes are to be substituted with 2 single quotes.
	Parameters:
		script - the script to be executed
	Return value:
		status - success/error
		result - result of script execution
 
 initiate_tcp_server - Initiates a TCP server for connection from remote client
	Return value:
		status - success/error
		ip_addr - IP address for connection
		port - port for connection
 
 */

- (NSString *)processInput:(NSString *)input {
	NSLog(@"%@", input);
	NSNotification *notification = nil;
	NSError *error = nil;
	NSDictionary *serializedInput = [NSJSONSerialization JSONObjectWithData:[input dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
	NSMutableDictionary *outputDictionary = [NSMutableDictionary dictionary];
	NSLog(@"input: %@", serializedInput);
	
	if (error) {
		NSLog(@"error at serializedInput: %@", error);
		outputDictionary[@"status"] = @"error";
		outputDictionary[@"message"] = [error description];
		outputDictionary[@"sound"] = @"error";
//		NSLog(@"%@ %@", outputDictionary, [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:outputDictionary options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]);
		return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:outputDictionary options:0 error:nil] encoding:NSUTF8StringEncoding];
	}
	
	NSString *command = serializedInput[@"cmd"];
	if ([command isEqualToString:@"fwd_applescript"]) {
		NSDictionary *errorDictionary = nil;
		NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:[serializedInput[@"script"] stringByReplacingOccurrencesOfString:@"''" withString:@"\""]];
		NSAppleEventDescriptor *result = [appleScript executeAndReturnError:&errorDictionary];
		NSLog(@"%@ %@", result, errorDictionary);
		if (errorDictionary) {
			outputDictionary[@"status"] = @"error";
			outputDictionary[@"message"] = errorDictionary[NSAppleScriptErrorMessage];
			outputDictionary[@"sound"] = @"error";
			notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"Failed to forward AppleScript", TransceiverInputNotificationDictionaryDetails : outputDictionary}];
			return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:outputDictionary options:0 error:nil] encoding:NSUTF8StringEncoding];
		}
		else {
			outputDictionary[@"status"] = @"success";
			outputDictionary[@"sound"] = @"acknowledged_one";
			NSLog(@"Win! %@ %@ %@", [self stringFromEventDescriptor:result], result, [result stringValue]);
			if ([result stringValue] != nil) outputDictionary[@"result"] = [result stringValue];
			else if ([self stringFromEventDescriptor:result] != nil) outputDictionary[@"result"] = [self stringFromEventDescriptor:result];
		}
		
		notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"Forwarded AppleScript", TransceiverInputNotificationDictionaryDetails : outputDictionary}];

	}
	else if ([command isEqualToString:@"get_program_list"]) {
		NSMutableArray *directoryContents = [NSMutableArray arrayWithArray:[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Users/Eliang/Desktop/Satellite Programs" error:&error]];
		if (error) {
			outputDictionary[@"status"] = @"error";
			outputDictionary[@"message"] = [error localizedFailureReason];
			outputDictionary[@"sound"] = @"error";
			notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"Failed to get program list.", TransceiverInputNotificationDictionaryDetails : outputDictionary}];
		}
		else {
			[directoryContents removeObject:@".DS_Store"];
			
			NSMutableArray *directoryContentsWithoutFileExtensionArray = [NSMutableArray arrayWithCapacity:[directoryContents count]];
			[directoryContents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSString *name = (NSString *)obj;
				[directoryContentsWithoutFileExtensionArray addObject:[[name substringToIndex:[name length]-4] uppercaseString]];
			}];
			NSLog(@"Directory contetns = %@ %@", directoryContentsWithoutFileExtensionArray, error);
			outputDictionary[@"status"] = @"success";
			outputDictionary[@"message"] = [NSString stringWithFormat:@"%ld program%@ retrieved.", [directoryContentsWithoutFileExtensionArray count], ([directoryContentsWithoutFileExtensionArray count] == 1 ? @" was" : @"s were")];
			outputDictionary[@"sound"] = @"acknowledged_one";
			outputDictionary[@"list"] = directoryContentsWithoutFileExtensionArray;
			notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : outputDictionary[@"message"], TransceiverInputNotificationDictionaryDetails : outputDictionary}];
			
			if (error) {
				outputDictionary[@"status"] = @"error";
				outputDictionary[@"message"] = [error localizedFailureReason];
				outputDictionary[@"sound"] = @"error";
				notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"Failed to get program list.", TransceiverInputNotificationDictionaryDetails : outputDictionary}];
			}
		}
	}
	else if ([command isEqualToString:@"voice_ctrl"]) {
		outputDictionary[@"status"] = @"success";
		outputDictionary[@"sound"] = @"acknowledged_one";
		NSMutableString *query = [NSMutableString stringWithString:serializedInput[@"q"]];
		if ([query hasPrefix:@"TURN UP VOLUME"] || [query hasPrefix:@"TURN DOWN VOLUME"] || [query hasPrefix:@"INCREASE VOLUME"] || [query hasPrefix:@"DECREASE VOLUME"] || [query hasPrefix:@"MUTE AUDIO"] || [query hasPrefix:@"UNMUTE AUDIO"]) {
			NSDictionary *errorDictionary = nil;
			
			[query replaceOccurrencesOfString:@"INCREASE VOLUME" withString:@"TURN UP VOLUME" options:0 range:NSMakeRange(0, [query length])];
			[query replaceOccurrencesOfString:@"DECREASE VOLUME" withString:@"TURN DOWN VOLUME" options:0 range:NSMakeRange(0, [query length])];
			NSInteger currentVolume = [[self runAppleScript:@"get output volume of (get volume settings)" error:&errorDictionary] integerValue];
			NSInteger changeLevel = 6; // 100/16
			
			if ([query hasPrefix:@"TURN UP VOLUME"] && currentVolume >= 100) {
				outputDictionary[@"status"] = @"error";
				outputDictionary[@"message"] = @"System volume is already at maximum.";
				outputDictionary[@"sound"] = @"error";
				notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"System volume is already at maximum.", TransceiverInputNotificationDictionaryDetails : outputDictionary}];
			}
			else if (([query hasPrefix:@"TURN DOWN VOLUME"] || [query hasPrefix:@"MUTE AUDIO"]) && currentVolume <= 0) {
				outputDictionary[@"status"] = @"error";
				outputDictionary[@"message"] = @"System volume is already at minimum.";
				outputDictionary[@"sound"] = @"error";
				notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"System volume is already at minimum.", TransceiverInputNotificationDictionaryDetails : outputDictionary}];
			}
			else if ([query hasPrefix:@"UNMUTE AUDIO"] && currentVolume > 0) {
				outputDictionary[@"status"] = @"error";
				outputDictionary[@"message"] = @"Audio is not muted.";
				outputDictionary[@"sound"] = @"error";
				notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : @"Audio is not muted.", TransceiverInputNotificationDictionaryDetails : outputDictionary}];
			}
			else {
				if ([query hasSuffix:@"LEVELS"] || [query hasSuffix:@"LEVEL"]) {
					NSString *level = [[query componentsSeparatedByString:@" "] objectAtIndex:3];
					changeLevel *= [self stringToInteger:level];
				}
				else if ([query hasPrefix:@"MUTE AUDIO"]) {
					changeLevel = currentVolume;
				}
				else if ([query hasPrefix:@"UNMUTE AUDIO"]) {
					changeLevel *= 3;
				}
				
				if ([query hasPrefix:@"TURN UP VOLUME"] || [query hasPrefix:@"UNMUTE AUDIO"]) {
					changeLevel += currentVolume;
					if (changeLevel > 100) changeLevel = 100;
					[self runAppleScript:[NSString stringWithFormat:@"set volume output volume %ld", changeLevel] error:&errorDictionary];
				}
				else if ([query hasPrefix:@"TURN DOWN VOLUME"] || [query hasPrefix:@"MUTE AUDIO"]) {
					changeLevel = currentVolume - changeLevel;
					if (changeLevel < 0) changeLevel = 0;
					[self runAppleScript:[NSString stringWithFormat:@"set volume output volume %ld", changeLevel] error:&errorDictionary];
				}
				
				if (errorDictionary) {
					outputDictionary[@"status"] = @"error";
					outputDictionary[@"message"] = errorDictionary[NSAppleScriptErrorMessage];
					outputDictionary[@"sound"] = @"error";
				}
				else {
					outputDictionary[@"sound"] = @"acknowledged_two";
					if (changeLevel == 100) outputDictionary[@"message"] = [NSString stringWithFormat:@"System volume is now set to maximum."];
					else if (changeLevel == 0) outputDictionary[@"message"] = [NSString stringWithFormat:@"Audio is now muted."];
					else outputDictionary[@"message"] = [NSString stringWithFormat:@"System volume is now set to %ld%%.", changeLevel];
					notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : [NSString stringWithFormat:@"System volume now at %ld%%.", changeLevel], TransceiverInputNotificationDictionaryDetails : outputDictionary}];
				}
			}
		}
		else if ([query hasPrefix:@"EXECUTE"] || [query hasPrefix:@"RUN"] || [query hasPrefix:@"OPEN"]) {
			NSArray *components = [query componentsSeparatedByString:@" "];
			NSUInteger indexOfProgram = [components indexOfObject:@"PROGRAM"];
			if (indexOfProgram == NSNotFound) indexOfProgram = 0; // RUN, EXECUTE, whatever
			components = [components subarrayWithRange:NSMakeRange(indexOfProgram+1, [components count] - (indexOfProgram+1))];
			__block NSString *appName = [[components componentsJoinedByString:@" "] stringByAppendingString:@".app"];
			
			NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Users/Eliang/Desktop/Satellite Programs" error:&error];
			[contents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				if ([(NSString *)obj caseInsensitiveCompare:appName] == NSOrderedSame) {
					appName = (NSString *)obj;
					*stop = YES;
				}
			}];
			
			NSLog(@"app name = %@", appName);
			[[NSWorkspace sharedWorkspace] launchApplication:[NSString stringWithFormat:@"/Users/Eliang/Desktop/Satellite Programs/%@", appName]];
			
			outputDictionary[@"status"] = @"success";
			outputDictionary[@"message"] = [NSString stringWithFormat:@"%@ has been launched.", [appName substringToIndex:[appName length]-4]];
			outputDictionary[@"sound"] = @"acknowledged_two";
			
			notification = [NSNotification notificationWithName:TransceiverInputNotification object:nil userInfo:@{TransceiverInputNotificationDictionaryActionName : outputDictionary[@"message"], TransceiverInputNotificationDictionaryDetails : outputDictionary}];
		}
		else {
			notification = [NSNotification notificationWithName:@"pork" object:nil];
		}
	}
	
	if (notification == nil) {
		NSAlert *alert = [NSAlert alertWithMessageText:@"Bugbugbugbug" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"No notification. #fail."];
		[alert runModal];
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotification:notification];
	}
	
	return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:outputDictionary options:0 error:nil] encoding:NSUTF8StringEncoding];
}

- (NSString *)runAppleScript:(NSString *)script error:(NSDictionary **)error {
	NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
	NSAppleEventDescriptor *result = [appleScript executeAndReturnError:&*error];
	if (*error) return nil;
	return [self stringFromEventDescriptor:result];
}

- (NSString *)stringFromEventDescriptor:(NSAppleEventDescriptor *)descriptor {
	OSStatus status;
	if ([descriptor descriptorType] == typeLongDateTime) {
		CFAbsoluteTime absoluteTime;
		LongDateTime longDateTime;
		[[descriptor data] getBytes:&longDateTime length:sizeof(longDateTime)];
		status = UCConvertLongDateTimeToCFAbsoluteTime(longDateTime, &absoluteTime);
		if (status == noErr) {
			NSDate *resultDate = (__bridge NSDate *)CFDateCreate(NULL, absoluteTime);
			return [resultDate description];
		}
		return nil;
	}
	else if ([descriptor descriptorType] == cLongInteger) {
		return [descriptor stringValue];
	}
	
	return nil;
}

// Convert spelled-out string to an NSInteger
- (NSInteger)stringToInteger:(NSString *)string {
	if ([string isEqualToString:@"ZERO"]) return 0;
	if ([string isEqualToString:@"ONE"]) return 1;
	if ([string isEqualToString:@"TWO"]) return 2;
	if ([string isEqualToString:@"THREE"]) return 3;
	if ([string isEqualToString:@"FOUR"]) return 4;
	if ([string isEqualToString:@"FIVE"]) return 5;
	if ([string isEqualToString:@"SIX"]) return 6;
	if ([string isEqualToString:@"SEVEN"]) return 7;
	if ([string isEqualToString:@"EIGHT"]) return 8;
	if ([string isEqualToString:@"NINE"]) return 9;
	if ([string isEqualToString:@"TEN"]) return 10;
	if ([string isEqualToString:@"ELEVEN"]) return 11;
	if ([string isEqualToString:@"TWELVE"]) return 12;
	if ([string isEqualToString:@"THIRTEEN"]) return 13;
	if ([string isEqualToString:@"FOURTEEN"]) return 14;
	if ([string isEqualToString:@"FIFTEEN"]) return 15;
	if ([string isEqualToString:@"SIXTEEN"]) return 16;
	if ([string isEqualToString:@"SEVENTEEN"]) return 17;
	if ([string isEqualToString:@"EIGHTEEN"]) return 18;
	if ([string isEqualToString:@"NINETEEN"]) return 19;
	if ([string isEqualToString:@"TWENTY"]) return 20;
	if ([string isEqualToString:@"THIRTY"]) return 30;
	if ([string isEqualToString:@"FORTY"]) return 40;
	if ([string isEqualToString:@"FIFTY"]) return 50;
	if ([string isEqualToString:@"SIXTY"]) return 60;
	if ([string isEqualToString:@"SEVENTY"]) return 70;
	if ([string isEqualToString:@"EIGHTY"]) return 80;
	if ([string isEqualToString:@"NINETY"]) return 90;
	if ([string isEqualToString:@"HUNDRED"]) return 100;
	if ([string isEqualToString:@"THOUSAND"]) return 1000;
	if ([string isEqualToString:@"MILLION"]) return 1000000;
	return -1;
}

@end
