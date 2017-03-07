//
//  MetadataBaseViewController.h
//  WatchWhileLayout-ios
//
//  Created by Ngo Than Phong on 3/5/17.
//  Copyright © 2017 kthangtd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define TYPE_METADATA_VIEW 0
#define TYPE_METADATA_PANEL_VIEW 1
#define TYPE_FULL_VIEW 2

#define EVENT_VIDEO_ITEM_CLICK @"event_video_item_click"

@interface MetadataBaseViewController : UICollectionViewController

@property (nonatomic, strong) NSString * nameVideo;

@property (nonatomic, assign) NSInteger typeView;

- (NSInteger)calcColumn;

@end
