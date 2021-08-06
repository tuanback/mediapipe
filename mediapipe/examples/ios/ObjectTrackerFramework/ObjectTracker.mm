#import <UIKit/UIKit.h>
#import "ObjectTracker.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPTimestampConverter.h"
#include "mediapipe/framework/formats/detection.pb.h"

static NSString* const kGraphName = @"mobile_gpu";
static const char* kInputStream = "input_video";
static const char* kOutputStream = "output_video";
static const char* kOutputPacketStream = "tracked_detections";
static const char* kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";

@interface ObjectTracker() <MPPGraphDelegate>
@property(nonatomic) MPPGraph* mediapipeGraph;
@property(nonatomic) MPPTimestampConverter* timestampConverter;
@end

@implementation ObjectTracker {}

#pragma mark - Cleanup methods

- (void)dealloc {
  self.mediapipeGraph.delegate = nil;
  [self.mediapipeGraph cancel];
  // Ignore errors since we're cleaning up.
  [self.mediapipeGraph closeAllInputStreamsWithError:nil];
  [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph*)loadGraphFromResource:(NSString*)resource {
  // Load the graph config resource.
  NSError* configLoadError = nil;
  NSBundle* bundle = [NSBundle bundleForClass:[self class]];
  if (!resource || resource.length == 0) {
    return nil;
  }
  NSURL* graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
  NSData* data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
  if (!data) {
    NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
    return nil;
  }
  
  // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
  mediapipe::CalculatorGraphConfig config;
  config.ParseFromArray(data.bytes, data.length);
  
  // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
  MPPGraph* newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
  [newGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
  [newGraph addFrameOutputStream:kOutputPacketStream outputPacketType:MPPPacketTypeRaw];
  return newGraph;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
    self.mediapipeGraph.delegate = self;
    // Set maxFramesInFlight to a small value to avoid memory contention for real-time processing.
    self.mediapipeGraph.maxFramesInFlight = 2;
    
    self.timestampConverter = [[MPPTimestampConverter alloc] init];
  }
  return self;
}

- (void)startGraph {
  // Start running self.mediapipeGraph.
  NSError* error;
  if (![self.mediapipeGraph startWithError:&error]) {
    NSLog(@"Failed to start graph: %@", error);
  }
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string&)streamName {
  if (streamName == kOutputStream) {
    [_delegate objectTracker: self didOutputPixelBuffer: pixelBuffer];
  }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph*)graph
       didOutputPacket:(const ::mediapipe::Packet&)packet
            fromStream:(const std::string&)streamName {
  if (streamName == kOutputPacketStream) {
    if (packet.IsEmpty()) {
      return;
    }
    
    const auto& all_detections = packet.Get<std::vector<::mediapipe::Detection>>();
    
    NSMutableArray<Detection*> *detections = [[NSMutableArray alloc] init];
    
    for (int index = 0; index < all_detections.size(); ++index) {
      const auto& detection = all_detections[index];
      Detection* convertedDetection = [self convertDetection: detection];
      [detections addObject: convertedDetection];
    }
    
    [_delegate objectTracker: self didOutputDetections: detections];
  }
}

- (Detection*) convertDetection:(mediapipe::Detection) detection {
  Detection *result = [[Detection alloc] init];
  
  for (int i = 0; i < detection.label_size(); ++i) {
    NSString* label = [NSString stringWithUTF8String:detection.label(i).c_str()];
    NSLog(@"[Framework] label %@", label);
    [result.labelArray addObject: label];
  }
  
  for (int i = 0; i < detection.label_id_size(); ++i) {
    NSNumber *label_id = [NSNumber numberWithInt:detection.label_id(i)];
    NSLog(@"[Framework] label id %d", [label_id integerValue]);
    [result.labelIdArray addObject: label_id];
  }
  
  for (int i = 0; i < detection.score_size(); ++i) {
    NSNumber *score = [NSNumber numberWithFloat:detection.score(i)];
    NSLog(@"[Framework] score %f", [score floatValue]);
    [result.scoreArray addObject: score];
  }
  
  if (detection.has_location_data()) {
    const auto& locationData = detection.location_data();
    result.locationData = [self convertLocationData: locationData];
    NSLog(@"[Framework] bbox %@", NSStringFromCGRect(result.locationData));
  }
  
  if (detection.has_track_id()) {
    NSString* trackId = [NSString stringWithUTF8String:detection.track_id().c_str()];
    result.trackId = trackId;
    NSLog(@"[Framework] trackId %@", trackId);
  }
  
  if (detection.has_detection_id()) {
    result.detectionId = detection.detection_id();
    NSLog(@"[Framework] detectionId %d", result.detectionId);
  }
  
  for (int i = 0; i < detection.display_name_size(); ++i) {
    NSString* displayName = [NSString stringWithUTF8String:detection.display_name(i).c_str()];
    NSLog(@"[Framework] displayName %@", displayName);
    [result.displayNameArray addObject: displayName];
  }
  
  return result;
}

- (CGRect) convertLocationData:(mediapipe::LocationData) location {
  if (location.has_relative_bounding_box()) {
    NSLog(@"[Framework] has bounding box");
    const auto& bbox = location.relative_bounding_box();
    CGFloat xmin = bbox.xmin();
    CGFloat ymin = bbox.ymin();
    CGFloat width = bbox.width();
    CGFloat height = bbox.height();
    CGRect rect = CGRectMake(xmin, ymin, width, height);
    return rect;
  }
  
  return CGRectZero;
}

- (void) processVideoFrame: (CVPixelBufferRef) imageBuffer
                 timestamp: (CMTime) timestamp {
  [self.mediapipeGraph
   sendPixelBuffer:imageBuffer
   intoStream:kInputStream
   packetType:MPPPacketTypePixelBuffer
   timestamp: [self.timestampConverter timestampForMediaTime:timestamp]];
}

@end
