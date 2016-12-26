//
//  AssetsLibraryManager.h
//  TEST
//
//  Created by hj on 15/10/4.
//  Copyright © 2015年 hj. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>



@interface AssetsLibraryManager : NSObject


+ (AssetsLibraryManager *)shareIntance;

- (void)createGroup:(NSString *)groupName block:(void(^)(BOOL success, NSError *error))block;

//返回ALAsset类型的数组
- (void)queryAssetsWithGroup:(NSString *)groupName block:(void(^)(NSArray *assetArray))block;

//保存单张图片1
- (void)savedPhotosWithGroup:(NSString *)groupName data:(NSData *)imageData blok:(void(^)(ALAsset *blockAset))block;
//删除图片
- (void)deleteAssets:(NSMutableArray *)assets block:(void(^)(BOOL success, NSError *error))block;

- (void)hasGroupAlbumWithName:(NSString *)groupName block:(void(^)(BOOL isExit))block;

//保存单张图片
- (void)savedImageWithGroup:(NSString *)groupName data:(NSData *)imageData blok:(void(^)(BOOL isSuccess))block;
@end
