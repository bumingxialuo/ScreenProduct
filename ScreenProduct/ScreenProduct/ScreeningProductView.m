//
//  ScreeningProductView.m
//  Star
//
//  Created by xia on 2018/6/26.
//  Copyright © 2018年 Mr_zhaohy. All rights reserved.
//

#import "ScreeningProductView.h"
#import "SCCollectionButtonsView.h"
#import "RDControlFactory.h"
#import "RDMacro.h"
#import "UIButton+Background.h"
#import "HandleTreeTagsModel.h"
#import <Masonry.h>
#import <RdAppSkinColor.h>
#import <SVProgressHUD.h>

@interface ScreeningProductView()<SCCollectionButtonsViewDelegate>
{
    ScreeningListModel *_listModel;     //遍历tree后的数组，不同层级的存放节点 | tagCollectionView的数据源
    TreeTagListModel *_sourceModel;     //网络获取的tree
    NSString *_selectTagId;             //点击item后的ID
}
@property(nonatomic, strong) UIView *bgView;
@property(nonatomic, strong) SCCollectionButtonsView *tagsView;
@property(nonatomic, strong) UIButton *resetButton;
@property(nonatomic, strong) UIButton *sureButton;
@end

@implementation ScreeningProductView

#pragma mark - initialization method
- (instancetype)initWithListModel:(ScreeningListModel *)listModel {
    self = [super init];
    if (self) {
        _listModel = listModel;
        self.backgroundColor = [UIColor whiteColor];
        [self tagsView];
        [self resetButton];
        [self sureButton];
        [self createLine];
    }
    return self;
}

- (instancetype)initWithListModel:(ScreeningListModel *)listModel tagsModel:(TreeTagListModel *)tagsModel {
    self = [super init];
    if (self) {
        if (!listModel) {
            _listModel = [HandleTreeTagsModel showDefaultData:tagsModel];
        } else {
            _listModel = listModel;
        }
        _sourceModel = tagsModel;
        self.backgroundColor = [UIColor whiteColor];
        [self tagsView];
        [self resetButton];
        [self sureButton];
        [self createLine];
    }
    return self;
}

#pragma mark - view opreation
- (void)createLine {
    UIView *line = [UIView getViewWithColor:[RdAppSkinColor sharedInstance].viewBackgroundColor superView:self];
    [line mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_offset(0);
        make.bottom.mas_offset(-(80*WIDTHRADIUS-1));
        make.height.mas_equalTo(1);
    }];
}

- (void)removeFromSuperViews {
    [self removeFromSuperview];
    [_bgView removeFromSuperview];
    _bgView = nil;
}

#pragma mark - event action
- (void)show {
    [[UIApplication sharedApplication].keyWindow endEditing:YES];
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    _bgView = [[UIView alloc] init];
    _bgView.frame = window.bounds;
    _bgView.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.4];
    [window addSubview:_bgView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissAlert)];
    [_bgView addGestureRecognizer:tap];
    [window addSubview:self];
    
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.bottom.equalTo(window);
        make.width.mas_equalTo(320*WIDTHRADIUS);
    }];
    self.transform = CGAffineTransformMakeTranslation(320*WIDTHRADIUS, 0);
    self.alpha = 0;
    [UIView animateWithDuration:.5f delay:0.f usingSpringWithDamping:.7f initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.alpha = 1;
        self.transform=CGAffineTransformMakeTranslation(0, 0);
    } completion:nil];
}

- (void)hideAlertView {
    [UIView animateWithDuration:0.3f animations:^{
        self.transform = CGAffineTransformMakeScale(0.2f, 1.21f);
        self.transform=CGAffineTransformMakeTranslation(320*WIDTHRADIUS, 0);
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperViews];
    }];
}

- (void)dismissAlert {
    [UIView animateWithDuration:0.3f animations:^{
        self.transform = CGAffineTransformMakeScale(0.2f, 1.21f);
        self.transform=CGAffineTransformMakeTranslation(320*WIDTHRADIUS, 0);
        self.alpha = 0;
    } completion:^(BOOL finished) {
        [self removeFromSuperViews];
    }];
    if (_alertDelegate && [_alertDelegate respondsToSelector:@selector(alertViewDidSelectSureButtonWithId:)]) {
        [_alertDelegate alertViewDidSelectSureButtonWithId:_selectTagId];
    }
}

- (void)resetButtonClick {
    _listModel = [HandleTreeTagsModel showDefaultData:_sourceModel];
    [self.tagsView updateWithListModel:_listModel];
    if (_alertDelegate && [_alertDelegate respondsToSelector:@selector(alertViewDidSelectResetButtonClick)]) {
        _selectTagId = @"";
        [_alertDelegate alertViewDidSelectResetButtonClick];
    }
}

- (void)sureButtonClick {
    [self hideAlertView];
}

#pragma mark - SCCollectionButtonsViewDelegate
- (BOOL)didSelectTagInSection:(NSInteger)section inRow:(NSInteger)row tagText:(NSString *)tag tagCode:(NSString *)code {
    //很大程度上依赖可变数组的copy特性
    ScreeningListModel *selectListModel = [HandleTreeTagsModel showSelectItemSelectTagId:code itemSection:section itemRow:row sourceModel:_listModel];
    if (!selectListModel) {
        [SVProgressHUD showImage:nil status:@"请选择上级标签"];
        return NO;
    }
    [self.tagsView updateWithListModel:selectListModel];
    _selectTagId = code;
    if (_alertDelegate && [_alertDelegate respondsToSelector:@selector(alertViewDidSelectIndexItemWithModel:)]) {
        [_alertDelegate alertViewDidSelectIndexItemWithModel:_listModel];
    }
    if (_alertDelegate && [_alertDelegate respondsToSelector:@selector(alertViewDidSelectSureButtonWithId:)]) {
        [_alertDelegate alertViewDidSelectSureButtonWithId:_selectTagId];
    }
    return YES;
}

- (void)returnTagCodeWhileSelecte:(NSString *)tagCode {
    _selectTagId = tagCode;
}

#pragma mark - Getter
- (SCCollectionButtonsView *)tagsView {
    if (!_tagsView) {
        _tagsView = [[SCCollectionButtonsView alloc] initWithFrame:CGRectMake(0, 0, 320*WIDTHRADIUS, HEIGHTOFSCREEN) style:TagsCollectionTypeNomal];
        _tagsView.leftAndRightPadding = 30.0;
        _tagsView.leftAndRightMagin = 20.0;
        _tagsView.topAndBottonMagin = 20.0;
        _tagsView.height = 30;
        _tagsView.normalBGColor = [RdAppSkinColor sharedInstance].viewBackgroundColor;
        _tagsView.normalTextColor = [RdAppSkinColor sharedInstance].emphasisSubTextColor;
        _tagsView.normalBoderColor = [RdAppSkinColor sharedInstance].viewBackgroundColor;
        _tagsView.selectTextColor = [UIColor whiteColor];
        _tagsView.selectBGColor = [RdAppSkinColor sharedInstance].mainColor;
        _tagsView.selectBoderColor = [RdAppSkinColor sharedInstance].mainColor;
        [_tagsView updateWithListModel:_listModel];
        [_tagsView setNormalBGColor:[UIColor whiteColor]] ;
        [self addSubview:_tagsView];
        _tagsView.tagsViewDelegate = self;
        [_tagsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(UIEdgeInsetsMake(0, 0, 80*WIDTHRADIUS, 0));
        }];
    }
    return _tagsView;
}

- (UIButton *)resetButton {
    if (!_resetButton) {
        _resetButton = [UIButton getButtonWithFontSize:16 TextColorHex:[RdAppSkinColor sharedInstance].emphasisSubTextColor backGroundColor:[UIColor whiteColor] radius:39*WIDTHRADIUS/2.0 superView:self];
        [_resetButton setTitle:@"重置" forState:UIControlStateNormal];
        [_resetButton addTarget:self action:@selector(resetButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _resetButton.layer.borderWidth = 1;
        _resetButton.layer.borderColor = [RdAppSkinColor sharedInstance].placeholderTextColor.CGColor;
        [_resetButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_offset(-20*WIDTHRADIUS);
            make.left.mas_offset(38*WIDTHRADIUS);
            make.size.mas_equalTo(CGSizeMake(115*WIDTHRADIUS, 39*WIDTHRADIUS));
        }];
    }
    return _resetButton;
}

- (UIButton *)sureButton {
    if (!_sureButton) {
        _sureButton = [UIButton getButtonWithFontSize:16 TextColorHex:[UIColor whiteColor] backGroundColor:[UIColor whiteColor] radius:39*WIDTHRADIUS/2.0 superView:self];
        [_sureButton setChameleonBackground];
        [_sureButton setTitle:@"确定" forState:UIControlStateNormal];
        [_sureButton addTarget:self action:@selector(sureButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_sureButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.mas_offset(-20*WIDTHRADIUS);
            make.right.mas_offset(-38*WIDTHRADIUS);
            make.size.mas_equalTo(CGSizeMake(115*WIDTHRADIUS, 39*WIDTHRADIUS));
        }];
    }
    return _sureButton;
}

@end
