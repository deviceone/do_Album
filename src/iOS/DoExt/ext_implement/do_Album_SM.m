//
//  do_Album_SM.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_Album_SM.h"
#import <UIKit/UIKit.h>

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonNode.h"
#import "doIPage.h"
#import "doSourceFile.h"
#import "doUIModuleHelper.h"
#import "doIPage.h"
#import "doIScriptEngine.h"
#import "doDefines.h"
#import "YZAlbumMultipleViewController.h"
#import "doIApp.h"
#import "doIDataFS.h"
#import "doIOHelper.h"


@interface do_Album_SM()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic,copy) NSString *myCallbackName;
@property(nonatomic,weak) id<doIScriptEngine> myScritEngine;

@end

@implementation do_Album_SM
#pragma mark -
#pragma mark - 同步异步方法的实现
/*
 1.参数节点
     doJsonNode *_dictParas = [parms objectAtIndex:0];
     a.在节点中，获取对应的参数
     NSString *title = [_dictParas GetOneText:@"title" :@"" ];
     说明：第一个参数为对象名，第二为默认值
 
 2.脚本运行时的引擎
     id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
 
 同步：
 3.同步回调对象(有回调需要添加如下代码)
     doInvokeResult *_invokeResult = [parms objectAtIndex:2];
     回调信息
     如：（回调一个字符串信息）
     [_invokeResult SetResultText:((doUIModule *)_model).UniqueKey];
 异步：
 3.获取回调函数名(异步方法都有回调)
     NSString *_callbackName = [parms objectAtIndex:2];
     在合适的地方进行下面的代码，完成回调
     新建一个回调对象
     doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
     填入对应的信息
     如：（回调一个字符串）
     [_invokeResult SetResultText: @"异步方法完成"];
     [_scritEngine Callback:_callbackName :_invokeResult];
 */
//同步
//异步
- (void)save:(NSArray *)parms
{
    doJsonNode *_dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    NSString *_url = [_dictParas GetOneText:@"url" :@""];
    NSInteger imageWidth = [_dictParas GetOneInteger:@"width" :-1];
    NSInteger imageHeight = [_dictParas GetOneInteger:@"height" :-1];
    NSInteger imageQuality = [_dictParas GetOneInteger:@"quality" :100];
    NSString *_callbackName = [parms objectAtIndex:2];
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    if (_url ==nil || _url.length <=0) {//失败
        [_invokeResult SetResultBoolean:false];
    }
    else
    {
        NSString * imagePath = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentPage.CurrentApp :_url];
//        NSString *imagePath = [_scritEngine CurrentApp].DataFS.PathPublic;
        if (imagePath ==nil || imagePath.length <= 0) {//失败
            [_invokeResult SetResultBoolean:false];
            return ;
        }
        UIImage *imageTemp = [UIImage imageWithContentsOfFile:imagePath];
        if (imagePath == nil) {//失败
            [_invokeResult SetResultBoolean:false];
            return;
        }
        if (imageWidth >=0 && imageHeight >= 0) {//设置图片大小
            imageTemp = [doUIModuleHelper imageWithImageSimple:imageTemp scaledToSize:CGSizeMake(imageWidth, imageHeight)];
        }
        if (imageQuality > 100 || imageQuality < 0) {//设置图片质量
            NSData *imageData = UIImageJPEGRepresentation(imageTemp, 100);
            imageTemp = [UIImage imageWithData:imageData];
        }
        UIImageWriteToSavedPhotosAlbum(imageTemp, nil, nil, nil);//保存图片到相册
        [_invokeResult SetResultBoolean:true];
    }
    [_scritEngine Callback:_callbackName :_invokeResult];//返回结果
}

- (void)select:(NSArray *)parms
{
    doJsonNode *_dictParas = [parms objectAtIndex:0];
    self.myScritEngine = [parms objectAtIndex:1];
    self.myCallbackName = [parms objectAtIndex:2];
    //自己的代码实现
    NSInteger imageNum = [_dictParas GetOneInteger:@"num" :0];
    NSInteger imageWidth = [_dictParas GetOneInteger:@"width" :-1];
    NSInteger imageHeight = [_dictParas GetOneInteger:@"height" :-1];
    NSInteger imageQuality = [_dictParas GetOneInteger:@"quality" :100];
    
    id<doIPage> curPage = [self.myScritEngine CurrentPage];
    
    UIViewController *curVc = (UIViewController *)curPage.PageView;
    
    YZAlbumMultipleViewController *albummultipleVc = [[YZAlbumMultipleViewController alloc]init];
    albummultipleVc.num = imageNum;
    UINavigationController *naVc = [[UINavigationController alloc]initWithRootViewController:albummultipleVc];
    albummultipleVc.cancelSelectBlock = ^(NSError *error)
    {
        doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
        [_invokeResult SetError:@"错误"];
        [self.myScritEngine Callback:self.myCallbackName :_invokeResult];
    };
    albummultipleVc.selectSucessBlock = ^(NSMutableArray *selectImageArr)
    {
        NSString *_fileFullName = [self.myScritEngine CurrentApp].DataFS.PathPrivateTemp;
        doJsonNode *_jsonNode = [[doJsonNode alloc]init];
        NSMutableArray *urlArr = [[NSMutableArray alloc]init];
        for (int i = 0; i < selectImageArr.count ; i ++) {
            ALAsset *asset = [selectImageArr objectAtIndex:i];
            NSString *fileName = [NSString stringWithFormat:@"%@.png",[doUIModuleHelper stringWithUUID]];
            NSString *filePath = [NSString stringWithFormat:@"%@/%@",_fileFullName,fileName];
            UIImage *image = [UIImage imageWithCGImage:[[asset defaultRepresentation]fullResolutionImage]];
            if (imageWidth != -1 || imageHeight != -1)
            {
                image = [doUIModuleHelper imageWithImageSimple:image scaledToSize:CGSizeMake(imageWidth, imageHeight)];
            }
            NSData *imageData = UIImageJPEGRepresentation(image, imageQuality / 100.0);
            image = [UIImage imageWithData:imageData];
            [doIOHelper WriteAllBytes:filePath :imageData];
            [urlArr addObject:[NSString stringWithFormat:@"data://temp/do_Album/%@",fileName]];
        } 
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:urlArr options:NSJSONWritingPrettyPrinted error:nil];
        doInvokeResult *_invokeResult = [[doInvokeResult alloc]init:self.UniqueKey];
        [_invokeResult SetResultTextArray:urlArr];
        [self.myScritEngine Callback:self.myCallbackName :_invokeResult];
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [curVc presentViewController:naVc animated:YES completion:nil];
    });
#warning 首先实现单选
//    UIImagePickerController *pickerVc = [[UIImagePickerController alloc]init];
//    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
//        pickerVc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        if (IsPad) {
//            UIPopoverController *popover = [[UIPopoverController alloc]initWithContentViewController:pickerVc];
//            //permittedArrowDirections 设置箭头方向
//            [popover presentPopoverFromRect:CGRectMake(0, 0, 300, 300) inView:curVc.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//            pickerVc.delegate = self;
//            return;
//
//        }
//        else
//        {
//            pickerVc.delegate = self;
//            [curVc presentViewController:pickerVc animated:YES completion:^{
//                
//            }];
//        }
//        
//    }
//    else
//    {
//        [doUIModuleHelper Alert:@"提示" msg:@"当前设备不支持"];
//    }
}
#pragma -mark -
#pragma -mark UIImagePickerControllerDelegate代理方法
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}

@end


















