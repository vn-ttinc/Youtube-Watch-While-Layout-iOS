//
//  MetadataBaseViewController.m
//  WatchWhileLayout-ios
//
//  Created by Ngo Than Phong on 3/5/17.
//  Copyright © 2017 kthangtd. All rights reserved.
//

#import "MetadataBaseViewController.h"

#define IS_TABLET ( [[[UIDevice currentDevice] model] isEqualToString:@"iPad"] )
#define IS_LANDSCAPE ( UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) )

@implementation MetadataBaseViewController

#define CARD_HEADER_ITEM @"card_header_item"
#define CARD_TITLE_ITEM @"card_title_item"
#define CARD_ROW_ITEM @"card_row_item"

#pragma mark ---- < Config >

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCell];
    [self.collectionView reloadData];
}

- (void)registerCell {
    [self.collectionView registerNib:[UINib nibWithNibName:CARD_ROW_ITEM bundle:nil] forCellWithReuseIdentifier:CARD_ROW_ITEM];
    [self.collectionView registerNib:[UINib nibWithNibName:CARD_TITLE_ITEM bundle:nil] forCellWithReuseIdentifier:CARD_TITLE_ITEM];
    [self.collectionView registerNib:[UINib nibWithNibName:CARD_HEADER_ITEM bundle:nil] forCellWithReuseIdentifier:CARD_HEADER_ITEM];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.collectionView reloadData];
}

- (NSInteger)calcColumn {
    if (IS_TABLET) {
        if (self.typeView == TYPE_FULL_VIEW && IS_LANDSCAPE) {
            return 4;
        }
        return 3;
    } else {
        if (IS_LANDSCAPE) {
            return 2;
        }
        return 1;
    }
}

#pragma mark ---- < Set Propery >

- (void)setNameVideo:(NSString *)nameVideo {
    _nameVideo = nameVideo;
    [self.collectionView reloadData];
}

#pragma mark ---- < CollectionView >

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (!IS_LANDSCAPE || self.typeView == TYPE_FULL_VIEW) {
        return UIEdgeInsetsMake(6, 6, 6, 6);
    }
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 6;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (IS_TABLET && IS_LANDSCAPE && self.typeView == TYPE_METADATA_VIEW) {
        return 1;
    }
    return 32;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = indexPath.row + self.typeView;
    switch (index) {
        case 0:
            return CGSizeMake(self.collectionView.frame.size.width, 70);
        case 1:
            return CGSizeMake(self.collectionView.frame.size.width, 60);
        default: {
            NSInteger numCol = [self calcColumn];
            CGFloat maxW = self.collectionView.frame.size.width - (numCol+1)*6;
            maxW = maxW/numCol;
            CGFloat maxH = maxW/16*9+66;
            return CGSizeMake(maxW, maxH);
        }
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.typeView != TYPE_FULL_VIEW) {
        NSInteger index = indexPath.row + MIN(self.typeView, 1);
        switch (index) {
            case 0: {
                UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CARD_HEADER_ITEM forIndexPath:indexPath];
                UILabel * title = (UILabel *)[cell viewWithTag:1010];
                title.text = self.nameVideo;
                return cell;
            }
            case 1: {
                return [collectionView dequeueReusableCellWithReuseIdentifier:CARD_TITLE_ITEM forIndexPath:indexPath];
            }
        }
    }
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:CARD_ROW_ITEM forIndexPath:indexPath];
    UILabel * title = (UILabel *)[cell viewWithTag:1010];
    title.text = [NSString stringWithFormat:@"This is element #%d", indexPath.row-1+self.typeView];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = 2 - self.typeView;
    if (indexPath.row >= index) {
        UICollectionViewCell * cell = [collectionView cellForItemAtIndexPath:indexPath];
        UIView * view = [cell viewWithTag:1010];
        if (view != nil) {
            UILabel * label = (UILabel *)view;
            [[NSNotificationCenter defaultCenter] postNotificationName:EVENT_VIDEO_ITEM_CLICK object:nil userInfo:@{@"name": label.text}];
        }
    }
    
}

@end
