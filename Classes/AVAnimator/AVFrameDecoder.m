//
//  AVFrameDecoder.m
//
//  Created by Moses DeJong on 12/30/10.
//

#import "AVFrameDecoder.h"

@implementation AVFrameDecoder

- (void) dealloc
{
  [super dealloc];
}

- (BOOL) openForReading:(NSString*)path
{
  [self doesNotRecognizeSelector:_cmd];
	return FALSE;
}

- (void) close
{
  [self doesNotRecognizeSelector:_cmd];
	return;
}

- (void) rewind
{
  [self doesNotRecognizeSelector:_cmd];
	return;
}

- (BOOL) advanceToFrame:(NSUInteger)newFrameIndex nextFrameBuffer:(CGFrameBuffer*)nextFrameBuffer
{
  [self doesNotRecognizeSelector:_cmd];
	return FALSE;
}

- (CGFrameBuffer*) currentFrameBuffer;
{
  [self doesNotRecognizeSelector:_cmd];
	return nil;
}

// Properties

- (NSUInteger) width
{
  [self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSUInteger) height
{
  [self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (BOOL) isOpen
{
  [self doesNotRecognizeSelector:_cmd];
	return FALSE;
}

- (NSUInteger) numFrames
{
  [self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSInteger) frameIndex
{
  [self doesNotRecognizeSelector:_cmd];
	return 0;
}

- (NSTimeInterval) frameDuration
{
  [self doesNotRecognizeSelector:_cmd];
	return 0;
}

@end
