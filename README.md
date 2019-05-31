# ScreenProduct
一个多级筛选框
## 背景
公司项目的商品部分需要一个筛选框，任意多级标签筛选。根据标签的tagId，进行商品的筛选。不能跨层点击，下级标签为上级所有标签的子标签。类似省市区，但是市为所有省所有的城市。因为项目从0开始，数据量少，为了标签的丰富，所以需要展示所有标签。代码放在最后。

![演示.gif](https://upload-images.jianshu.io/upload_images/1918401-a2249486a8c8ec1b.gif?imageMogr2/auto-orient/strip)


## 数据准备
标签数据源为接口提供的一次性返回的树形数据。解析的model如下
```
#import <Foundation/Foundation.h>

@protocol TreeTagListModel
@end


@interface TreeTagListModel : NSObject

@property(nonatomic, copy) NSString *id;

/**
 标签名称
 */
@property(nonatomic, copy) NSString *name;

/**
 标签code
 */
@property(nonatomic, copy) NSString *code;

/**
 标签所在层级名
 */
@property(nonatomic, copy) NSString *groupName;

/**
 上一级标签的ID
 */
@property(nonatomic, copy) NSString *parentId;

@property(nonatomic, strong) NSArray<TreeTagListModel> *tags;


@end
```
>说明：由于这个项目是18年中旬的了，测试的服务器也停了。所以自己写了一串json文本放在项目工程中。便于演示。
```
- (void)requestData {
    //应该为从网络获取标签数据
    // ... ...
    
    //这里是模拟了一段数据
    NSError *error;
    NSString *dataStr = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    
    NSData *jsonData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    _tagsModel = [TreeTagListModel yy_modelWithJSON:jsonData];
    
}
```
## 视图分析
弹框由 三部分组成
- bgView:UIView。半透明的背景视图，用于点击时隐藏弹框
- 底部的两个按钮
- tagsView：SCCollectionButtonsView。是个自定义的collectionView。
>说明：根据不同级别的标签分成不同的Sections。
每个item的大小则根据要显示的内容计算出来。
item的状态变化，item选中后的数据刷新则全都交给数据model来做，然后reloadData，刷新视图的显示。

## 数据处理
数据处理是这个控件花费时间最多的部分。其实原来的方案不是完全依据数据的变化来reload的。是因为产品改需求了：本来是默认显示三级标签，然后每一级默认展示上一级的字标签。改为适配多种标签及标签分组，然后下级标签全部展示出来。
为此把之前分散在其他地方的数据处理部分的代码全部放在了一个单独的文件ScreeningListModel中
这里介绍一下用到的model。

1、解析源数据model
- TreeTagListModel。用来解析网络获取的数据的。获取到的数据是树形的，类似省市区。
---
2、控件所需的数据model
- ScreeningDataModel 。Collection的item需要的数据：是否被选中，是否需要展示（父标签被选中后只展示当前父标签的子标签，其他的子标签不展示），等。

- ScreeningTagGroupModel。Collection的单个section所需的数据集合+组标签名字。
- ScreeningListModel 。所有的collection需要的数据集合
---
3、工具model
- **HandleTreeTagsModel**。这是一个工具类。可以将ScreeningListModel转换为TreeTagListModel，还有处理选中一个tag之后的数据的刷新。
头文件如下



```
#import <Foundation/Foundation.h>
#import "TreeTagListModel.h"
#import "ScreeningListModel.h"

@interface HandleTreeTagsModel : NSObject

/**
 初始化数据

 @param model 源数据
 @return 目标collection数据源
 */
+ (ScreeningListModel *)showDefaultData:(TreeTagListModel *)model;


/**
 选中某个item后的数据刷新

 @param tagId 当前选中item的ID
 @param section item所在的section
 @param row item所在的row
 @param sourceModel 数据源（这是一个copy的可变数组集）
 @return 处理后的数据 （不可选中时返回nil）
 */
+ (ScreeningListModel *)showSelectItemSelectTagId:(NSString *)tagId itemSection:(NSInteger)section itemRow:(NSInteger)row sourceModel:(ScreeningListModel *)sourceModel;
@end
```
然后在ScreeningProductView的初始化方法中调用
 ```
 + (ScreeningListModel *)showDefaultData:(TreeTagListModel *)model;
```

这样就能获得一个页面初始化所需的展示数据。转换的方式为，将网络获取的数据源一层层遍历，add到一个可变数组中，然后返回。这个遍历的过程是循环的，用到了函数的递归。作递归操作的时机是，遍历完了当前节点所有的子节点时接着便利下一个节点的子节点，直到这一层遍历完毕。接着继续下一个层级的遍历。有点绕。这个地方我也是思考了很久的。一开始时硬编码，找到其中的repeat部分，觉得很像是一个尾递归？递归？然后把它写成了递归的方式。
>说明：treeArray的作用：存放已被遍历节点，当 当前层级的节点遍历完以后，保存当前层级的targetGroup作一个section，然后开始遍历 存放节点数组 的子节点（这个子节点时上层所有节点的子节点）

>说明：其中我们需要的目标model是存放在函数的第一个参数中的，在遍历过程当中一直存在。其中很大程度上借用了可变数组的拷贝属性。（没有copy然后return回一个新的变量）。因为我在写这个的过程中发现如果我新创建了一个数组并且把处理完的数组copy后return给他，虽然这个数组有了新的内存地址，但是这个地址里面的数据的内存地址还是原先的，并没有新创建地址存放它。
```
/**
 递归遍历各个层级的子节点

 @param list 遍历后存放的数组
 @param treeList 层级树
 */
+ (void)createGroupTags:(NSMutableArray<ScreeningTagGroupModel> *)list
          treeListModel:(NSArray<TreeTagListModel> *)treeList
{
    ScreeningTagGroupModel *targetGroup = [ScreeningTagGroupModel new];
    targetGroup.tags = [NSMutableArray new];
    
    NSMutableArray<TreeTagListModel> *treeArray = [NSMutableArray new];
    int i = 0;
    for (TreeTagListModel *T_tmp in treeList) {
        i ++ ;
        targetGroup.groupTag = T_tmp.groupName;
        ScreeningDataModel *dataModel = [ScreeningDataModel new];
        dataModel.tag = T_tmp.name;
        dataModel.selected = NO;
        dataModel.code = T_tmp.id;
        dataModel.parentId = T_tmp.parentId;
        dataModel.show = YES;
        [targetGroup.tags addObject:dataModel];
        [treeArray addObject:T_tmp];
        //当遍历到最后一个时，遍历下一层级
        if (i == treeList.count) {
            [list addObject:targetGroup];
            NSMutableArray *nextTree = [NSMutableArray new];
            for (TreeTagListModel *subTree in treeArray) {
                [nextTree addObjectsFromArray:subTree.tags];
            }
            //做递归
            [self createGroupTags:list treeListModel:[nextTree copy]];
        }
    }
}
```

还有另一个操作。点击单个item后的数据刷新。这个部分需要注意的地方有：
- 不能跨层级点击。用到了currentSelect这个变量来记录当前这个section是否被选中过。
- 按钮 不能复选。用到selected来控制。将所有的标签的selected置为NO，当前选中这个赋值为YES。
- 下一级别的刷新。下级展示当前级所有的子标签，并且将选中状态置为未选中。
 ```
+ (ScreeningListModel *)showSelectItemSelectTagId:(NSString *)tagId itemSection:(NSInteger)section itemRow:(NSInteger)row sourceModel:(ScreeningListModel *)sourceModel {
    ScreeningListModel *targetModel = [ScreeningListModel new];
    targetModel = sourceModel;
    
    //上一级
    if (section > 0) {
        //第一级不存在上一级
        ScreeningTagGroupModel *lastGroup = sourceModel.list[section-1];
        if (!lastGroup.currentSelect) {
            return nil;
        }
    }
    
    //当前级的状态  
    ScreeningTagGroupModel *currentGroup = sourceModel.list[section];
    currentGroup.currentSelect = YES;
    for (ScreeningDataModel *dataModel in currentGroup.tags) {
        dataModel.selected = NO;
        if ([dataModel.code isEqualToString:tagId]) {
            dataModel.selected = YES;
        }
    }
    
    //当前级所在级的所有下级 - 选中状态置空
    for (NSInteger i = section+1; i < sourceModel.list.count; i ++) {
        ScreeningTagGroupModel *groupModel = targetModel.list[I];
        for (ScreeningDataModel *dataModel in groupModel.tags) {
            dataModel.selected = NO;
            //当前级的下一级数据刷新
            if (i == section+1) {
                if ([dataModel.parentId isEqualToString:tagId]) {
                    dataModel.show = YES;
                } else {
                    dataModel.show = NO;
                }
            }
            groupModel.currentSelect = NO;
        }
    }
    
    
    return targetModel;
}
```

## 使用
在视图内部调用UICollectionView的Delegate、DataSource, FlowLayout部分就不多说了。基本就是常规的用法。
控件的点击事件，controller部分实现这个代理就可以实现标签的筛选：
```
@protocol ScreeningProductViewDelegate<NSObject>

/**
 点击确定按钮

 @param tagId tagID
 */
- (void)alertViewDidSelectSureButtonWithId: (NSString *)tagId;

/**
 点击重置按钮 -- 清空tagID，发起搜索请求
 */
- (void)alertViewDidSelectResetButtonClick;

/**
 保存点击记录

 @param model 搜索标签状态的保存数据
 */
- (void)alertViewDidSelectIndexItemWithModel:(ScreeningListModel *)model;

@end
```

## 反思
以前写的代码没有好好整理过，简直罪过。有时间还是要再整理一下这个逻辑，争取见码知意。目标是写出不写注释的好代码。还有代码的写法还有待加强。emmm,或许还有更好的实现方法。







