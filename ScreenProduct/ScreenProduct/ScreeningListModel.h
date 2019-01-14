//
//  ScreeningListModel.h
//  Star
//
//  Created by xia on 2018/6/26.
//  Copyright © 2018年 Mr_zhaohy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ScreeningDataModel: NSObject
@property(nonatomic, assign) BOOL selected;
@property(nonatomic, assign) BOOL show;
@property(nonatomic, copy) NSString *tag;
@property(nonatomic, copy) NSString *code;
@property(nonatomic, copy) NSString *parentId;
@end

@protocol ScreeningDataModel<NSObject>
@end

@interface ScreeningTagGroupModel : NSObject
@property(nonatomic, copy) NSString *groupTag;
@property(nonatomic, assign) BOOL currentSelect;
@property(nonatomic, strong) NSMutableArray<ScreeningDataModel> *tags;
@end

@protocol ScreeningTagGroupModel<NSObject>
@end

@interface ScreeningListModel : NSObject

@property(nonatomic, strong) NSMutableArray<ScreeningTagGroupModel> *list;

@end
