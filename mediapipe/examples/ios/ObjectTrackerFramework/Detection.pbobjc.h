#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class Detection;

@interface Detection: NSObject

- (instancetype)init;
/** i-th label or label_id has a score encoded by the i-th element in score. */
@property(nonatomic, readwrite, strong, nullable) NSMutableArray<NSString*> *labelArray;

@property(nonatomic, readwrite, strong, nullable) NSMutableArray<NSNumber*> *labelIdArray;

@property(nonatomic, readwrite, strong, nullable) NSMutableArray<NSNumber*> *scoreArray;

/** Location data corresponding to all detected labels above. */
@property(nonatomic, readwrite) CGRect locationData;

/** Optional string to specify track_id if detection is part of a track. */
@property(nonatomic, readwrite, copy, nullable) NSString *trackId;

/** Optional unique id to help associate different Detections to each other. */
@property(nonatomic, readwrite) int64_t detectionId;
/**
 * Human-readable string for display, intended for debugging purposes. The
 * display name corresponds to the label (or label_id). This is optional.
 **/
@property(nonatomic, readwrite, strong, nullable) NSMutableArray<NSString*> *displayNameArray;
@end
