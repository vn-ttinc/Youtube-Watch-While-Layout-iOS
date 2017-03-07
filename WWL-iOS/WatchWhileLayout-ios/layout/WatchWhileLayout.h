//
//  WatchWhileLayout.h
//  WatchWhileLayout-ios
//
//  Created by Ngo Than Phong on 3/1/17.
//  Copyright © 2017 kthangtd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define WWL_STATE_HIDED 0
#define WWL_STATE_MAXIMIZED 1
#define WWL_STATE_MINIMIZED 2

@class WWLWindow;

static WWLWindow * contentWindow;

#pragma mark ---- < WWL Listener >

@protocol WWLListener <NSObject>

@optional
- (void)WWL_onSliding:(CGFloat)offset;
- (void)WWL_onClicked;
- (void)WWL_onHided;
- (void)WWL_minimized;
- (void)WWL_maximized;

@end

#pragma mark ---- < Drag Orientation >

typedef NS_ENUM(NSInteger, DragOrientation) {
    DRAGGING_NONE = 1,
    DRAGGING_VERTICAL = 2,
    DRAGGING_HORIZONTAL = 3
};

#pragma mark ---- < UIView Extension >

@interface UIView (Extension)

@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end

#pragma mark ---- < WWL Window >

@interface WWLWindow : UIWindow

@end

#pragma mark ---- < WWL View >

@interface WWLView : UIView

@end

#pragma mark ---- < WWL PlayerViewWrapper >

@interface WWLPlayerViewWrapper : UIView

- (void)setBorderAlpha:(CGFloat)alpha;

@end

#pragma mark ---- < WWL OverlayView >

@interface WWLOverlayView : WWLView

@property (nonatomic, strong) UIButton * playerCollapseButton;

@property (nonatomic, strong) UIButton * playerFullscreenButton;

@end

#pragma mark ---- < WatchWhileLayout >

@interface WatchWhileLayout : UIViewController

@property (nonatomic, strong) UIView * playerView;

@property (nonatomic, strong) UIView * metadataView;

@property (nonatomic, strong) UIView * metadataPanelView;

@property (nonatomic, strong) WWLOverlayView * overlayView;

@property (nonatomic, assign) CGFloat miniPlayerWidth;

@property (nonatomic, assign) CGFloat miniPlayerPadding;

@property (nonatomic, assign, readonly) NSInteger state;

@property (nonatomic, assign, readonly) BOOL isFullScreen;

@property (nonatomic, weak) id<WWLListener> listener;

+ (void)init;

+ (WatchWhileLayout *)get;

- (void)setMetadataViewController:(UIViewController *)viewController;

- (void)setMetadataPanelViewController:(UIViewController *)viewController;

- (void)startPlay;

- (void)minimize:(BOOL)animated;

- (void)hided:(BOOL)animatedl;

- (void)maximize:(BOOL)animated;

- (void)enterPlayerFullscreen;

- (void)exitFullscreen;

- (void)showOverlayView:(BOOL)animated;

- (void)hideOverlayView:(BOOL)animated;

@end
