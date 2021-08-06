#import "Detection.pbobjc.h"

#pragma mark - Detection

@implementation Detection

- (instancetype)init
{
  self = [super init];
  if (self) {
    _labelArray = [[NSMutableArray alloc] init];
    _labelIdArray = [[NSMutableArray alloc] init];
    _scoreArray = [[NSMutableArray alloc] init];
    _displayNameArray = [[NSMutableArray alloc] init];
  }
  return self;
}

@end
