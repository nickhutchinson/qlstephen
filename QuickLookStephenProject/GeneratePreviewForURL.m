#import <Foundation/Foundation.h>

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>

#import "QLSMagicFileAttributes.h"


// Generate a preview for the document with the given url
OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef request,
                               CFURLRef url, CFStringRef contentTypeUTI,
                               CFDictionaryRef options) {
  @autoreleasepool {
    if (QLPreviewRequestIsCancelled(request))
      return noErr;
    
    QLSMagicFileAttributes *magicAttributes
        = [QLSMagicFileAttributes magicAttributesForItemAtURL:(__bridge NSURL *)url];
    
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
    
    NSDictionary *previewProperties = @{
      (NSString *)kQLPreviewPropertyMIMETypeKey   : @"text/plain",
      (NSString *)kQLPreviewPropertyStringEncodingKey : @( magicAttributes.fileEncoding ),
      (NSString *)kQLPreviewPropertyWidthKey      : @700,
      (NSString *)kQLPreviewPropertyHeightKey     : @800
    };
    
    QLPreviewRequestSetURLRepresentation(request, url, kUTTypePlainText,
                                         (__bridge CFDictionaryRef)previewProperties);

    return noErr;
  }
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
  // implement only if supported
}
