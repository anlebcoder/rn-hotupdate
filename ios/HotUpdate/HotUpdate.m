//
//  HotUpdate.m
//  HotUpdate
//
//  Created by named on 2017/9/25.
//  Copyright © 2017年 jiwei. All rights reserved.
//

#import "HotUpdate.h"
#import <UIKit/UIKit.h>
#import "SSZipArchive/SSZipArchive.h"
#define cacheDir [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
#define documentDir [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject]


@implementation HotUpdate
RCT_EXPORT_MODULE();
/**
 * 暴露常量给rn
 */
-(NSDictionary<NSString *,id> *)constantsToExport {
    return @{
             @"documentDir": documentDir,
             @"cacheDir": cacheDir
             };
}

-(NSURL *)getBundlePath{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *app_build = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    id value = [stand valueForKey:@"build"];
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *jsPath = [documentDir stringByAppendingPathComponent:@"index.ios.jsbundle"];
    NSString *assetsPath = [documentDir stringByAppendingPathComponent:@"assets"];
    if ([self needOverwrite:app_build version:value]) {
        [manager removeItemAtPath:jsPath error:nil];
        [manager removeItemAtPath:assetsPath error:nil];
        NSString *jsBundlePath = [[NSBundle mainBundle] pathForResource:@"bundle/index.ios" ofType:@"jsbundle"];
        [manager copyItemAtPath:jsBundlePath toPath:jsPath error:nil];
        NSString *assetsBundlePath = [[NSBundle mainBundle] pathForResource:@"bundle/assets" ofType:nil];
        [manager copyItemAtPath:assetsBundlePath toPath:assetsPath error:nil];
    }
    return [NSURL URLWithString:jsPath];
}

RCT_EXPORT_METHOD(downLoadBundleZipWithOption:(NSDictionary *)option cb:(RCTResponseSenderBlock)callback) {
    NSString *zipPath = option[@"zipPath"];
    BOOL isAbort = [option[@"isAbort"] boolValue];
    NSAssert(zipPath != nil, @"无效的压缩包地址");
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:zipPath]];
    if(data){
        NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *zipPath = [cachePath stringByAppendingPathComponent:@"release.zip"];
        [data writeToFile:zipPath atomically:YES]; //下载zip包至cache文件夹
        NSString *unZipPath = [cachePath stringByAppendingString:@"/"];
        if([SSZipArchive unzipFileAtPath:zipPath toDestination:unZipPath overwrite:YES password:nil error:nil]){
            [self moveNewestBundleToDocument:unZipPath];
            NSFileManager *manager = [NSFileManager defaultManager];
            [manager removeItemAtPath:zipPath error:nil];
            [manager removeItemAtPath:unZipPath error:nil];
            callback(@[@{@"result":@(YES)}]);
            if(isAbort)
                exit(0);
        }else{
            callback(@[@{@"result":@(NO),@"error":@"解压出错"}]);
        }
    }else{
        callback(@[@{@"result":@(NO),@"error":@"无效的zip包"}]);
    }
}

RCT_EXPORT_METHOD(downLoadZipWithOpts:(NSDictionary *)options cb:(RCTResponseSenderBlock)callback) {
    NSString *zipPath = options[@"zipPath"];
    NSAssert(zipPath != nil, @"Invalid zip path");
    if ([zipPath hasPrefix:@"http"]) { // 以http开头
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:zipPath]];
        if (data) {
            NSString *zipPath = [cacheDir stringByAppendingPathComponent:@"release.zip"];
            NSFileManager *manager = [NSFileManager defaultManager];
            if ([manager fileExistsAtPath:zipPath]) {
                [manager removeItemAtPath:zipPath error:nil];
            }
            BOOL isSuccess = [data writeToFile:zipPath atomically:YES];
            if (isSuccess) {
                callback(@[@{@"result":@(YES),@"error":[NSNull null]}]);
            } else {
                callback(@[@{@"result":@(NO),@"error":@"保存出错"}]);
            }
        } else {
            callback(@[@{@"result":@(NO),@"error":@"无效的zip包"}]);
        }
    } else {
        UIApplication *application = [UIApplication sharedApplication];
        NSURL *url = [NSURL URLWithString:zipPath];
        if ([application canOpenURL:url]) {
            [application openURL:url options:@{} completionHandler:nil];
        }
        callback(@[@{@"result": @(YES)}]);
    }
}

RCT_EXPORT_METHOD(unzipBundleToDir:(NSString *)target cb:(RCTResponseSenderBlock)callback) {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSAssert(target != nil, @"无效的目标地址");
    NSString *cachePath = [cacheDir stringByAppendingPathComponent:@"release.zip"];
    if ([manager fileExistsAtPath:cachePath]) {
        NSString *tempDir = [cacheDir stringByAppendingString:@"/"];
        if([SSZipArchive unzipFileAtPath:cachePath toDestination:tempDir overwrite:YES password:nil error:nil]){
            if ([self moveNewstRn:tempDir targetDir:target manager:manager]) {
                [manager removeItemAtPath:cachePath error:nil];
                [manager removeItemAtPath:tempDir error:nil];
                callback(@[@{@"result":@(YES), @"error": [NSNull null]}]);
            } else {
                callback(@[@{@"result": @(NO), @"error": @"移动出错"}]);
            }
        } else {
            callback(@[@{@"result": @(NO), @"error": @"解压出错"}]);
        }
    } else {
        callback(@[@{@"result": @(NO), @"error": @"无效的zip包"}]);
    }
}

RCT_EXPORT_METHOD(setValueToUserStand:(NSString *)value key:(NSString *)key cb:(RCTResponseSenderBlock)callback) {
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    [stand setValue:value forKey:key];
    [stand synchronize];
}

RCT_EXPORT_METHOD(getValueWithkey:(NSString *)key cb:(RCTResponseSenderBlock)callback) {
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    id value = [stand valueForKey:key];
    if (value) {
        callback(@[@{@"value": value}]);
    } else {
        callback(@[@{@"value": [NSNull null]}]);
    }
}

RCT_EXPORT_METHOD(removeValueWithKey:(NSString *)key cb:(RCTResponseSenderBlock)callback) {
    NSUserDefaults *stand = [NSUserDefaults standardUserDefaults];
    id value = [stand valueForKey:key];
    if (value) {
        [stand removeObjectForKey:key];
        [stand synchronize];
    }
    callback(@[@{@"result":@(YES)}]);
}

RCT_EXPORT_METHOD(killApp) {
    exit(0);
}


#pragma mark 移动最新的包到Document中
-(void)moveNewestBundleToDocument:(NSString *)path{
    NSString *jsCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"index.ios.jsbundle"];
    NSString *assetsCachePath = [NSString stringWithFormat:@"%@/\%@",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0],@"assets"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL jsExist = [manager fileExistsAtPath:jsCachePath];
    if(jsExist){
        [manager removeItemAtPath:jsCachePath error:nil];
    }
    [manager copyItemAtPath:[path stringByAppendingPathComponent:@"release_ios/index.ios.jsbundle"] toPath:jsCachePath error:nil];
    if(assetsCachePath){
        [manager removeItemAtPath:assetsCachePath error:nil];
    }
    [manager copyItemAtPath:[path stringByAppendingPathComponent:@"release_ios/assets"] toPath:assetsCachePath error:nil];
    
}


-(BOOL)moveNewstRn:(NSString *)tmpDir targetDir:(NSString *)target manager:(NSFileManager *)manager {
    NSString *jsBundle = [target stringByAppendingPathComponent:@"index.ios.jsbundle"];
    if ([manager fileExistsAtPath:jsBundle]) {
        [manager removeItemAtPath:jsBundle error:nil];
    }
    NSString *assetBundle = [target stringByAppendingPathComponent:@"assets"];
    if ([manager fileExistsAtPath:assetBundle]) {
        [manager removeItemAtPath:assetBundle error:nil];
    }
    NSString *release_iosDir = [target stringByAppendingPathComponent:@"release_ios"];
    if (![manager fileExistsAtPath:release_iosDir]) {
        [manager createDirectoryAtPath:release_iosDir withIntermediateDirectories:YES attributes:@{} error:nil];
    }
    NSError *error = nil;
    [manager copyItemAtPath:tmpDir toPath:release_iosDir error:&error];
    if (error) {
        return NO;
    }
    return YES;
}

-(BOOL)needOverwrite:(NSString *)buildVersion version:(NSString *)version {
    if (version) {
        NSArray *buildArray = [buildVersion componentsSeparatedByString:@"."];
        NSArray *versionArray = [version componentsSeparatedByString:@"."];
        NSInteger minArrayLength = MIN(buildArray.count, versionArray.count);
        BOOL needOverWrite = NO;
        for(int i=0; i<minArrayLength; i++){
            NSString *localElement = buildArray[i];
            NSString *appElement = versionArray[i];
            NSInteger  buildValue =  localElement.integerValue;
            NSInteger  appValue = appElement.integerValue;
            if(buildValue > appValue) {
                needOverWrite = YES;
                break;
            }else{
                needOverWrite = NO;
            }
        }
        return needOverWrite;
    } else {
        return YES;
    }
}

@end
