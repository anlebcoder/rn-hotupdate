//
//  HotUpdate.h
//  HotUpdate
//
//  Created by named on 2017/9/25.
//  Copyright © 2017年 jiwei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>

@interface HotUpdate : NSObject<RCTBridgeModule>
-(NSURL *)getBundlePath;
@end
