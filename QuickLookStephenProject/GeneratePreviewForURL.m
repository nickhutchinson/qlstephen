//

#import <Foundation/Foundation.h>
#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import "QLSMagicFileAttributes.h"


// Generate a preview for the document with the given url
OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview,
                               CFURLRef url, CFStringRef contentTypeUTI,
                               CFDictionaryRef options) {
  if (QLPreviewRequestIsCancelled(preview))
    return noErr;
  
  @autoreleasepool {
    NSMutableDictionary *props = [NSMutableDictionary new];
    props[(NSString *)kQLPreviewPropertyMIMETypeKey]  = @"text/plain";
    props[(NSString *)kQLPreviewPropertyWidthKey]     = @700;
    props[(NSString *)kQLPreviewPropertyHeightKey]    = @80;

    
    QLSMagicFileAttributes *magicAttributes =
        [QLSMagicFileAttributes magicAttributesForItemAtURL:(__bridge NSURL *)url];
        
    if (!magicAttributes) {
      NSLog(@"QLStephen: Could not determine attribtues of file %@", url);
      return noErr;
    }
    
    if (!magicAttributes.isTextual) {
//      NSLog(@"QLStephen: I don't think %@ is a text file", url);
      return noErr;
    }
    
    if (magicAttributes.fileEncoding == kCFStringEncodingInvalidId) {
      NSLog(@"QLStephen: Could not determine encoding of file %@", url);
      return noErr;
    }
    
    props[(NSString *)kQLPreviewPropertyStringEncodingKey] = @( magicAttributes.fileEncoding );
    
    NSError *error;
    NSData *fileData = [NSData dataWithContentsOfURL:(__bridge NSURL *)url
                                             options:NSDataReadingMappedIfSafe
                                               error:&error];
    if (!fileData) {
      NSLog(@"QLStephen: Could not read file %@; error was %@", url, error);
      return noErr;
    }
    
        
    QLPreviewRequestSetDataRepresentation(
        preview,
        (__bridge CFDataRef)fileData,
        kUTTypePlainText,
        (__bridge CFDictionaryRef)props);

    return noErr;
  }
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
  // implement only if supported
}
