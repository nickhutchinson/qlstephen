//
//  QLSMagicFileAttributes.m
//  QuickLookStephen
//
//  Created by Nick Hutchinson on 31/07/12.
//

#import "QLSMagicFileAttributes.h"

@interface QLSMagicFileAttributes ()

@property (readwrite) BOOL isTextual;
@property (readwrite) NSString *mimeType;
@property (readwrite) CFStringEncoding fileEncoding;

@end


@implementation QLSMagicFileAttributes

+ (instancetype)magicAttributesForItemAtURL:(NSURL *)aURL
{
  NSString *magicString = [self magicStringForFileAtURL:aURL];
  if (!magicString) return nil;
  
  NSRegularExpression *magicRegex = self.magicOutputRegex;
  
  NSArray *matches = [magicRegex matchesInString:magicString
                                         options:0
                                           range:NSMakeRange(0, magicString.length)];
  
  if (![matches count]) return nil;
  
  NSTextCheckingResult *regexResult = matches[0];
  
  NSRange mimeTypeRange = [regexResult rangeAtIndex:1];
  NSRange charsetRange = [regexResult rangeAtIndex:2];
  
  NSString *mimetype = [magicString substringWithRange:mimeTypeRange];
  NSString *charset = [magicString substringWithRange:charsetRange];
  
  BOOL mimeTypeIsTextual = [self mimeTypeIsTextual:mimetype];
  
  CFStringEncoding encoding = CFStringConvertIANACharSetNameToEncoding(
                                  (CFStringRef)charset);
  
  QLSMagicFileAttributes *props = [QLSMagicFileAttributes new];
  props.fileEncoding = encoding;
  props.isTextual = mimeTypeIsTextual;
  props.mimeType = mimetype;
  
  return props;
}


+ (NSRegularExpression *)magicOutputRegex
{
  NSString *regexString =
      @"\\S+: (\\S+/\\S+); charset=(\\S+)";
  
  NSError *error;
  NSRegularExpression *regex =
      [NSRegularExpression regularExpressionWithPattern:regexString
                                                options:0
                                                  error:&error];
  NSAssert(regex, @"Invalid regex");
  
  return regex;
}

+ (NSString *)magicStringForFileAtURL:(NSURL *)aURL
{
  NSString *path = [aURL path];
  NSParameterAssert(path);
  
  NSTask *task = [NSTask new];
  task.launchPath = @"/usr/bin/file";
  task.arguments = @[@"-I", path];
  task.standardOutput = [NSPipe new];
  
  [task launch];
  [task waitUntilExit];
  
  if (!(task.terminationReason == NSTaskTerminationReasonExit
        && task.terminationStatus == 0)) {
    return nil;
  }
  
  NSCharacterSet *whitespaceCharset =
  [NSCharacterSet whitespaceAndNewlineCharacterSet];
  
  NSData *output =
      [[task.standardOutput fileHandleForReading] readDataToEndOfFile];
  
  NSString *stringOutput =
      [[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding];
  
  stringOutput =
      [stringOutput stringByTrimmingCharactersInSet:whitespaceCharset];
  
  return stringOutput;
}

+ (BOOL)mimeTypeIsTextual:(NSString *)mimeType
{
  NSArray *components = [mimeType componentsSeparatedByString:@"/"];
  if (components.count != 2)
    return NO;
  
  if ([components[0] rangeOfString:@"text"].location != NSNotFound)
    return YES;
  
  NSString *UTType =
      CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(
                            kUTTagClassMIMEType,
                            (__bridge CFStringRef)mimeType,
                            kUTTypeData));
  
  if (UTTypeConformsTo((__bridge CFStringRef)UTType, kUTTypeText)) {
    return YES;
  }
  
  return NO;
}

@end
