#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Foundation/Foundation.h>

#import "QLSFileAttributes.h"


/**
 * This dictionary is used for a file with no extension. It maps the MIME type
 * (as returned by file(1)) onto an appropriate thumbnail badge.
 */
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
 * @return the string that should be used to badge the thumbnail.
 */
static NSString *ThumbnailBadgeForItemWithAttributes(
    QLSFileAttributes *attributes) {
  NSString *fileExtension = attributes.url.pathExtension;
  NSString *badge;

  // Do we have a file extension?
  if (![fileExtension isEqualToString:@""]) {
    badge = fileExtension;

    // Is the file extension too long to be reasonably displayed in a
    // thumbnail? If so, fall back on the additional tests.

    // FIXME: use some better test to determine an appropriate length.
    // FIXME: perhaps we should truncate the extension (at the end? in the
    //        middle?) to fit as much in the thumbnail as possible.

    if (badge.length >= 10)
      badge = nil;
  }

  // Do we have a well-known MIME type? Note that we only do this test if we
  // have no file extension. file(1) might wrongly guess the MIME type, and it
  // would be annoying if the file extension were to say one thing and the
  // badge another.
  if (!badge && [fileExtension isEqualToString:@""]) {
    NSDictionary *map = MIMETypeToBadgeMap();
    badge = map[attributes.mimeType];
  }

  // Do we have an executable text file? If so, assume it's a script of some
  // sort.
  if (!badge) {
    NSFileManager *fm = [NSFileManager new];
    BOOL isExecutable = [fm isExecutableFileAtPath:attributes.url.path];
    if (isExecutable)
      badge = @"script";
  }

  if (!badge) {
    badge = @"txt"; // I would use "text", but the OS X text QuickLook
                    // generator uses "txt", and we ought to be consistent.
  }

  return [badge uppercaseString];
}


/* -----------------------------------------------------------------------------
 Generate a thumbnail for file

 This function's job is to create thumbnail for designated file as fast as
 possible
 -------------------------------------------------------------------------- */
OSStatus GenerateThumbnailForURL(void *thisInterface,
                                 QLThumbnailRequestRef request,
                                 CFURLRef url,
                                 CFStringRef contentTypeUTI,
                                 CFDictionaryRef options,
                                 CGSize maxSize) {
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

    NSString *badge = ThumbnailBadgeForItemWithAttributes(magicAttributes);

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

void CancelThumbnailGeneration(void* thisInterface,
                               QLThumbnailRequestRef thumbnail) {
    // implement only if supported
}
