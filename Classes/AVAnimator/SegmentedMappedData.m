//
//  Created by Moses DeJong on 1/22/12.
//
//  License terms defined in License.txt.

#import "SegmentedMappedData.h"
#import "AutoPropertyRelease.h"

#include <sys/mman.h>
#include <fcntl.h>

// This private class is used to implement a ref counted
// file descriptor container. The held file descriptor
// is closed once all the mapped objects have been released.

@interface RefCountedFD : NSObject
{
@public
  int                 m_fd;
}

+ (RefCountedFD*) refCountedFD:(int)fd;

- (void) dealloc;

@end

@implementation RefCountedFD

+ (RefCountedFD*) refCountedFD:(int)fd
{
  RefCountedFD *obj = [[RefCountedFD alloc] init];
  obj->m_fd = fd;
  return [obj autorelease];
}

- (void) dealloc
{
  int close_result = close(m_fd);
  NSAssert(close_result == 0, @"close_result");
  [super dealloc];
}

@end // RefCountedFD


// SegmentedMappedData Private API

@interface SegmentedMappedData ()

@property (nonatomic, retain) NSMutableArray *mappedDataSegments;

@property (nonatomic, copy)   NSString *filePath;

@property (nonatomic, retain) RefCountedFD *refCountedFD;

// Create an object that will map a specific segment into memory.
// The object stores the file offset, the FD, the offset, and the length in bytes.

+ (SegmentedMappedData*) segmentedMappedDataWithDeferredMapping:(NSString*)filePath
                                                   refCountedFD:(RefCountedFD*)refCountedFD
                                                         offset:(off_t)offset
                                                            len:(size_t)len;

@end

// SegmentedMappedData implementation

@implementation SegmentedMappedData

@synthesize mappedDataSegments = m_mappedDataSegments;
@synthesize filePath = m_filePath;
@synthesize refCountedFD = m_refCountedFD;

+ (SegmentedMappedData*) segmentedMappedData:(NSString*)filePath
{
  SegmentedMappedData *obj = [[SegmentedMappedData alloc] init];
  obj.filePath = filePath;
  return [obj autorelease];
}

+ (SegmentedMappedData*) segmentedMappedDataWithDeferredMapping:(NSString*)filePath
                                                   refCountedFD:(RefCountedFD*)refCountedFD
                                                         offset:(off_t)offset
                                                            len:(size_t)len
{
  SegmentedMappedData *obj = [[SegmentedMappedData alloc] init];

  NSAssert(offset >= 0, @"offset");
  obj->m_mappedOffset = offset;

  NSAssert(len > 0, @"len");
  obj->m_mappedLen = len;

  NSAssert(filePath, @"filePath");
  obj.filePath = filePath;
  
  NSAssert(refCountedFD, @"refCountedFD");
  obj.refCountedFD = refCountedFD;
  
  return [obj autorelease];
}

- (void) dealloc
{
  if (self->m_mappedData) {
    // This branch will only be taken in a mapped segment object after the parent
    // has been deallocated.
    
    [self unmapSegment];
  }
  
  [AutoPropertyRelease releaseProperties:self thisClass:SegmentedMappedData.class];
  [super dealloc];
}

- (const void*) bytes
{
  // FIXME: should bytes implicitly attempt to map and return nil if there
  // was a failure to map? Unclear if existing code expects bytes to
  // return the correct pointer, might need to add mapSegment but
  // not really clear on how to detect error condition?
  
  //if (self->m_mappedData == NULL) {
  //  BOOL worked = [self mapSegment];
  //  NSAssert(worked, @"");
  //}
  
  NSAssert(self->m_mappedData != NULL, @"data not mapped");
  return self->m_mappedData;
}

// Note that it is perfectly fine to query the mapping length even if the file range
// has not actually be mapped into memory at this point.

- (NSUInteger) length
{
  return self->m_mappedLen;
}

- (BOOL) mapSegment
{
  if (self->m_mappedData != NULL) {
    // Already mapped
    return TRUE;
  }
  
  int fd = self.refCountedFD->m_fd;
  off_t offset = self->m_mappedOffset;
  size_t len = self->m_mappedLen;
  
  void *mappedData = mmap(NULL, len, PROT_READ, MAP_FILE | MAP_SHARED, fd, offset);
  
  if (mappedData == NULL) {
    return FALSE;
  }
  
  self->m_mappedData = mappedData;
  return TRUE;
}

- (void) unmapSegment
{
  // Can't be invoked on container data object

  NSAssert(self.mappedDataSegments == nil, @"unmapSegment can't be invoked on container");
  
  if (self->m_mappedData == nil) {
    // Already unmapped, no-op
    return;
  }

  int result = munmap(self->m_mappedData, self->m_mappedLen);
  NSAssert(result == 0, @"munmap result");
  
  self->m_mappedData = NULL;
  
  return;
}

- (NSArray*) makeSegmentedMappedDataObjects:(NSArray*)segInfo
{
  self.mappedDataSegments = [NSMutableArray array];
  NSAssert(self.mappedDataSegments, @"mappedDataSegments");
  self.refCountedFD = nil;

  // Open the file once, then keep the open file descriptor around so that each call
  // to mmap() need not also open the file descriptor.
  
  const char *cStr = [self.filePath UTF8String];
  int fd = open(cStr, O_RDONLY);
  if (fd == -1) {
    return nil;
  }
  
  RefCountedFD *rcFD = [RefCountedFD refCountedFD:fd];
  self.refCountedFD = rcFD;
  
  for (NSValue *value in segInfo) {
    NSRange range = [value rangeValue];
    
    NSUInteger offset = range.location;
    NSUInteger len = range.length;

    SegmentedMappedData *seg = [SegmentedMappedData segmentedMappedDataWithDeferredMapping:self.filePath
                                                                              refCountedFD:rcFD
                                                                                    offset:offset
                                                                                       len:len];
    [self.mappedDataSegments addObject:seg];
  }

  return self.mappedDataSegments;
}

@end
