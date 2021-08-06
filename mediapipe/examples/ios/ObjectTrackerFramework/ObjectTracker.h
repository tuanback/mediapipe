#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import "Detection.pbobjc.h"

@class ObjectTracker;

@protocol ObjectTrackerDelegate <NSObject>
- (void)objectTracker: (ObjectTracker*)objectTracker didOutputDetections: (NSArray<Detection*>*)detections;
- (void)objectTracker: (ObjectTracker*)objectTracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
@end

@interface ObjectTracker : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)processVideoFrame:(CVPixelBufferRef)imageBuffer
                timestamp:(CMTime)timestamp;

@property (weak, nonatomic) id <ObjectTrackerDelegate> delegate;

@end
