//
//  AssetsLibraryManager.m
//  TEST
//
//  Created by hj on 15/10/4.
//  Copyright © 2015年 hj. All rights reserved.
//

#import "AssetsLibraryManager.h"
#import <Photos/Photos.h>

#define IS_IOS8 [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0


@interface AssetsLibraryManager ()<PHPhotoLibraryChangeObserver>
@property(strong, nonatomic)ALAssetsLibrary *library;
@property(strong, nonatomic)PHAssetCollectionChangeRequest *changeRequest;

@property(strong, nonatomic) id  curGroup;

@end

@implementation AssetsLibraryManager
+ (AssetsLibraryManager *)shareIntance
{
    static AssetsLibraryManager *intance = nil;
    static dispatch_once_t onece;
    dispatch_once(&onece, ^{
        intance = [[AssetsLibraryManager alloc] init];

    });
    
    intance.library = [[ALAssetsLibrary alloc] init];
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:intance];

    return intance;
}

- (void)createAlbum
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"groupName"];
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error creating album: %@", error);
        }
    }];

}

//获取所有group
- (void)queryGroupsWithBlock:(void(^)(NSArray *groups))block
{
    if (IS_IOS8) {
        PHFetchResult * fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"obj=%@",obj);
           // PHAssetCollection
        }];

    }
    else
    {
        
    __block NSMutableArray *groupArray = [[NSMutableArray alloc] init];
    [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum  usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [groupArray addObject:group];
        if (group==nil) {
            block(groupArray);
        }
    } failureBlock:^(NSError *error) {
        block(groupArray);
    }];
    }
}

- (void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}


//是否存在group
/*
- (void)hasGroupAlbumWithName:(NSString *)groupName block:(void(^)(ALAssetsGroup *group))block
{
    __block ALAssetsGroup *tempGroup;
        [self.library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:groupName]) {
                tempGroup = group;
                *stop = YES;
            }
            if (group==nil) {
                block(tempGroup);
            }
            
        } failureBlock:^(NSError *error) {
            block(nil);
        }];
}
*/
- (void)queryAssetsWithGroup:(NSString *)groupName block:(void(^)(NSArray *assetArray))block
{
    __block NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    if (IS_IOS8) {
        //// 列出所有用户创建的相册
       // PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        
        PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        
        [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            PHAssetCollection *collection = (PHAssetCollection *)obj;
            if ([groupName compare:collection.localizedTitle]==NSOrderedSame) {
                PHFetchResult *result = [PHAsset fetchKeyAssetsInAssetCollection:collection options:nil];
                [result enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj) {
                        [tempArray addObject:obj];
                    }
                }];
                block(tempArray);
                return ;
            }
        }];

    }
    else
    {
        /*
        [self hasGroupAlbumWithName:groupName block:^(ALAssetsGroup *group) {
            
            if (group) {
                [group enumerateAssetsWithOptions:NSEnumerationConcurrent usingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    NSLog(@"ALAsset=%@",result);
                    if (result) {
                        [tempArray addObject:result];
                    }
                }];
            }
            block(tempArray);
    }];*/
    }
    
}

- (void)savedPhotosWithGroup:(NSString *)groupName data:(NSData *)imageData blok:(void(^)(ALAsset *blockAset))block
{
    if (IS_IOS8)
    {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            __block PHAssetChangeRequest *assetchange = [PHAssetChangeRequest creationRequestForAssetFromImage:[UIImage imageWithData:imageData]];
            PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
            __block BOOL isExit = NO;
            [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                PHAssetCollection *collection = (PHAssetCollection *)obj;
                NSLog(@"group Name:%@",collection.localIdentifier);
                if ([groupName compare:collection.localizedTitle]==NSOrderedSame) {
                    isExit = YES;
                    PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection];
                    [changeRequest addAssets:@[[assetchange placeholderForCreatedAsset]]];
                    return ;
                }
                
            }];
            
            if (isExit==NO) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    self.changeRequest =[PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:groupName];
                   // [changeRequest addAssets:@[[assetchange placeholderForCreatedAsset]]];
                    
                } completionHandler:^(BOOL success, NSError *error) {
                    

                    if (!success) {
                        NSLog(@"Error creating album: %@", error);
                    }
                    else
                    {
                                        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                            [self.changeRequest addAssets:@[[assetchange placeholderForCreatedAsset]]];
 
                                        } completionHandler:^(BOOL success, NSError * _Nullable error) {
                                            NSLog(@"Error addAssets: %@", error);

                                        }];
                    }
                }];
               //[assetchange  creationRequestForAssetFro
            }

        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"success=%d",success);
        }];

    }
    else
    {
    __weak typeof(self) weakself = self;
    [self.library writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
        __block BOOL isExit = NO;
        [weakself.library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
         {
             if ([groupName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
                 isExit = YES;
                 [weakself.library assetForURL: assetURL
                                resultBlock:^(ALAsset *asset) {
                                    [group addAsset: asset];
                                    block(asset);
                                } failureBlock:^(NSError *error) {
                                    block(nil);
                                }];
                 return;
             }
             if (group==nil && isExit==NO)
             {
                 [weakself.library addAssetsGroupAlbumWithName:groupName resultBlock:^(ALAssetsGroup *group)
                  {
                      [weakself.library assetForURL: assetURL
                                resultBlock:^(ALAsset *asset)
                       {
                           [group addAsset: asset];
                           block(asset);

                       } failureBlock:^(NSError *error) {
                           block(nil);

                       }];
                      
                  } failureBlock:^(NSError *error) {
                      block(nil);
                  }];
                 return;
             }
             
         }failureBlock:^(NSError *error) {
            block(nil);
         }];
    }];
    }
}

- (void)deleteAssets:(NSMutableArray *)assets block:(void(^)(BOOL success, NSError *error))block
{
    if ([assets count]>0)
    {
        NSMutableArray *assetUrls = [[NSMutableArray alloc] init];
        if (IS_IOS8) {
            /*
            [assets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [assetUrls addObject:[obj  valueForProperty:ALAssetPropertyAssetURL]];
            }];
            
            PHFetchResult * fetchResult = [PHAsset fetchAssetsWithALAssetURLs:assetUrls  options:nil];
            NSMutableArray * array = [[NSMutableArray alloc] init];
            [fetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if ([obj isKindOfClass:[PHAsset class]]) {
                    [array addObject:obj];
                }
            }];
             */
            
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                [PHAssetChangeRequest deleteAssets:assets];
            } completionHandler:^(BOOL success, NSError *error) {
                block(success,error);
                NSLog(@"Finished deleting asset. %@", (success ? @"Success." : error));
            }];
        }
        
        else
        {
            [assetUrls addObjectsFromArray:assets];
            [assetUrls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                ALAsset * asset = (ALAsset*) obj;
                [asset setImageData:nil metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
                    // NSLog(@"Asset url %@ should be deleted. (Error %@)", assetURL, error);
                    
                }];
            }];
            block(YES,nil);
        }
    }

}

-(void)addAssetURL:(NSURL*)assetURL toAlbum:(NSString*)albumName
{
    //相册存在标示
    __block BOOL albumWasFound = NO;
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
    //search all photo albums in the library
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         //判断相册是否存在
         if ([albumName compare: [group valueForProperty:ALAssetsGroupPropertyName]]==NSOrderedSame) {
             
             //存在
             albumWasFound = YES;
             
             //get a hold of the photo's asset instance
             [assetsLibrary assetForURL: assetURL
                            resultBlock:^(ALAsset *asset) {
                                
                                //add photo to the target album
                                [group addAsset: asset];
                                
                                //run the completion block
                                
                            } failureBlock:^(NSError *error) {
                                
                            }];
             return;
         }
         
         //如果不存在该相册创建
         if (group==nil && albumWasFound==NO)
         {
             __weak ALAssetsLibrary* weakSelf = assetsLibrary;
             
             //创建相册
             [assetsLibrary addAssetsGroupAlbumWithName:albumName resultBlock:^(ALAssetsGroup *group)
              {
                  //get the photo's instance
                  [weakSelf assetForURL: assetURL
                            resultBlock:^(ALAsset *asset)
                   {
                       //add photo to the newly created album
                       [group addAsset: asset];
                       //call the completion block
                   } failureBlock:^(NSError *error) {
                       
                   }];
                  
              } failureBlock:^(NSError *error) {
                  
              }];
             return;
         }
         
     }failureBlock:^(NSError *error) {
         
     }];
}

- (void)createGroup:(NSString *)groupName block:(void(^)(BOOL success, NSError *error))block
{
    if (IS_IOS8) {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:groupName];
        } completionHandler:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Error creating album: %@", error);
            }
            [self hasGroupAlbumWithName:groupName block:^(BOOL isExit) {
                block(success,error);
  
            }];
        }];
    }
    else
    {
        __weak typeof(self) weakself = self;
        [weakself.library addAssetsGroupAlbumWithName:groupName resultBlock:^(ALAssetsGroup *group) {
            
        } failureBlock:^(NSError *error) {
            if (error) {
                block(NO,error);
            }
            else
            {
                block(YES,error);
            }
        }];
    }
}

- (void)hasGroupAlbumWithName:(NSString *)groupName block:(void(^)(BOOL isExit))block
{
    __weak typeof(self) weakSelf = self;
    if (IS_IOS8) {
        __block BOOL isExit = NO;
        
        PHFetchResult *fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
        [fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            PHAssetCollection *collection = (PHAssetCollection *)obj;
            NSLog(@"group Name:%@",collection.localIdentifier);
            if ([groupName compare:collection.localizedTitle]==NSOrderedSame) {
                isExit = YES;
                weakSelf.curGroup = collection;
                *stop = YES;
            }
        }];
        block(isExit);
    }
    else
    {
        __block BOOL isExit = NO;
        [weakSelf.library enumerateGroupsWithTypes:ALAssetsGroupAlbum usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if ([[group valueForProperty:ALAssetsGroupPropertyName] isEqualToString:groupName]) {
                isExit = YES;
                weakSelf.curGroup = group;
                *stop = YES;
            }
            if (!group) {
                block(isExit);
            }
            
        } failureBlock:^(NSError *error) {
        }];
    }
}

- (void)savedImageWithGroup:(NSString *)groupName data:(NSData *)imageData blok:(void(^)(BOOL isSuccess))block
{
    __weak typeof(self) weakSelf = self;

    if (IS_IOS8)
    {
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            __block PHAssetChangeRequest *assetchange = [PHAssetChangeRequest creationRequestForAssetFromImage:[UIImage imageWithData:imageData]];
            PHAssetCollectionChangeRequest *changeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:weakSelf.curGroup];
            [changeRequest addAssets:@[[assetchange placeholderForCreatedAsset]]];
            
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"---success=%d--ERROR =%@",success,[error localizedDescription]);
            block(success);

        }];
    }
    else
    {
        [weakSelf.library writeImageDataToSavedPhotosAlbum:imageData metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            
            if (!error) {
                [weakSelf.library assetForURL: assetURL
                                  resultBlock:^(ALAsset *asset) {
                                      [weakSelf.curGroup addAsset: asset];
                                  } failureBlock:^(NSError *error) {
                                      if (error) {
                                          block(NO);
                                      }
                                      else
                                      {
                                          block(YES);
                                      }
                                  }];
            }
            else
            {
                block(NO);
            }
            
        }];
    }
}
#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
   // PHObjectChangeDetails *changeDetails = [changeInstance changeDetailsForObject:self.asset];
    NSLog(@"changeInstance = %@",changeInstance);
}
@end

