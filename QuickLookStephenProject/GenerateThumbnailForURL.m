#import <Foundation/Foundation.h>

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>

#import "QLSMagicFileAttributes.h"


static NSString *uppercaseString(NSString *aString, NSLocale *locale) {
  NSMutableString *copy = [aString mutableCopy];
  CFStringUppercase((__bridge CFMutableStringRef)(copy), (CFLocaleRef)locale);
  return copy;
}

/**
 * @return the text used to badge the thumbnail.
 */
static NSString *ThumbnailBadgeForItemAtURL(NSURL *url) {
  // If the file has no extension--eg. Makefile, Doxyfile, CHANGELOG etc--we
  // badge it with the filename itself. This might not be the best of
  // heuristics, but it seems to work well enough.
  
  NSString *fileExtension = [url pathExtension];
  NSString *badge;

  if ([fileExtension isEqualToString:@""])
    badge = [url lastPathComponent];
  else
    badge = fileExtension;

  return uppercaseString(badge, [NSLocale currentLocale]);
}


/* -----------------------------------------------------------------------------
 Generate a thumbnail for file
 
 This function's job is to create thumbnail for designated file as fast as
 possible
 -------------------------------------------------------------------------- */
OSStatus GenerateThumbnailForURL(void *thisInterface,
                                 QLThumbnailRequestRef request,
                                 CFURLRef url, CFStringRef contentTypeUTI,
                                 CFDictionaryRef options, CGSize maxSize) {
  @autoreleasepool {
    if (QLThumbnailRequestIsCancelled(request))
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
      (NSString *)kQLPreviewPropertyMIMETypeKey       : @"text/plain",
      (NSString *)kQLPreviewPropertyStringEncodingKey : @( magicAttributes.fileEncoding )
    };
    
    
    NSString *badge = ThumbnailBadgeForItemAtURL((__bridge NSURL *)url);

    NSDictionary *properties = @{
      (NSString *)kQLThumbnailPropertyExtensionKey : badge
    };
    
    
    QLThumbnailRequestSetThumbnailWithURLRepresentation(
        request,
        url,
        kUTTypePlainText,
        (__bridge CFDictionaryRef)previewProperties,
        (__bridge CFDictionaryRef)properties);
    
    return noErr;
  }
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
