//
//  QLSMagicFileAttributes.h
//  QuickLookStephen
//
//  Created by Nick Hutchinson on 31/07/12.

#import <Foundation/Foundation.h>

@interface QLSMagicFileAttributes : NSObject

+ (instancetype)magicAttributesForItemAtURL:(NSURL *)aURL;

@property (readonly) BOOL isTextual;
@property (readonly) NSString *mimeType;
@property (readonly) CFStringEncoding fileEncoding;

@end


