#import <Foundation/Foundation.h>

#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>

#import "QLSFileAttributes.h"


static NSString *uppercaseString(NSString *aString, NSLocale *locale) {
  NSMutableString *copy = [aString mutableCopy];
  CFStringUppercase((__bridge CFMutableStringRef)(copy), (CFLocaleRef)locale);
  return copy;
}


static NSDictionary *MIMETypeToBadgeMap() {
  return @{
      @"application/xml": @"xml",
      @"text/x-c"       : @"C",
      @"text/x-c++"     : @"C++",
      @"text/x-shellscript" : @"shell",
      @"text/x-php"     : @"php",
      @"text/x-python"  : @"python",
      @"text/x-perl"    : @"perl",
      @"text/x-ruby"    : @"ruby"
  };
}

/**
 * @brief If the file has no extension--eg. Makefile, Doxyfile, CHANGELOG etc--
 *   we badge it with the filename itself. This might not be the best of
 *   heuristics, but it seems to work well enough.
 *
 * @return the text used to badge the thumbnail.
 * @todo Filenames or extensions are sometimes too long to properly fit the 
 *       Finder icon, and the result looks ridiculous. FIXME.
 */
static NSString *ThumbnailBadgeForPlainTextItemAtURL(NSURL *url,
                                                     NSString *mimeType) {
  NSString *fileExtension = [url pathExtension];
  NSString *badge;

  // Do we have a file extension?
  if (![fileExtension isEqualToString:@""]) {
    badge = fileExtension;
    
    // Is the file extension too long to be reasonably displayed in a thumbnail?
    // Is so, fall back on the additional tests.
    
    // FIXME1: use some better best to determine an appropriate length.
    // FIXME2: perhaps truncate the extension (at the end? in the middle?) to
    //         fit as much in the thumbnail as possible.
    
    if ([badge length] >= 10)
      badge = nil;
  }

  // Do we have a well-known MIME type? Note that we only do this test if we
  // have no file extension. It's would be pretty jarring to get a misdiagnosis.
  if (!badge && [fileExtension isEqualToString:@""]) {
    NSDictionary *map = MIMETypeToBadgeMap();
    badge = map[mimeType];
  }
  
  // Do we have an executable text file? If so, assume it's a script of some
  // sort.
  if (!badge) {
    NSFileManager *fm = [NSFileManager new];
    BOOL isExecutable = [fm isExecutableFileAtPath:[url path]];
    if (isExecutable)
      badge = @"script";
  }
    
  if (!badge) {
    badge = @"txt"; // I would use "text", but the OS X text QuickLook
                    // generator uses "txt", and we ought to be consistent.
  }
  

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
        
    QLSFileAttributes *magicAttributes
        = [QLSFileAttributes attributesForItemAtURL:(__bridge NSURL *)url];
    
    if (!magicAttributes) {
      NSLog(@"QLStephen: Could not determine attribtues of file %@", url);
      return noErr;
    }
    
    if (!magicAttributes.isTextFile) {
//      NSLog(@"QLStephen: I don't think %@ is a text file", url);
      return noErr;
    }
    
    if (magicAttributes.fileEncoding == kCFStringEncodingInvalidId) {
      NSLog(@"QLStephen: Could not determine encoding of file %@", url);
      return noErr;
    }
    
    NSDictionary *previewProperties = @{
      (NSString *)kQLPreviewPropertyStringEncodingKey : @( magicAttributes.fileEncoding )
    };
    
    NSString *badge = ThumbnailBadgeForPlainTextItemAtURL(
                          (__bridge NSURL *)url,
                          magicAttributes.mimeType);

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
