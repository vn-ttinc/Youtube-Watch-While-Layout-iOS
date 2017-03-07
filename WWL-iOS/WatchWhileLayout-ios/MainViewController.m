//
//  MainViewController.m
//  WatchWhileLayout-ios
//
//  Created by Ngo Than Phong on 3/1/17.
//  Copyright © 2017 kthangtd. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

#import "MainViewController.h"
#import "WatchWhileLayout.h"
#import "MetadataViewController.h"
#import "MetadataPanelViewController.h"

@interface MainViewController () <WWLListener>

@property (nonatomic, strong) MPMoviePlayerController * moviePlayer;

@property (nonatomic, strong) MetadataViewController * metaView;

@property (nonatomic, strong) MetadataPanelViewController * metaPanelView;

@end

@implementation MainViewController

#pragma mark ---- < Init >

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[WatchWhileLayout get] setListener:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(goDetail:)
                                                 name:EVENT_VIDEO_ITEM_CLICK
                                               object:nil];
    
    self.moviePlayer= [[MPMoviePlayerController alloc] init];
    self.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    [[WatchWhileLayout get] setPlayerView:self.moviePlayer.view];
    
    self.metaView = [self getViewController:[MetadataViewController class]];
    [[WatchWhileLayout get] setMetadataViewController:self.metaView];
    
    if ([[[UIDevice currentDevice] model] isEqualToString:@"iPad"]) {
        self.metaPanelView = [self getViewController:[MetadataPanelViewController class]];
        [[WatchWhileLayout get] setMetadataPanelViewController:self.metaPanelView];
    }
}

- (id)getViewController:(Class)class {
    return [self.storyboard instantiateViewControllerWithIdentifier: NSStringFromClass(class)];
}

#pragma mark ---- < Handle Item Tap >

- (void)goDetail:(NSNotification *)notify {
    NSDictionary * userInfo = notify.userInfo;
    
    [[WatchWhileLayout get] startPlay];
    
    if (self.moviePlayer != nil) {
        [self.moviePlayer stop];
        NSString * path =[[NSBundle mainBundle] pathForResource:@"sample_video" ofType:@"mp4"];
        NSURL * url =[NSURL fileURLWithPath:path];
        self.moviePlayer.contentURL = url;
        [self.moviePlayer prepareToPlay];
        [self.moviePlayer play];
    }
    
    if (self.metaView != nil) {
        self.metaView.nameVideo = [userInfo objectForKey:@"name"];
    }
    
}

#pragma mark ---- < WWL Listener >

- (void)WWL_onHided {
    if (self.moviePlayer != nil) {
        [self.moviePlayer stop];
    }
}

@end
