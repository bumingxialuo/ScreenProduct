//
//  ViewController.m
//  ScreenProduct
//
//  Created by 不明下落 on 2019/1/14.
//  Copyright © 2019 不明下落. All rights reserved.
//

#import "ViewController.h"
#import "ScreeningProductView.h"
#import "TreeTagListModel.h"
#import <SVProgressHUD.h>
#import <YYModel.h>

@interface ViewController ()<ScreeningProductViewDelegate>
{
    NSString *_tagId;
    TreeTagListModel *_tagsModel;
    ScreeningListModel *_lastScreenModel;
//    ProductListModel *_listModel;
}
@property (weak, nonatomic) IBOutlet UILabel *remark;

@end

@implementation ViewController

- (IBAction)selctScreenItem:(UIButton *)sender {
    [self selectScreenItem];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setMaximumDismissTimeInterval:1];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self requestData];
}

- (void)requestData {
    //应该为从网络获取标签数据
    // ... ...
    
    //这里是模拟了一段数据
    NSError *error;
    NSString *dataStr = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"json" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&error];
    
    NSData *jsonData = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    _tagsModel = [TreeTagListModel yy_modelWithJSON:jsonData];
    
}

- (void)selectScreenItem {
    if (_tagsModel) {
        ScreeningProductView *alert = [[ScreeningProductView alloc] initWithListModel:_lastScreenModel tagsModel:_tagsModel];
        alert.alertDelegate = self;
        [alert show];
    } else {
        [SVProgressHUD showImage:[UIImage imageNamed:@""] status:@"数据拉取中"];
    }
    
}

#pragma mark - ScreeningProductViewDelegate
- (void)alertViewDidSelectSureButtonWithId:(NSString *)tagId {
    _tagId = tagId;
    //传回来的ID
    _remark.text = [NSString stringWithFormat:@"tagId:%@",_tagId];
}

- (void)alertViewDidSelectResetButtonClick {
    _tagId = @"";
    _lastScreenModel = nil;

}

- (void)alertViewDidSelectIndexItemWithModel:(ScreeningListModel *)model {
    _lastScreenModel = model;
}



@end
